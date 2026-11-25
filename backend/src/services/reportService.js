const Order = require('../models/Order');
const Customer = require('../models/Customer');
const recordSyncDeletion = require('../utils/recordSyncDeletion');

const TZ_OFFSET_MS = 5.5 * 3600 * 1000;

class ReportService {
  _getIstYmd(date = new Date()) {
    const tz = process.env.TZ || 'Asia/Kolkata';
    const parts = date.toLocaleDateString('en-CA', { timeZone: tz }).split('-').map(Number);
    return { y: parts[0], m: parts[1], d: parts[2] };
  }

  _istStartOfDay(y, m, d) {
    return new Date(Date.UTC(y, m - 1, d, 0, 0, 0, 0) - TZ_OFFSET_MS);
  }

  _istEndOfDay(y, m, d) {
    return new Date(Date.UTC(y, m - 1, d, 23, 59, 59, 999) - TZ_OFFSET_MS);
  }

  _resolveDateRange(query = {}) {
    const { period = 'today', startDate, endDate, refDate } = query;
    const baseDate = refDate ? new Date(refDate) : new Date();
    const { y, m, d } = this._getIstYmd(Number.isNaN(baseDate.getTime()) ? new Date() : baseDate);

    const todayStart = this._istStartOfDay(y, m, d);
    const todayEnd = this._istEndOfDay(y, m, d);

    let start;
    let end;
    let prevStart;
    let prevEnd;

    if (period === 'today' || period === 'daily') {
      start = todayStart;
      end = todayEnd;
      prevStart = new Date(start.getTime() - 24 * 3600 * 1000);
      prevEnd = new Date(end.getTime() - 24 * 3600 * 1000);
    } else if (period === 'yesterday') {
      start = new Date(todayStart.getTime() - 24 * 3600 * 1000);
      end = new Date(todayEnd.getTime() - 24 * 3600 * 1000);
      prevStart = new Date(start.getTime() - 24 * 3600 * 1000);
      prevEnd = new Date(end.getTime() - 24 * 3600 * 1000);
    } else if (period === 'weekly') {
      const istMid = new Date(todayStart.getTime() + TZ_OFFSET_MS);
      const dayOfWeek = istMid.getUTCDay();
      const daysSinceMon = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
      start = new Date(todayStart.getTime() - daysSinceMon * 24 * 3600 * 1000);
      end = new Date(start.getTime() + 7 * 24 * 3600 * 1000 - 1);
      prevStart = new Date(start.getTime() - 7 * 24 * 3600 * 1000);
      prevEnd = new Date(start.getTime() - 1);
    } else if (period === 'last7') {
      end = todayEnd;
      start = new Date(todayStart.getTime() - 6 * 24 * 3600 * 1000);
      prevEnd = new Date(start.getTime() - 1);
      prevStart = new Date(prevEnd.getTime() - (end.getTime() - start.getTime()));
    } else if (period === 'last30') {
      end = todayEnd;
      start = new Date(todayStart.getTime() - 29 * 24 * 3600 * 1000);
      prevEnd = new Date(start.getTime() - 1);
      prevStart = new Date(prevEnd.getTime() - (end.getTime() - start.getTime()));
    } else if (period === 'thisMonth' || period === 'monthly') {
      const lastDay = new Date(Date.UTC(y, m, 0)).getUTCDate();
      start = this._istStartOfDay(y, m, 1);
      end = this._istEndOfDay(y, m, lastDay);
      const pm = m === 1 ? 12 : m - 1;
      const py = m === 1 ? y - 1 : y;
      const pLastDay = new Date(Date.UTC(py, pm, 0)).getUTCDate();
      prevStart = this._istStartOfDay(py, pm, 1);
      prevEnd = this._istEndOfDay(py, pm, pLastDay);
    } else if (period === 'lastMonth') {
      const pm = m === 1 ? 12 : m - 1;
      const py = m === 1 ? y - 1 : y;
      const pLastDay = new Date(Date.UTC(py, pm, 0)).getUTCDate();
      start = this._istStartOfDay(py, pm, 1);
      end = this._istEndOfDay(py, pm, pLastDay);
      const pm2 = pm === 1 ? 12 : pm - 1;
      const py2 = pm === 1 ? py - 1 : py;
      const p2LastDay = new Date(Date.UTC(py2, pm2, 0)).getUTCDate();
      prevStart = this._istStartOfDay(py2, pm2, 1);
      prevEnd = this._istEndOfDay(py2, pm2, p2LastDay);
    } else if (period === 'yearly') {
      start = this._istStartOfDay(y, 1, 1);
      end = this._istEndOfDay(y, 12, 31);
      prevStart = this._istStartOfDay(y - 1, 1, 1);
      prevEnd = this._istEndOfDay(y - 1, 12, 31);
    } else if (period === 'allTime') {
      start = new Date(0);
      end = new Date();
      prevStart = new Date(0);
      prevEnd = new Date(0);
    } else if (period === 'custom' && startDate && endDate) {
      const sParsed = /^\d{4}-\d{2}-\d{2}$/.test(startDate)
        ? (() => {
            const [sy, sm, sd] = startDate.split('-').map(Number);
            return this._istStartOfDay(sy, sm, sd);
          })()
        : new Date(startDate);
      const eParsed = /^\d{4}-\d{2}-\d{2}$/.test(endDate)
        ? (() => {
            const [ey, em, ed] = endDate.split('-').map(Number);
            return this._istEndOfDay(ey, em, ed);
          })()
        : new Date(endDate);
      start = sParsed <= eParsed ? sParsed : eParsed;
      end = sParsed <= eParsed ? eParsed : sParsed;
      const diffMs = Math.max(end.getTime() - start.getTime(), 1);
      prevEnd = new Date(start.getTime() - 1);
      prevStart = new Date(prevEnd.getTime() - diffMs);
    } else {
      start = todayStart;
      end = todayEnd;
      prevStart = new Date(start.getTime() - 24 * 3600 * 1000);
      prevEnd = new Date(end.getTime() - 24 * 3600 * 1000);
    }

    return { start, end, prevStart, prevEnd, period };
  }

