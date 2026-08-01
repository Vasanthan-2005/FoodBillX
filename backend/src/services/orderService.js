const Order = require('../models/Order');
const Customer = require('../models/Customer');
const MenuItem = require('../models/MenuItem');
const BusinessSettings = require('../models/BusinessSettings');
const AppError = require('../utils/appError');

class OrderService {
  async generateOrderNumber() {
    const settings = await BusinessSettings.findOne();
    const prefix = settings?.invoicePrefix || 'INV-';
    return `${prefix}${Date.now().toString(36).toUpperCase()}`;
  }

  async createOrder(orderData) {
    const { customerId, customerName, customerPhone, items, paymentMethod = 'cash', discountAmount = 0 } = orderData;

    if (!items || items.length === 0) {
      throw new AppError('Order must contain at least one item', 400);
    }

    const itemIds = items.map((item) => item.menuItem).filter(Boolean);
    const [dbItems, settings] = await Promise.all([
      MenuItem.find({ _id: { $in: itemIds } }),
      BusinessSettings.findOne(),
    ]);
    const itemsById = new Map(dbItems.map((item) => [item._id.toString(), item]));

    let calculatedSubtotal = 0;
    let calculatedGst = 0;
    let itemDiscountTotal = 0;
    const processedItems = [];

    for (const item of items) {
      const dbItem = itemsById.get(item.menuItem?.toString());
      if (!dbItem) {
        throw new AppError(`Menu item ${item.name || item.menuItem} not found`, 404);
      }
      const price = dbItem.price;
      const quantity = item.quantity || 1;
      const itemSubtotal = price * quantity;
      const itemDiscount = Math.min(dbItem.discount || 0, price) * quantity;
      const itemNet = itemSubtotal - itemDiscount;
      const gstPercentage = dbItem.gstPercentage || 5.0;

      calculatedSubtotal += itemSubtotal;
      itemDiscountTotal += itemDiscount;
      calculatedGst += (itemNet * gstPercentage) / 100;

      processedItems.push({
        menuItem: dbItem._id,
        name: dbItem.name,
        price,
        quantity,
        gstPercentage,
        subtotal: itemNet,
        notes: item.notes || '',
      });
    }

    const totalDiscount = itemDiscountTotal + discountAmount;
    const subtotalAfterDiscount = Math.max(0, calculatedSubtotal - totalDiscount);
    const subtotalAfterItemDiscount = calculatedSubtotal - itemDiscountTotal;
    if (subtotalAfterItemDiscount > 0) {
      calculatedGst *= subtotalAfterDiscount / subtotalAfterItemDiscount;
    } else {
      calculatedGst = 0;
    }
    const serviceChargePercentage = settings?.serviceChargePercentage || 0;
    const serviceChargeAmount =
      subtotalAfterDiscount * serviceChargePercentage / 100;
    const grandTotal = Math.round(
      subtotalAfterDiscount + calculatedGst + serviceChargeAmount
    );
    const orderNumber = orderData.orderNumber || await this.generateOrderNumber();

    const order = await Order.create({
      orderNumber,
      customer: customerId || null,
      customerName: customerName || 'Walk-in Customer',
      customerPhone: customerPhone || '',
      items: processedItems,
      subtotal: calculatedSubtotal,
      discountAmount: totalDiscount,
      gstAmount: calculatedGst,
      serviceChargeAmount,
      grandTotal,
      paymentMethod,
      paymentStatus: 'paid',
    });

    if (customerId) {
      const customer = await Customer.findById(customerId);
      if (customer) {
        customer.totalVisits += 1;
        customer.totalSpent += grandTotal;
        customer.loyaltyPoints += Math.floor(grandTotal / 100) * 10;
        await customer.save();
      }
    }

    return order;
  }

  async getOrders(query = {}) {
    const { startDate, endDate, paymentMethod, page = 1, limit = 50 } = query;
    const filter = {};

    if (paymentMethod) filter.paymentMethod = paymentMethod;
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.$gte = new Date(startDate);
      if (endDate) filter.createdAt.$lte = new Date(endDate);
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [orders, total] = await Promise.all([
      Order.find(filter).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Order.countDocuments(filter),
    ]);

    return { orders, total };
  }

  async getOrderById(orderId) {
    const order = await Order.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);
    return order;
  }
}

module.exports = new OrderService();
