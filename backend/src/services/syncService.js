const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');
const Customer = require('../models/Customer');
const ExpenseCategory = require('../models/ExpenseCategory');
const Expense = require('../models/Expense');
const BusinessSettings = require('../models/BusinessSettings');
const Order = require('../models/Order');

class SyncService {
  /**
   * Pull all records updated after `sinceDate` across all core collections.
   */
  async pullChanges(sinceDate) {
    const filter = sinceDate ? { updatedAt: { $gte: new Date(sinceDate) } } : {};

    const [categories, menuItems, customers, expenseCategories, expenses, settings] =
      await Promise.all([
        Category.find(filter),
        MenuItem.find(filter).populate('category', '_id name'),
        Customer.find(filter),
        ExpenseCategory.find(filter),
        Expense.find(filter),
        BusinessSettings.findOne(),
      ]);

    return {
      categories,
      menuItems,
      customers,
      expenseCategories,
      expenses,
      settings,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Process a batch of push operations sent by the mobile app.
   */
  async pushBatch(operations = []) {
    const results = [];

    for (const op of operations) {
      const { entityType, operationType, localId, serverId, payload } = op;
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
        if (operationType === 'create') {
          // If serverId was supplied or document exists by unique field (e.g. orderNumber, phone)
          let doc;
          if (entityType === 'order' && payload.orderNumber) {
            doc = await model.findOne({ orderNumber: payload.orderNumber });
          } else if (entityType === 'customer' && payload.phone) {
            doc = await model.findOne({ phone: payload.phone });
          }

          if (!doc) {
            doc = await model.create(payload);
          }

          results.push({
            localId,
            serverId: doc._id.toString(),
            status: 'success',
          });
        } else if (operationType === 'update' && serverId) {
          await model.findByIdAndUpdate(serverId, payload, { new: true, runValidators: true });
          results.push({
            localId,
            serverId,
            status: 'success',
          });
        } else if (operationType === 'delete' && serverId) {
          await model.findByIdAndDelete(serverId);
          results.push({
            localId,
            serverId,
            status: 'success',
          });
        }
      } catch (err) {
        results.push({
          localId,
          serverId,
          status: 'error',
          error: err.message,
        });
      }
    }

    return results;
  }
}

module.exports = new SyncService();
