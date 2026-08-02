const Order = require('../models/Order');
const Expense = require('../models/Expense');
const Customer = require('../models/Customer');
const MenuItem = require('../models/MenuItem');

class ReportService {
  async getDashboardSummary() {
    const now = new Date();
    
    // Today boundary
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
    const endOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    // Yesterday boundary
    const startOfYesterday = new Date(startOfDay);
    startOfYesterday.setDate(startOfYesterday.getDate() - 1);
    const endOfYesterday = new Date(endOfDay);
    endOfYesterday.setDate(endOfYesterday.getDate() - 1);

    // Week boundary (last 7 days)
    const startOfWeek = new Date(startOfDay);
    startOfWeek.setDate(startOfWeek.getDate() - 6);

    // Month boundary
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);

    // Completed orders filter condition
    const validOrderMatch = { orderStatus: { $ne: 'refunded' } };

    // --- REVENUE & ORDERS ---
    const [todayOrders, yesterdayOrders, weekOrders, monthOrders, overallOrders] = await Promise.all([
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: startOfDay, $lte: endOfDay } } },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: startOfYesterday, $lte: endOfYesterday } } },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: startOfWeek, $lte: endOfDay } } },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: startOfMonth, $lte: endOfDay } } },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: validOrderMatch },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
    ]);

    // --- EXPENSES ---
    const [todayExp, weekExp, monthExp, overallExp] = await Promise.all([
      Expense.aggregate([
        { $match: { date: { $gte: startOfDay, $lte: endOfDay } } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Expense.aggregate([
        { $match: { date: { $gte: startOfWeek, $lte: endOfDay } } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Expense.aggregate([
        { $match: { date: { $gte: startOfMonth, $lte: endOfDay } } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Expense.aggregate([
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
    ]);

    const todayRevenue = todayOrders[0]?.totalRevenue || 0;
    const todayOrderCount = todayOrders[0]?.count || 0;
    const yesterdayRevenue = yesterdayOrders[0]?.totalRevenue || 0;
    const weekRevenue = weekOrders[0]?.totalRevenue || 0;
    const weekOrderCount = weekOrders[0]?.count || 0;
    const monthRevenue = monthOrders[0]?.monthRevenue || monthOrders[0]?.totalRevenue || 0;
    const monthOrderCount = monthOrders[0]?.count || 0;
    const overallRevenue = overallOrders[0]?.totalRevenue || 0;
    const overallOrderCount = overallOrders[0]?.count || 0;

    const todayExpenseTotal = todayExp[0]?.total || 0;
    const weekExpenseTotal = weekExp[0]?.total || 0;
    const monthExpenseTotal = monthExp[0]?.total || 0;
    const overallExpenseTotal = overallExp[0]?.total || 0;

    const netProfitToday = todayRevenue - todayExpenseTotal;
    const weeklyProfit = weekRevenue - weekExpenseTotal;
    const monthlyProfit = monthRevenue - monthExpenseTotal;
    const overallProfit = overallRevenue - overallExpenseTotal;

    const averageBillValue = overallOrderCount > 0 ? Math.round(overallRevenue / overallOrderCount) : 0;

    // --- PEAK SELLING HOUR ---
    const peakHourAgg = await Order.aggregate([
      { $match: validOrderMatch },
      { $project: { hour: { $hour: '$createdAt' } } },
      { $group: { _id: '$hour', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 },
    ]);
    const peakHourInt = peakHourAgg[0]?._id ?? 13;
    const peakSellingHour = `${peakHourInt % 12 || 12}:00 ${peakHourInt >= 12 ? 'PM' : 'AM'}`;

    // --- MENU PERFORMANCE ---
    const itemPerformance = await Order.aggregate([
      { $match: validOrderMatch },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.name',
          totalQuantity: { $sum: '$items.quantity' },
          totalSales: { $sum: '$items.subtotal' },
        },
      },
      { $sort: { totalQuantity: -1 } },
    ]);

    const bestSellingItems = itemPerformance.slice(0, 5);
    const leastSellingItems = itemPerformance.slice(-5).reverse();

    // Category Performance
    const categoryAgg = await Order.aggregate([
      { $match: validOrderMatch },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.name',
          revenue: { $sum: '$items.subtotal' },
        },
      },
    ]);

    // --- CUSTOMER ANALYTICS ---
    const [totalCustomers, loyaltyMembers] = await Promise.all([
      Customer.countDocuments(),
      Customer.countDocuments({ loyaltyCardNumber: { $exists: true, $ne: '' } }),
    ]);
    const returningCustomers = await Customer.countDocuments({ totalVisits: { $gt: 1 } });
    const newCustomers = Math.max(0, totalCustomers - returningCustomers);
    const rewardsRedeemed = await Order.countDocuments({ rewardStatus: { $regex: 'Reward Available', $options: 'i' } });

    // --- PAYMENT ANALYTICS ---
    const paymentAgg = await Order.aggregate([
      { $match: validOrderMatch },
      { $group: { _id: '$paymentMethod', total: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
    ]);
    const paymentAnalytics = { cash: 0, upi: 0, card: 0, wallet: 0 };
    paymentAgg.forEach((p) => {
      const key = (p._id || 'cash').toLowerCase();
      paymentAnalytics[key] = p.total;
    });

    // --- EXPENSE ANALYTICS ---
    const expenseBreakdown = await Expense.aggregate([
      { $group: { _id: '$category', total: { $sum: '$amount' }, count: { $sum: 1 } } },
      { $sort: { total: -1 } },
    ]);

    // --- HOURLY SALES TREND (TODAY 6 INTERVALS) ---
    const hourlyRevenueToday = [];
    const hourlyRanges = [
      [0, 3],
      [4, 7],
      [8, 11],
      [12, 15],
      [16, 19],
      [20, 23],
    ];

    for (const [startHour, endHour] of hourlyRanges) {
      const slotStart = new Date(startOfDay);
      slotStart.setHours(startHour, 0, 0, 0);
      const slotEnd = new Date(startOfDay);
      slotEnd.setHours(endHour, 59, 59, 999);

      const slotOrder = await Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: slotStart, $lte: slotEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]);
      hourlyRevenueToday.push(slotOrder[0]?.total || 0.0);
    }

    // --- DAILY SALES TREND (LAST 7 DAYS) ---
    const recentDailyRevenue = [];
    for (let i = 6; i >= 0; i--) {
      const dayStart = new Date(startOfDay);
      dayStart.setDate(dayStart.getDate() - i);
      const dayEnd = new Date(dayStart);
      dayEnd.setHours(23, 59, 59, 999);

      const dayOrder = await Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: dayStart, $lte: dayEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]);
      recentDailyRevenue.push(dayOrder[0]?.total || 0.0);
    }

    // --- MONTHLY WEEKLY TREND (5 WEEKS OF CURRENT MONTH) ---
    const monthlyWeeklyRevenue = [];
    const year = now.getFullYear();
    const month = now.getMonth();
    const lastDayOfMonth = new Date(year, month + 1, 0).getDate();

    const weekRanges = [
      [1, 7],
      [8, 14],
      [15, 21],
      [22, 28],
      [29, lastDayOfMonth],
    ];

    for (const [sDay, eDay] of weekRanges) {
      if (sDay > lastDayOfMonth) {
        monthlyWeeklyRevenue.push(0.0);
        continue;
      }
      const actualEDay = Math.min(eDay, lastDayOfMonth);
      const wStart = new Date(year, month, sDay, 0, 0, 0, 0);
      const wEnd = new Date(year, month, actualEDay, 23, 59, 59, 999);

      const wOrder = await Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: wStart, $lte: wEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]);
      monthlyWeeklyRevenue.push(wOrder[0]?.total || 0.0);
    }

    // --- PREVIOUS PERIOD TOTALS FOR ACCURATE COMPARISON ---
    const prevWeekStart = new Date(startOfWeek);
    prevWeekStart.setDate(prevWeekStart.getDate() - 7);
    const prevWeekEnd = new Date(startOfWeek);
    prevWeekEnd.setMilliseconds(-1);

    const prevMonthStart = new Date(year, month - 1, 1, 0, 0, 0, 0);
    const prevMonthEnd = new Date(year, month, 0, 23, 59, 59, 999);

    const [prevWeekAgg, prevMonthAgg] = await Promise.all([
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: prevWeekStart, $lte: prevWeekEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]),
      Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: prevMonthStart, $lte: prevMonthEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]),
    ]);

    const previousWeekRevenue = prevWeekAgg[0]?.total || 0.0;
    const previousMonthRevenue = prevMonthAgg[0]?.total || 0.0;

    // Return merged summary object
    return {
      todayRevenue,
      todayOrderCount,
      todayExpenseTotal,
      netProfitToday,
      yesterdayRevenue,
      weekRevenue,
      weekOrderCount,
      weekExpenseTotal,
      weeklyProfit,
      previousWeekRevenue,
      monthRevenue,
      monthOrderCount,
      monthExpenseTotal,
      monthlyProfit,
      previousMonthRevenue,
      overallRevenue,
      overallOrderCount,
      overallExpenseTotal,
      overallProfit,
      averageBillValue,
      peakSellingHour,
      topSellingItems: bestSellingItems,
      leastSellingItems,
      revenueByItem: itemPerformance,
      customerAnalytics: {
        totalCustomers,
        newCustomers,
        returningCustomers,
        loyaltyMembers,
        rewardsRedeemed,
      },
      paymentAnalytics,
      expenseBreakdown: expenseBreakdown.map((e) => ({ category: e._id || 'Miscellaneous', total: e.total, count: e.count })),
      hourlyRevenueToday,
      recentDailyRevenue,
      monthlyWeeklyRevenue,
    };
  }
}

module.exports = new ReportService();
