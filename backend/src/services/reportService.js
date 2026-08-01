const Order = require('../models/Order');
const Expense = require('../models/Expense');

class ReportService {
  async getDashboardSummary() {
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const endOfDay = new Date();
    endOfDay.setHours(23, 59, 59, 999);

    const startOfMonth = new Date(startOfDay.getFullYear(), startOfDay.getMonth(), 1);

    // Today Orders Total & Count
    const todayOrders = await Order.aggregate([
      { $match: { createdAt: { $gte: startOfDay, $lte: endOfDay } } },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$grandTotal' },
          orderCount: { $sum: 1 },
        },
      },
    ]);

    // Today Expenses Total
    const todayExpenses = await Expense.aggregate([
      { $match: { date: { $gte: startOfDay, $lte: endOfDay } } },
      {
        $group: {
          _id: null,
          totalExpense: { $sum: '$amount' },
        },
      },
    ]);

    // Month Revenue
    const monthOrders = await Order.aggregate([
      { $match: { createdAt: { $gte: startOfMonth, $lte: endOfDay } } },
      {
        $group: {
          _id: null,
          monthRevenue: { $sum: '$grandTotal' },
        },
      },
    ]);

    // Top Selling Items This Month
    const topSellingItems = await Order.aggregate([
      { $match: { createdAt: { $gte: startOfMonth, $lte: endOfDay } } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.name',
          totalQuantity: { $sum: '$items.quantity' },
          totalSales: { $sum: '$items.subtotal' },
        },
      },
      { $sort: { totalQuantity: -1 } },
      { $limit: 5 },
    ]);

    const todayRevenue = todayOrders[0]?.totalRevenue || 0;
    const todayOrderCount = todayOrders[0]?.orderCount || 0;
    const todayExpenseTotal = todayExpenses[0]?.totalExpense || 0;
    const monthRevenue = monthOrders[0]?.monthRevenue || 0;
    const netProfitToday = todayRevenue - todayExpenseTotal;

    return {
      todayRevenue,
      todayOrderCount,
      todayExpenseTotal,
      netProfitToday,
      monthRevenue,
      topSellingItems,
    };
  }
}

module.exports = new ReportService();
