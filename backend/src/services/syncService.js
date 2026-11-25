const mongoose = require('mongoose');
const Customer = require('../models/Customer');
const BusinessSettings = require('../models/BusinessSettings');
const Order = require('../models/Order');
const SyncReceipt = require('../models/SyncReceipt');
const SyncTombstone = require('../models/SyncTombstone');
const recordSyncDeletion = require('../utils/recordSyncDeletion');

class SyncService {
  /**
   * Pull all records updated after `sinceDate` across active core collections (Orders & Customers).
   */
  async pullChanges(sinceDate) {
    const syncStartedAt = new Date();
    const filter = sinceDate
      ? { updatedAt: { $gt: new Date(sinceDate), $lte: syncStartedAt } }
      : { updatedAt: { $lte: syncStartedAt } };

    const tombstoneFilter = sinceDate
      ? { 
          deletedAt: { $gt: new Date(sinceDate), $lte: syncStartedAt },
          entityType: { $in: ['customer', 'order', 'settings'] }
        }
      : { 
          deletedAt: { $lte: syncStartedAt },
          entityType: { $in: ['customer', 'order', 'settings'] }
        };

    const [customers, orders, settings, tombstones] = await Promise.all([
      Customer.find(filter),
      Order.find(filter),
      BusinessSettings.findOne(),
      SyncTombstone.find(tombstoneFilter),
    ]);

    return {
      customers,
      orders,
      settings,
      tombstones,
      timestamp: syncStartedAt.toISOString(),
    };
  }

  /**
   * Normalize order payment/status/items so legacy or imported rows satisfy Order schema.
   */
  _sanitizeOrderPayload(payload) {
    if (!payload || typeof payload !== 'object') return payload;

    const rawPay = (payload.paymentMethod || 'cash').toString().toLowerCase().trim();
    if (['cash', 'upi', 'card', 'wallet'].includes(rawPay)) {
      payload.paymentMethod = rawPay;
    } else if (/upi|gpay|phonepe|paytm|qr|online|bank/.test(rawPay)) {
      payload.paymentMethod = 'upi';
    } else if (/card|credit|debit/.test(rawPay)) {
      payload.paymentMethod = 'card';
    } else if (/wallet/.test(rawPay)) {
      payload.paymentMethod = 'wallet';
    } else {
      payload.paymentMethod = 'cash';
    }

    const rawStatus = (payload.orderStatus || 'completed').toString().toLowerCase().trim();
    payload.orderStatus = ['completed', 'edited', 'refunded'].includes(rawStatus)
      ? rawStatus
      : 'completed';

    const rawPayStatus = (payload.paymentStatus || 'paid').toString().toLowerCase().trim();
    payload.paymentStatus = ['paid', 'pending'].includes(rawPayStatus) ? rawPayStatus : 'paid';

    if (Array.isArray(payload.items)) {
      payload.items = payload.items.map((item) => {
        const price = Number(item?.price) || 0;
        const rawQty = Number(item?.quantity) || 1;
        const quantity = rawQty >= 1 ? Math.floor(rawQty) : 1;
        const subtotal = Number(item?.subtotal);
        return {
          ...item,
          name: (item?.name || 'Item').toString().trim() || 'Item',
          price,
          quantity,
          gstPercentage: Number(item?.gstPercentage) || 0,
          subtotal: Number.isFinite(subtotal) ? subtotal : price * quantity,
          notes: (item?.notes || '').toString(),
        };
      });
    }

    return payload;
  }

