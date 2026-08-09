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
        { $match: { $or: [{ date: { $gte: startOfDay, $lte: endOfDay } }, { createdAt: { $gte: startOfDay, $lte: endOfDay } }] } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Expense.aggregate([
        { $match: { $or: [{ date: { $gte: startOfWeek, $lte: endOfDay } }, { createdAt: { $gte: startOfWeek, $lte: endOfDay } }] } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Expense.aggregate([
        { $match: { $or: [{ date: { $gte: startOfMonth, $lte: endOfDay } }, { createdAt: { $gte: startOfMonth, $lte: endOfDay } }] } },
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
      { $project: { hour: { $hour: { date: '$createdAt', timezone: process.env.TZ || 'Asia/Kolkata' } } } },
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

    // --- DAILY SALES TREND (CURRENT WEEK: SUN -> SAT) ---
    const recentDailyRevenue = [];
    const sunOfWeek = new Date(startOfDay);
    sunOfWeek.setDate(sunOfWeek.getDate() - sunOfWeek.getDay()); // Sunday of current week

    for (let i = 0; i < 7; i++) {
      const dayStart = new Date(sunOfWeek);
      dayStart.setDate(dayStart.getDate() + i);
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

  async getFilteredAnalytics(query = {}) {
    const { period = 'today', startDate, endDate } = query;
    const now = new Date();
    let start, end, prevStart, prevEnd;

    const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0);
    const endOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);

    if (period === 'today') {
      start = startOfDay(now);
      end = endOfDay(now);
      prevStart = new Date(start);
      prevStart.setDate(prevStart.getDate() - 1);
      prevEnd = new Date(end);
      prevEnd.setDate(prevEnd.getDate() - 1);
    } else if (period === 'yesterday') {
      const yest = new Date(now);
      yest.setDate(yest.getDate() - 1);
      start = startOfDay(yest);
      end = endOfDay(yest);
      prevStart = new Date(start);
      prevStart.setDate(prevStart.getDate() - 1);
      prevEnd = new Date(end);
      prevEnd.setDate(prevEnd.getDate() - 1);
    } else if (period === 'last7') {
      end = endOfDay(now);
      start = new Date(startOfDay(now));
      start.setDate(start.getDate() - 6);
      prevEnd = new Date(start);
      prevEnd.setMilliseconds(-1);
      prevStart = new Date(prevEnd);
      prevStart.setDate(prevStart.getDate() - 6);
    } else if (period === 'last30') {
      end = endOfDay(now);
      start = new Date(startOfDay(now));
      start.setDate(start.getDate() - 29);
      prevEnd = new Date(start);
      prevEnd.setMilliseconds(-1);
      prevStart = new Date(prevEnd);
      prevStart.setDate(prevStart.getDate() - 29);
    } else if (period === 'thisMonth') {
      start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
      end = endOfDay(now);
      prevStart = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
      prevEnd = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    } else if (period === 'lastMonth') {
      start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
      end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
      prevStart = new Date(now.getFullYear(), now.getMonth() - 2, 1, 0, 0, 0, 0);
      prevEnd = new Date(now.getFullYear(), now.getMonth() - 1, 0, 23, 59, 59, 999);
    } else if (period === 'custom' && startDate && endDate) {
      start = new Date(startDate);
      end = new Date(endDate);
      const diffMs = end.getTime() - start.getTime();
      prevEnd = new Date(start.getTime() - 1);
      prevStart = new Date(prevEnd.getTime() - diffMs);
    } else {
      start = startOfDay(now);
      end = endOfDay(now);
      prevStart = new Date(start);
      prevStart.setDate(prevStart.getDate() - 1);
      prevEnd = new Date(end);
      prevEnd.setDate(prevEnd.getDate() - 1);
    }

    const validOrderMatch = { orderStatus: { $ne: 'refunded' }, createdAt: { $gte: start, $lte: end } };
    const prevOrderMatch = { orderStatus: { $ne: 'refunded' }, createdAt: { $gte: prevStart, $lte: prevEnd } };

    const [
      currOrdersAgg,
      prevOrdersAgg,
      cancelledCount,
      expensesAgg,
      paymentAgg,
      topItemsAgg,
      categoryAgg,
      recentOrders,
      totalCustCount,
      returningCustCount,
      topSpenderAgg,
      mostFreqAgg
    ] = await Promise.all([
      Order.aggregate([
        { $match: validOrderMatch },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 }, totalGst: { $sum: '$gstAmount' }, totalDiscount: { $sum: '$discountAmount' } } },
      ]),
      Order.aggregate([
        { $match: prevOrderMatch },
        { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.countDocuments({ orderStatus: 'refunded', createdAt: { $gte: start, $lte: end } }),
      Expense.aggregate([
        { $match: { $or: [{ date: { $gte: start, $lte: end } }, { createdAt: { $gte: start, $lte: end } }] } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Order.aggregate([
        { $match: validOrderMatch },
        { $group: { _id: '$paymentMethod', total: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: validOrderMatch },
        { $unwind: '$items' },
        {
          $group: {
            _id: '$items.name',
            qtySold: { $sum: '$items.quantity' },
            revenue: { $sum: '$items.subtotal' },
            category: { $first: '$items.category' }
          }
        },
        { $sort: { qtySold: -1 } },
        { $limit: 10 }
      ]),
      Order.aggregate([
        { $match: validOrderMatch },
        { $unwind: '$items' },
        {
          $group: {
            _id: { $ifNull: ['$items.category', 'General'] },
            revenue: { $sum: '$items.subtotal' },
            ordersCount: { $sum: 1 }
          }
        },
        { $sort: { revenue: -1 } }
      ]),
      Order.find({ createdAt: { $gte: start, $lte: end } }).sort({ createdAt: -1 }).limit(15),
      Customer.countDocuments(),
      Customer.countDocuments({ totalVisits: { $gt: 1 } }),
      Customer.find().sort({ totalSpent: -1 }).limit(1),
      Customer.find().sort({ totalVisits: -1 }).limit(1)
    ]);

    const revenue = currOrdersAgg[0]?.totalRevenue || 0;
    const ordersCount = currOrdersAgg[0]?.count || 0;
    const prevRevenue = prevOrdersAgg[0]?.totalRevenue || 0;
    const prevOrdersCount = prevOrdersAgg[0]?.count || 0;

    const totalExpenses = expensesAgg[0]?.total || 0;
    const netProfit = revenue - totalExpenses;
    const aov = ordersCount > 0 ? Math.round(revenue / ordersCount) : 0;
    const profitMargin = revenue > 0 ? Math.round((netProfit / revenue) * 100) : 0;
    const revenueGrowth = prevRevenue > 0 ? parseFloat((((revenue - prevRevenue) / prevRevenue) * 100).toFixed(1)) : 0;
    const returningPercent = totalCustCount > 0 ? Math.round((returningCustCount / totalCustCount) * 100) : 0;

    // --- HOURLY BREAKDOWN (0 - 23) ---
    const hourlyData = Array.from({ length: 24 }, (_, h) => {
      const ampm = h >= 12 ? 'PM' : 'AM';
      const displayHour = h % 12 === 0 ? 12 : h % 12;
      return { hour: `${displayHour} ${ampm}`, hourNum: h, revenue: 0, count: 0 };
    });

    const hourlyAgg = await Order.aggregate([
      { $match: validOrderMatch },
      { $project: { hour: { $hour: { date: '$createdAt', timezone: process.env.TZ || 'Asia/Kolkata' } }, grandTotal: 1 } },
      { $group: { _id: '$hour', total: { $sum: '$grandTotal' }, count: { $sum: 1 } } }
    ]);

    hourlyAgg.forEach(item => {
      if (item._id >= 0 && item._id < 24) {
        hourlyData[item._id].revenue = item.total;
        hourlyData[item._id].count = item.count;
      }
    });

    // --- DAILY TREND WITHIN PERIOD ---
    const dailyTrend = [];
    const stepDays = 1;
    const curr = new Date(start);
    while (curr <= end) {
      const dStart = startOfDay(curr);
      const dEnd = endOfDay(curr);
      const dRevAgg = await Order.aggregate([
        { $match: { orderStatus: { $ne: 'refunded' }, createdAt: { $gte: dStart, $lte: dEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' }, count: { $sum: 1 } } }
      ]);
      const dExpAgg = await Expense.aggregate([
        { $match: { $or: [{ date: { $gte: dStart, $lte: dEnd } }, { createdAt: { $gte: dStart, $lte: dEnd } }] } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]);

      const dRev = dRevAgg[0]?.total || 0;
      const dCnt = dRevAgg[0]?.count || 0;
      const dExp = dExpAgg[0]?.total || 0;
      const dProf = dRev - dExp;

      const dateLabel = curr.toLocaleDateString('en-US', { month: 'short', day: 'numeric', weekday: 'short' });
      dailyTrend.push({
        date: curr.toISOString().split('T')[0],
        label: dateLabel,
        revenue: dRev,
        orders: dCnt,
        profit: dProf,
        expenses: dExp
      });

      curr.setDate(curr.getDate() + stepDays);
    }

    // Format Payment Breakdown
    const paymentBreakdown = { cash: 0, upi: 0, card: 0, wallet: 0 };
    paymentAgg.forEach(p => {
      const method = (p._id || 'cash').toLowerCase();
      paymentBreakdown[method] = p.total;
    });

    return {
      kpis: {
        revenue,
        ordersCount,
        aov,
        netProfit,
        totalExpenses,
        profitMargin,
        revenueGrowth,
        returningPercent,
        cancelledCount,
        totalCustomers: totalCustCount
      },
      dailyTrend,
      hourlyData: hourlyData.filter(h => h.hourNum >= 8 && h.hourNum <= 23), // 8 AM to 11 PM
      paymentBreakdown,
      topSellingItems: topItemsAgg.map(i => ({
        name: i._id,
        category: i.category || 'General',
        qtySold: i.qtySold,
        revenue: i.revenue,
        profit: Math.round(i.revenue * 0.45) // Estimated profit margin per dish item
      })),
      categoryPerformance: categoryAgg.map(c => ({
        category: c._id,
        revenue: c.revenue,
        ordersCount: c.ordersCount
      })),
      customerInsights: {
        totalCustomers: totalCustCount,
        newCustomers: Math.max(0, totalCustCount - returningCustCount),
        returningCustomers: returningCustCount,
        returningPercent,
        highestSpender: topSpenderAgg[0] ? { name: topSpenderAgg[0].name, amount: topSpenderAgg[0].totalSpent || 0 } : null,
        mostFrequent: mostFreqAgg[0] ? { name: mostFreqAgg[0].name, visits: mostFreqAgg[0].totalVisits || 0 } : null
      },
      recentOrders
    };
  }
}

module.exports = new ReportService();