  async getDashboardSummary() {
    const now = new Date();
    const { y, m, d } = this._getIstYmd(now);

    const startOfDay = this._istStartOfDay(y, m, d);
    const endOfDay = this._istEndOfDay(y, m, d);
    const startOfYesterday = new Date(startOfDay.getTime() - 24 * 3600 * 1000);
    const endOfYesterday = new Date(endOfDay.getTime() - 24 * 3600 * 1000);
    const startOfWeek = new Date(startOfDay.getTime() - 6 * 24 * 3600 * 1000);
    const startOfMonth = this._istStartOfDay(y, m, 1);

    const validOrderMatch = { orderStatus: { $ne: 'refunded' } };

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

    const todayRevenue = todayOrders[0]?.totalRevenue || 0;
    const todayOrderCount = todayOrders[0]?.count || 0;
    const yesterdayRevenue = yesterdayOrders[0]?.totalRevenue || 0;
    const weekRevenue = weekOrders[0]?.totalRevenue || 0;
    const weekOrderCount = weekOrders[0]?.count || 0;
    const monthRevenue = monthOrders[0]?.totalRevenue || 0;
    const monthOrderCount = monthOrders[0]?.count || 0;
    const overallRevenue = overallOrders[0]?.totalRevenue || 0;
    const overallOrderCount = overallOrders[0]?.count || 0;

    const averageBillValue = overallOrderCount > 0 ? Math.round(overallRevenue / overallOrderCount) : 0;

    const tz = process.env.TZ || 'Asia/Kolkata';
    const [peakHourAgg, itemPerformance, totalCustomers, loyaltyMembers, returningCustomers, rewardsRedeemed, paymentAgg] = await Promise.all([
      Order.aggregate([
        { $match: validOrderMatch },
        { $project: { hour: { $hour: { date: '$createdAt', timezone: tz } } } },
        { $group: { _id: '$hour', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 1 },
      ]),
      Order.aggregate([
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
      ]),
      Customer.countDocuments(),
      Customer.countDocuments({ loyaltyCardNumber: { $exists: true, $nin: ['', null] } }),
      Customer.countDocuments({ totalVisits: { $gt: 1 } }),
      Order.countDocuments({ rewardStatus: { $regex: 'Reward Available', $options: 'i' } }),
      Order.aggregate([
        { $match: validOrderMatch },
        { $group: { _id: '$paymentMethod', total: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
    ]);

    const peakHourInt = peakHourAgg[0]?._id ?? 13;
    const peakSellingHour = `${peakHourInt % 12 || 12}:00 ${peakHourInt >= 12 ? 'PM' : 'AM'}`;

    const paymentAnalytics = { cash: 0, upi: 0, card: 0, wallet: 0 };
    paymentAgg.forEach((p) => {
      const key = (p._id || 'cash').toLowerCase();
      paymentAnalytics[key] = (paymentAnalytics[key] || 0) + (p.total || 0);
    });

    const hourlyRevenueToday = [];
    for (const [startHour, endHour] of [[0, 3], [4, 7], [8, 11], [12, 15], [16, 19], [20, 23]]) {
      const slotStart = new Date(Date.UTC(y, m - 1, d, startHour, 0, 0, 0) - TZ_OFFSET_MS);
      const slotEnd = new Date(Date.UTC(y, m - 1, d, endHour, 59, 59, 999) - TZ_OFFSET_MS);
      const slotOrder = await Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: slotStart, $lte: slotEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]);
      hourlyRevenueToday.push(slotOrder[0]?.total || 0.0);
    }

    const recentDailyRevenue = [];
    const currentDayOfWeek = new Date(now.getTime() + TZ_OFFSET_MS).getUTCDay();
    const daysSinceMon = currentDayOfWeek === 0 ? 6 : currentDayOfWeek - 1;
    const monOfWeek = new Date(startOfDay.getTime() - daysSinceMon * 24 * 3600 * 1000);
    for (let i = 0; i < 7; i++) {
      const dayStart = new Date(monOfWeek.getTime() + i * 24 * 3600 * 1000);
      const dayEnd = new Date(dayStart.getTime() + 24 * 3600 * 1000 - 1);
      const dayOrder = await Order.aggregate([
        { $match: { ...validOrderMatch, createdAt: { $gte: dayStart, $lte: dayEnd } } },
        { $group: { _id: null, total: { $sum: '$grandTotal' } } },
      ]);
      recentDailyRevenue.push(dayOrder[0]?.total || 0.0);
    }

    return {
      todayRevenue,
      todayOrderCount,
      todayExpenseTotal: 0.0,
      netProfitToday: todayRevenue,
      yesterdayRevenue,
      weekRevenue,
      weekOrderCount,
      weekExpenseTotal: 0.0,
      weeklyProfit: weekRevenue,
      monthRevenue,
      monthOrderCount,
      monthExpenseTotal: 0.0,
      monthlyProfit: monthRevenue,
      overallRevenue,
      overallOrderCount,
      overallExpenseTotal: 0.0,
      overallProfit: overallRevenue,
      averageBillValue,
      peakSellingHour,
      topSellingItems: itemPerformance.slice(0, 5),
      leastSellingItems: itemPerformance.slice(-5).reverse(),
      revenueByItem: itemPerformance,
      customerAnalytics: {
        totalCustomers,
        newCustomers: Math.max(0, totalCustomers - returningCustomers),
        returningCustomers,
        loyaltyMembers,
        rewardsRedeemed,
      },
      paymentAnalytics,
      expenseBreakdown: [],
      hourlyRevenueToday,
      recentDailyRevenue,
      monthlyWeeklyRevenue: [],
    };
  }

  async getFilteredAnalytics(query = {}) {
    const tz = process.env.TZ || 'Asia/Kolkata';
    const { start, end, prevStart, prevEnd, period } = this._resolveDateRange(query);

    const validOrderMatch = { orderStatus: { $ne: 'refunded' }, createdAt: { $gte: start, $lte: end } };
    const prevOrderMatch = { orderStatus: { $ne: 'refunded' }, createdAt: { $gte: prevStart, $lte: prevEnd } };

    const spanDays = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (24 * 3600 * 1000)));
    const useMonthlyBuckets = period === 'yearly' || period === 'allTime' || spanDays > 45;
    const trendFormat = useMonthlyBuckets ? '%Y-%m' : '%Y-%m-%d';

    const [
      currOrdersAgg,
      prevOrdersAgg,
      paymentAgg,
      topItemsAgg,
      recentOrders,
      totalCustCount,
      returningCustCount,
      loyaltyMembersCount,
      topSpenderAgg,
      mostFreqAgg,
      hourlyAgg,
      trendAgg,
    ] = await Promise.all([
      Order.aggregate([
        { $match: validOrderMatch },
        {
          $group: {
            _id: null,
            totalRevenue: { $sum: '$grandTotal' },
            count: { $sum: 1 },
            totalDiscount: { $sum: '$discountAmount' },
            totalServiceCharge: { $sum: '$serviceChargeAmount' },
          },
        },
      ]),
      period === 'allTime'
        ? Promise.resolve([])
        : Order.aggregate([
            { $match: prevOrderMatch },
            { $group: { _id: null, totalRevenue: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
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
          },
        },
        { $sort: { qtySold: -1 } },
        { $limit: 15 },
      ]),
      Order.find(validOrderMatch).sort({ createdAt: -1 }).limit(100).lean(),
      Customer.countDocuments(),
      Customer.countDocuments({ totalVisits: { $gt: 1 } }),
      Customer.countDocuments({ loyaltyCardNumber: { $exists: true, $nin: ['', null] } }),
      Customer.find().sort({ totalSpent: -1 }).limit(1).lean(),
      Customer.find().sort({ totalVisits: -1 }).limit(1).lean(),
      Order.aggregate([
        { $match: validOrderMatch },
        { $project: { hour: { $hour: { date: '$createdAt', timezone: tz } }, grandTotal: 1 } },
        { $group: { _id: '$hour', total: { $sum: '$grandTotal' }, count: { $sum: 1 } } },
      ]),
      Order.aggregate([
        { $match: validOrderMatch },
        {
          $group: {
            _id: { $dateToString: { format: trendFormat, date: '$createdAt', timezone: tz } },
            revenue: { $sum: '$grandTotal' },
            orders: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

    const revenue = currOrdersAgg[0]?.totalRevenue || 0;
    const ordersCount = currOrdersAgg[0]?.count || 0;
    const totalDiscount = currOrdersAgg[0]?.totalDiscount || 0;
    const totalServiceCharge = currOrdersAgg[0]?.totalServiceCharge || 0;
    const prevRevenue = prevOrdersAgg[0]?.totalRevenue || 0;

    const aov = ordersCount > 0 ? Math.round(revenue / ordersCount) : 0;
    const revenueGrowth =
      prevRevenue > 0 ? parseFloat((((revenue - prevRevenue) / prevRevenue) * 100).toFixed(1)) : 0;
    const returningPercent =
      totalCustCount > 0 ? Math.round((returningCustCount / totalCustCount) * 100) : 0;

    const hourlyData = Array.from({ length: 24 }, (_, h) => {
      const ampm = h >= 12 ? 'PM' : 'AM';
      const displayHour = h % 12 === 0 ? 12 : h % 12;
      return { hour: `${displayHour} ${ampm}`, hourNum: h, revenue: 0, count: 0 };
    });

    hourlyAgg.forEach((item) => {
      if (item._id >= 0 && item._id < 24) {
        hourlyData[item._id].revenue = item.total;
        hourlyData[item._id].count = item.count;
      }
    });

    // Build chart series cleanly without N+1 roundtrips
    const trendMap = new Map(trendAgg.map((t) => [t._id, t]));
    const dailyTrend = [];

    if (spanDays === 1 && period !== 'allTime') {
      // Single-day hourly buckets matching the mobile app's 4-hour blocks
      const slotLabels = ['12-4 AM', '4-8 AM', '8-12 PM', '12-4 PM', '4-8 PM', '8-12 AM'];
      for (let b = 0; b < 6; b++) {
        let rev = 0;
        let cnt = 0;
        for (let h = b * 4; h < (b + 1) * 4; h++) {
          rev += hourlyData[h].revenue;
          cnt += hourlyData[h].count;
        }
        dailyTrend.push({
          date: slotLabels[b],
          label: slotLabels[b],
          revenue: rev,
          orders: cnt,
          profit: rev,
        });
      }
    } else if (useMonthlyBuckets) {
      const sorted = trendAgg.slice(-12);
      for (const row of sorted) {
        const [yy, mm] = row._id.split('-').map(Number);
        const dt = new Date(Date.UTC(yy, mm - 1, 1));
        const label = dt.toLocaleDateString('en-IN', { month: 'short', year: '2-digit', timeZone: 'UTC' });
        dailyTrend.push({
          date: row._id,
          label,
          revenue: row.revenue || 0,
          orders: row.orders || 0,
          profit: row.revenue || 0,
        });
      }
    } else {
      const cursor = new Date(start.getTime() + TZ_OFFSET_MS);
      const endCursor = new Date(end.getTime() + TZ_OFFSET_MS);
      while (cursor <= endCursor) {
        const key = cursor.toISOString().slice(0, 10);
        const found = trendMap.get(key);
        const label = cursor.toLocaleDateString('en-IN', {
          month: 'short',
          day: 'numeric',
          timeZone: 'UTC',
        });
        dailyTrend.push({
          date: key,
          label,
          revenue: found?.revenue || 0,
          orders: found?.orders || 0,
          profit: found?.revenue || 0,
        });
        cursor.setUTCDate(cursor.getUTCDate() + 1);
      }
    }

    const paymentBreakdown = { cash: 0, upi: 0, card: 0, wallet: 0 };
    paymentAgg.forEach((p) => {
      const method = (p._id || 'cash').toLowerCase();
      paymentBreakdown[method] = (paymentBreakdown[method] || 0) + (p.total || 0);
    });

    return {
      period,
      rangeStart: start.toISOString(),
      rangeEnd: end.toISOString(),
      kpis: {
        revenue,
        ordersCount,
        aov,
        netProfit: revenue,
        totalDiscount,
        totalServiceCharge,
        revenueGrowth,
        returningPercent,
        loyaltyMembers: loyaltyMembersCount,
        totalCustomers: totalCustCount,
      },
      dailyTrend,
      hourlyData: hourlyData.filter((h) => h.hourNum >= 8 && h.hourNum <= 23),
      paymentBreakdown,
      topSellingItems: topItemsAgg.map((i) => ({
        name: i._id,
        qtySold: i.qtySold,
        revenue: i.revenue,
      })),
      customerInsights: {
        totalCustomers: totalCustCount,
        newCustomers: Math.max(0, totalCustCount - returningCustCount),
        returningCustomers: returningCustCount,
        loyaltyMembers: loyaltyMembersCount,
        returningPercent,
        highestSpender: topSpenderAgg[0]
          ? { name: topSpenderAgg[0].name, amount: topSpenderAgg[0].totalSpent || 0 }
          : null,
        mostFrequent: mostFreqAgg[0]
          ? { name: mostFreqAgg[0].name, visits: mostFreqAgg[0].totalVisits || 0 }
          : null,
      },
      recentOrders,
    };
  }

  async getOrdersList(query = {}) {
    const {
      period = 'allTime',
      startDate,
      endDate,
      search = '',
      paymentMethod = 'ALL',
      page = 1,
      limit = 50,
    } = query;

    const filter = {};
    if (period !== 'allTime' || (startDate && endDate)) {
      const { start, end } = this._resolveDateRange({ period, startDate, endDate });
      filter.createdAt = { $gte: start, $lte: end };
    }
    if (paymentMethod && paymentMethod.toUpperCase() !== 'ALL') {
      filter.paymentMethod = paymentMethod.toLowerCase();
    }
    if (search && search.trim()) {
      const regex = new RegExp(search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [
        { orderNumber: regex },
        { customerName: regex },
        { customerPhone: regex },
      ];
    }

    const safePage = Math.max(1, parseInt(page, 10) || 1);
    const safeLimit = Math.min(200, Math.max(1, parseInt(limit, 10) || 50));
    const skip = (safePage - 1) * safeLimit;

    const [orders, total] = await Promise.all([
      Order.find(filter).sort({ createdAt: -1 }).skip(skip).limit(safeLimit).lean(),
      Order.countDocuments(filter),
    ]);

    return {
      orders,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.max(1, Math.ceil(total / safeLimit)),
    };
  }

  async deleteOrderById(id) {
    const order = await Order.findByIdAndDelete(id);
    if (!order) return null;

    await recordSyncDeletion('order', id);

    if (order.orderStatus !== 'refunded' && order.customerPhone) {
      const cust = await Customer.findOne({ phone: order.customerPhone });
      if (cust) {
        cust.totalVisits = Math.max(0, (cust.totalVisits || 0) - 1);
        cust.totalSpent = Math.max(0, (cust.totalSpent || 0) - (order.grandTotal || 0));
        await cust.save();
      }
    }

    return { deletedId: id };
  }

  async getCustomersList(query = {}) {
    const { search = '', page = 1, limit = 50 } = query;
    const filter = {};
    if (search && search.trim()) {
      const regex = new RegExp(search.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
      filter.$or = [
        { name: regex },
        { phone: regex },
        { loyaltyCardNumber: regex },
      ];
    }

    const safePage = Math.max(1, parseInt(page, 10) || 1);
    const safeLimit = Math.min(200, Math.max(1, parseInt(limit, 10) || 50));
    const skip = (safePage - 1) * safeLimit;

    const [customers, total] = await Promise.all([
      Customer.find(filter).sort({ totalVisits: -1, createdAt: -1 }).skip(skip).limit(safeLimit).lean(),
      Customer.countDocuments(filter),
    ]);

    return {
      customers,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.max(1, Math.ceil(total / safeLimit)),
    };
  }
}

module.exports = new ReportService();