  /**
   * Process a batch of push operations sent by the mobile app (Orders, Customers & Settings).
   */
  async pushBatch(operations = []) {
    const results = [];

    // Bulk pre-fetch receipts and customer localId mappings to avoid N*5 sequential round-trips.
    const opIds = operations.map((o) => o?.operationId).filter(Boolean);
    const createCustomerLocalIds = operations
      .filter((o) => o?.operationType === 'create' && o?.entityType && o?.localId != null)
      .map((o) => o.localId.toString());
    const orderRawCustIds = operations
      .filter((o) => o?.entityType === 'order' && o?.payload)
      .map((o) => o.payload.customer || o.payload.customerId)
      .filter((id) => id && !mongoose.Types.ObjectId.isValid(id))
      .map((id) => id.toString());

    const allLocalIds = [...new Set([...createCustomerLocalIds, ...orderRawCustIds])];

    const [opReceipts, localReceipts] = await Promise.all([
      opIds.length > 0 ? SyncReceipt.find({ operationId: { $in: opIds } }).lean() : [],
      allLocalIds.length > 0 ? SyncReceipt.find({ localId: { $in: allLocalIds } }).lean() : [],
    ]);

    const receiptByOpId = new Map(opReceipts.map((r) => [r.operationId, r]));
    const receiptByEntityLocal = new Map(
      localReceipts.map((r) => [`${r.entityType}:${r.localId}`, r])
    );

    for (const op of operations) {
      const { operationId, entityType, operationType, localId, serverId, payload } = op;
      let model;

      switch (entityType) {
        case 'order':
          model = Order;
          break;
        case 'customer':
          model = Customer;
          break;
        case 'settings':
          model = BusinessSettings;
          break;
        default:
          // Ignore non-essential entities (categories, menu items, expenses) safely
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: serverId || localId || 'skipped',
            status: 'success',
          });
          continue;
      }

