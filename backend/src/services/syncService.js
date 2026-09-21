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
   * Process a batch of push operations sent by the mobile app (Orders & Customers only).
   */
  async pushBatch(operations = []) {
    const results = [];

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
        let receipt = null;
        if (operationId) {
          receipt = await SyncReceipt.findOne({ operationId });
        }
        if (!receipt && localId && entityType && operationType === 'create') {
          receipt = await SyncReceipt.findOne({ entityType, localId: localId.toString() });
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

        // Foreign key resolution for offline customer matching
        if (entityType === 'order' && payload) {
          const rawCust = payload.customer || payload.customerId;
          if (rawCust) {
            if (mongoose.Types.ObjectId.isValid(rawCust)) {
              payload.customer = new mongoose.Types.ObjectId(rawCust);
            } else {
              const custReceipt = await SyncReceipt.findOne({
                entityType: 'customer',
                localId: rawCust.toString(),
              });
              payload.customer = (custReceipt && mongoose.Types.ObjectId.isValid(custReceipt.serverId))
                ? new mongoose.Types.ObjectId(custReceipt.serverId)
                : null;
            }
          } else {
            payload.customer = null;
          }
          delete payload.customerId;
        }

        if (operationType === 'create') {
          // Normalize empty loyaltyCardNumber to null for sparse unique index compatibility
          if (entityType === 'customer' && payload.loyaltyCardNumber === '') {
            payload.loyaltyCardNumber = null;
          }

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

          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: doc._id.toString(),
            status: 'success',
          });
          resultServerId = doc._id.toString();
        } else if (operationType === 'update' && (serverId || entityType === 'settings')) {
          // Normalize empty loyaltyCardNumber to null for customer updates
          if (entityType === 'customer' && payload.loyaltyCardNumber === '') {
            payload.loyaltyCardNumber = null;
          }
          if (entityType === 'settings' && !serverId) {
            let settings = await model.findOne();
            if (settings) {
              Object.assign(settings, payload);
              await settings.save();
            } else {
              settings = await model.create(payload);
            }
            resultServerId = settings._id.toString();
          } else {
            await model.findByIdAndUpdate(serverId, payload, { new: true, runValidators: true });
          }
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId: resultServerId,
            status: 'success',
          });
        } else if (operationType === 'delete' && serverId) {
          await model.findByIdAndDelete(serverId);
          await recordSyncDeletion(entityType, serverId);
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId,
            status: 'success',
          });
        } else {
          results.push({
            operationId,
            entityType,
            operationType,
            localId,
            serverId,
            status: 'error',
            error: 'Operation is missing a required serverId',
          });
          continue;
        }

        if (operationId) {
          await SyncReceipt.updateOne(
            { operationId },
            { $setOnInsert: { operationId, entityType, localId, serverId: resultServerId } },
            { upsert: true }
          );
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
