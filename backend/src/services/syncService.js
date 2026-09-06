const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');
const Customer = require('../models/Customer');
const ExpenseCategory = require('../models/ExpenseCategory');
const Expense = require('../models/Expense');
const BusinessSettings = require('../models/BusinessSettings');
const Order = require('../models/Order');
const SyncReceipt = require('../models/SyncReceipt');
const SyncTombstone = require('../models/SyncTombstone');
const recordSyncDeletion = require('../utils/recordSyncDeletion');

class SyncService {
  /**
   * Pull all records updated after `sinceDate` across all core collections.
   */
  async pullChanges(sinceDate) {
    const syncStartedAt = new Date();
    const filter = sinceDate
      ? { updatedAt: { $gt: new Date(sinceDate), $lte: syncStartedAt } }
      : { updatedAt: { $lte: syncStartedAt } };

    const tombstoneFilter = sinceDate
      ? { deletedAt: { $gt: new Date(sinceDate), $lte: syncStartedAt } }
      : { deletedAt: { $lte: syncStartedAt } };
    const [categories, menuItems, customers, expenseCategories, expenses, orders, settings, tombstones] =
      await Promise.all([
        Category.find(filter),
        MenuItem.find(filter).populate('category', '_id name'),
        Customer.find(filter),
        ExpenseCategory.find(filter),
        Expense.find(filter),
        Order.find(filter),
        BusinessSettings.findOne(),
        SyncTombstone.find(tombstoneFilter),
      ]);

    return {
      categories,
      menuItems,
      customers,
      expenseCategories,
      expenses,
      orders,
      settings,
      tombstones,
      timestamp: syncStartedAt.toISOString(),
    };
  }

  /**
   * Process a batch of push operations sent by the mobile app.
   */
  async pushBatch(operations = []) {
    const results = [];

    for (const op of operations) {
      const { operationId, entityType, operationType, localId, serverId, payload } = op;
      let model;

      switch (entityType) {
        case 'category':
          model = Category;
          break;
        case 'menuItem':
          model = MenuItem;
          break;
        case 'order':
          model = Order;
          break;
        case 'customer':
          model = Customer;
          break;
        case 'expense':
          model = Expense;
          break;
        case 'expenseCategory':
          model = ExpenseCategory;
          break;
        case 'settings':
          model = BusinessSettings;
          break;
        default:
          continue;
      }

      try {
        if (operationId) {
          const receipt = await SyncReceipt.findOne({ operationId });
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
        }

        let resultServerId = serverId || null;
        if (operationType === 'create') {
          // Idempotent matching prevents duplicate creates when a response is lost
          // and the mobile outbox retries the same logical operation.
          let doc;
          if (entityType === 'order' && payload.orderNumber) {
            doc = await model.findOne({ orderNumber: payload.orderNumber });
          } else if (entityType === 'customer' && payload.phone) {
            doc = await model.findOne({ phone: payload.phone });
          } else if (entityType === 'category' && payload.name) {
            doc = await model.findOne({ name: payload.name });
          } else if (entityType === 'expenseCategory' && payload.name) {
            doc = await model.findOne({ name: payload.name });
          } else if (entityType === 'menuItem' && payload.name && payload.category) {
            doc = await model.findOne({ name: payload.name, category: payload.category });
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
   * Export all cloud data stored in MongoDB across all collections.
   */
  async exportAllData() {
    const exportedAt = new Date();
    const [
      categories,
      menuItems,
      customers,
      expenseCategories,
      expenses,
      orders,
      settings,
    ] = await Promise.all([
      Category.find().lean(),
      MenuItem.find().populate('category', '_id name').lean(),
      Customer.find().lean(),
      ExpenseCategory.find().lean(),
      Expense.find().lean(),
      Order.find().lean(),
      BusinessSettings.findOne().lean(),
    ]);

    return {
      version: '1.0',
      exportedAt: exportedAt.toISOString(),
      database: 'FoodBillX MongoDB Cloud Backup',
      summary: {
        totalCategories: categories.length,
        totalMenuItems: menuItems.length,
        totalCustomers: customers.length,
        totalOrders: orders.length,
        totalExpenses: expenses.length,
        totalExpenseCategories: expenseCategories.length,
        totalRecords:
          categories.length +
          menuItems.length +
          customers.length +
          orders.length +
          expenses.length +
          expenseCategories.length,
      },
      data: {
        businessSettings: settings,
        categories,
        menuItems,
        customers,
        orders,
        expenses,
        expenseCategories,
      },
    };
  }

  /**
   * Get sync and cloud backup status including record counts and latest activity.
   */
  async getSyncStatus() {
    const [
      categoriesCount,
      menuItemsCount,
      customersCount,
      ordersCount,
      expensesCount,
      expenseCategoriesCount,
      latestOrder,
      latestExpense,
      latestReceipt,
    ] = await Promise.all([
      Category.countDocuments(),
      MenuItem.countDocuments(),
      Customer.countDocuments(),
      Order.countDocuments(),
      Expense.countDocuments(),
      ExpenseCategory.countDocuments(),
      Order.findOne().sort({ updatedAt: -1 }).select('updatedAt').lean(),
      Expense.findOne().sort({ updatedAt: -1 }).select('updatedAt').lean(),
      SyncReceipt.findOne().sort({ createdAt: -1 }).select('createdAt').lean(),
    ]);

    const dates = [
      latestReceipt?.createdAt,
      latestOrder?.updatedAt,
      latestExpense?.updatedAt,
    ].filter(Boolean);

    const latestSyncTime = dates.length > 0
      ? new Date(Math.max(...dates.map((d) => new Date(d).getTime()))).toISOString()
      : null;

    const totalRecords =
      categoriesCount +
      menuItemsCount +
      customersCount +
      ordersCount +
      expensesCount +
      expenseCategoriesCount;

    return {
      databaseStatus: 'Connected',
      lastSyncedAt: latestSyncTime,
      totalRecords,
      counts: {
        orders: ordersCount,
        expenses: expensesCount,
        customers: customersCount,
        menuItems: menuItemsCount,
        categories: categoriesCount,
        expenseCategories: expenseCategoriesCount,
      },
    };
  }
}

module.exports = new SyncService();