      try {
        let receipt = operationId ? receiptByOpId.get(operationId) : null;
        if (!receipt && localId != null && operationType === 'create') {
          receipt = receiptByEntityLocal.get(`${entityType}:${localId.toString()}`);
        }
        if (receipt) {
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: receipt.serverId,
            status: 'success',
          });
          continue;
        }

        let resultServerId = serverId || null;

        // Foreign key resolution & sanitization for orders
        if (entityType === 'order' && payload) {
          const rawCust = payload.customer || payload.customerId;
          if (rawCust) {
            if (mongoose.Types.ObjectId.isValid(rawCust)) {
              payload.customer = new mongoose.Types.ObjectId(rawCust);
            } else {
              const custReceipt = receiptByEntityLocal.get(`customer:${rawCust.toString()}`);
              payload.customer = (custReceipt && mongoose.Types.ObjectId.isValid(custReceipt.serverId))
                ? new mongoose.Types.ObjectId(custReceipt.serverId)
                : null;
            }
          } else {
            payload.customer = null;
          }
          delete payload.customerId;
          this._sanitizeOrderPayload(payload);
        }

        // Normalize customer payload before create/update
        if (entityType === 'customer' && payload && payload.loyaltyCardNumber === '') {
          payload.loyaltyCardNumber = null;
        }

        // Resolve serverId via existing receipt or natural key when an update arrives before serverId is stored locally
        let effectiveOpType = operationType;
        if (operationType === 'update' && !resultServerId && entityType !== 'settings') {
          const knownReceipt = localId != null
            ? receiptByEntityLocal.get(`${entityType}:${localId.toString()}`)
            : null;
          if (knownReceipt?.serverId && mongoose.Types.ObjectId.isValid(knownReceipt.serverId)) {
            resultServerId = knownReceipt.serverId;
          } else {
            let existingDoc = null;
            if (entityType === 'order' && payload?.orderNumber) {
              existingDoc = await model.findOne({ orderNumber: payload.orderNumber }).select('_id').lean();
            } else if (entityType === 'customer' && payload?.phone) {
              existingDoc = await model.findOne({ phone: payload.phone }).select('_id').lean();
            }
            if (existingDoc) {
              resultServerId = existingDoc._id.toString();
            } else {
              effectiveOpType = 'create';
            }
          }
        }

        if (effectiveOpType === 'create') {
          // Idempotent matching prevents duplicate records
          let doc;
          if (entityType === 'order' && payload.orderNumber) {
            doc = await model.findOne({ orderNumber: payload.orderNumber });
          } else if (entityType === 'customer' && payload.phone) {
            doc = await model.findOne({ phone: payload.phone });
          } else if (entityType === 'settings') {
            doc = await model.findOne();
          }

          if (!doc) {
            doc = await model.create(payload);
          } else if (entityType === 'settings') {
            Object.assign(doc, payload);
            await doc.save();
          }

          resultServerId = doc._id.toString();
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: resultServerId,
            status: 'success',
          });
        } else if (effectiveOpType === 'update' && (resultServerId || entityType === 'settings')) {
          if (entityType === 'settings' && !resultServerId) {
            let settings = await model.findOne();
            if (settings) {
              Object.assign(settings, payload);
              await settings.save();
            } else {
              settings = await model.create(payload);
            }
            resultServerId = settings._id.toString();
          } else {
            const updatedDoc = await model.findByIdAndUpdate(
              resultServerId,
              payload,
              { new: true, runValidators: true }
            );
            if (!updatedDoc) {
              const createdDoc = await model.create(payload);
              resultServerId = createdDoc._id.toString();
            }
          }
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: resultServerId,
            status: 'success',
          });
        } else if (effectiveOpType === 'delete' && resultServerId) {
          await model.findByIdAndDelete(resultServerId);
          await recordSyncDeletion(entityType, resultServerId);
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: resultServerId,
            status: 'success',
          });
        } else if (effectiveOpType === 'delete' && !resultServerId) {
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: 'deleted-local',
            status: 'success',
          });
        } else {
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: resultServerId,
            status: 'error',
            error: 'Operation is missing a required serverId',
          });
          continue;
        }

        if (operationId) {
          const receiptDoc = { operationId, entityType, localId, serverId: resultServerId };
          await SyncReceipt.updateOne(
            { operationId },
            { $setOnInsert: receiptDoc },
            { upsert: true }
          );
          receiptByOpId.set(operationId, receiptDoc);
          if (localId != null && resultServerId) {
            receiptByEntityLocal.set(`${entityType}:${localId.toString()}`, receiptDoc);
          }
        }
      } catch (err) {
        results.push({
          operationId,
          entityType,
          operationType,
          localId,
          serverId,
          status: 'error',
          error: err.message,
        });
      }
    }

    return results;
  }

  /**
   * Export all cloud data stored in MongoDB (Orders & Customers).
   */
  async exportAllData() {
    const exportedAt = new Date();
    const [customers, orders, settings] = await Promise.all([
      Customer.find().lean(),
      Order.find().lean(),
      BusinessSettings.findOne().lean(),
    ]);

    return {
      version: '1.0',
      exportedAt: exportedAt.toISOString(),
      database: 'FoodBillX MongoDB Cloud Backup',
      summary: {
        totalCustomers: customers.length,
        totalOrders: orders.length,
        totalRecords: customers.length + orders.length,
      },
      data: {
        businessSettings: settings,
        customers,
        orders,
      },
    };
  }

  /**
   * Get sync and cloud backup status including record counts.
   */
  async getSyncStatus() {
    const [
      customersCount,
      ordersCount,
      latestOrder,
      latestReceipt,
    ] = await Promise.all([
      Customer.countDocuments(),
      Order.countDocuments(),
      Order.findOne().sort({ updatedAt: -1 }).select('updatedAt').lean(),
      SyncReceipt.findOne().sort({ createdAt: -1 }).select('createdAt').lean(),
    ]);

    const dates = [
      latestReceipt?.createdAt,
      latestOrder?.updatedAt,
    ].filter(Boolean);

    const latestSyncTime = dates.length > 0
      ? new Date(Math.max(...dates.map((d) => new Date(d).getTime()))).toISOString()
      : null;

    return {
      databaseStatus: 'Connected',
      lastSyncedAt: latestSyncTime,
      totalRecords: customersCount + ordersCount,
      counts: {
        orders: ordersCount,
        customers: customersCount,
      },
    };
  }
}

module.exports = new SyncService();
