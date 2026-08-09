const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');
const Customer = require('../models/Customer');
const Order = require('../models/Order');
const Expense = require('../models/Expense');
const ExpenseCategory = require('../models/ExpenseCategory');
const BusinessSettings = require('../models/BusinessSettings');
const reportService = require('./reportService');

class BootstrapService {
  /**
   * Fetches all core application data required for startup in parallel.
   */
  async getBootstrapData() {
    const [
      settings,
      categories,
      menuItems,
      customers,
      recentOrders,
      expenses,
      expenseCategories,
      dashboardAnalytics,
    ] = await Promise.all([
      BusinessSettings.findOne(),
      Category.find().sort({ name: 1 }),
      MenuItem.find().populate('category', '_id name').sort({ name: 1 }),
      Customer.find().sort({ name: 1 }),
      Order.find().sort({ createdAt: -1 }).limit(50),
      Expense.find().sort({ createdAt: -1 }).limit(50),
      ExpenseCategory.find().sort({ name: 1 }),
      reportService.getFilteredAnalytics({ period: 'today' }),
    ]);

    return {
      settings: settings || null,
      categories: categories || [],
      menuItems: menuItems || [],
      customers: customers || [],
      recentOrders: recentOrders || [],
      expenses: expenses || [],
      expenseCategories: expenseCategories || [],
      dashboard: dashboardAnalytics || {},
      timestamp: new Date().toISOString(),
    };
  }
}

module.exports = new BootstrapService();
