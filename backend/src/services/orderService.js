const Order = require('../models/Order');
const Customer = require('../models/Customer');
const MenuItem = require('../models/MenuItem');
const BusinessSettings = require('../models/BusinessSettings');
const AppError = require('../utils/appError');

class OrderService {
  async generateOrderNumber() {
    let settings = await BusinessSettings.findOne();
    if (!settings) {
      settings = await BusinessSettings.create({ businessName: 'Honeymoon Biryani' });
    }
    settings.lastBillSequenceNumber = (settings.lastBillSequenceNumber || 0) + 1;
    await settings.save();

    const prefix = settings.invoicePrefix || 'B';
    const seqStr = String(settings.lastBillSequenceNumber).padStart(5, '0');
    return `${prefix}${seqStr}`;
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

      calculatedSubtotal += itemSubtotal;
      itemDiscountTotal += itemDiscount;

      processedItems.push({
        menuItem: dbItem._id,
        name: dbItem.name,
        price,
        quantity,
        gstPercentage: 0,
        subtotal: itemNet,
        notes: item.notes || '',
      });
    }

    const totalDiscount = itemDiscountTotal + discountAmount;
    const subtotalAfterDiscount = Math.max(0, calculatedSubtotal - totalDiscount);
    calculatedGst = 0;
    const serviceChargePercentage = settings?.serviceChargePercentage || 0;
    const serviceChargeAmount =
      subtotalAfterDiscount * serviceChargePercentage / 100;
    const grandTotal = Math.round(
      subtotalAfterDiscount + serviceChargeAmount
    );
    const orderNumber = await this.generateOrderNumber();

    let customerObj = null;
    let loyaltyCardNumber = orderData.loyaltyCardNumber || '';
    let visitCount = 1;
    let rewardStatus = 'Standard Visit';

    const targetVisits = settings?.loyaltyTargetVisits || 6;
    const rewardType = settings?.loyaltyRewardType || 'Free Drink';

    if (customerId) {
      customerObj = await Customer.findById(customerId);
    } else if (customerPhone) {
      customerObj = await Customer.findOne({ phone: customerPhone.trim() });
    }

    if (customerObj) {
      customerObj.totalVisits += 1;
      customerObj.totalSpent += grandTotal;
      customerObj.loyaltyPoints += Math.floor(grandTotal / 100) * 10;
      visitCount = customerObj.totalVisits;
      loyaltyCardNumber = customerObj.loyaltyCardNumber || loyaltyCardNumber;

      if (visitCount % targetVisits === 0) {
        rewardStatus = `🎉 Loyalty Reward Available: ${rewardType}`;
      } else {
        const remaining = targetVisits - (visitCount % targetVisits);
        rewardStatus = `Visit ${visitCount} (${remaining} more for ${rewardType})`;
      }
      await customerObj.save();
    }

    const order = await Order.create({
      orderNumber,
      customer: customerObj?._id || customerId || null,
      customerName: customerName || customerObj?.name || 'Walk-in Customer',
      customerPhone: customerPhone || customerObj?.phone || '',
      loyaltyCardNumber,
      visitCount,
      rewardStatus,
      orderStatus: 'completed',
      items: processedItems,
      subtotal: calculatedSubtotal,
      discountAmount: totalDiscount,
      gstAmount: calculatedGst,
      serviceChargeAmount,
      grandTotal,
      paymentMethod,
      paymentStatus: 'paid',
    });

    return order;
  }

  async getOrders(query = {}) {
    const { startDate, endDate, paymentMethod, status, page = 1, limit = 100 } = query;
    const filter = {};

    if (paymentMethod) filter.paymentMethod = paymentMethod;
    if (status) filter.orderStatus = status;
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

  async updateOrder(orderId, updateData) {
    const order = await Order.findByIdAndUpdate(
      orderId,
      { ...updateData, orderStatus: 'edited' },
      { new: true, runValidators: true }
    );
    if (!order) throw new AppError('Order not found', 404);
    return order;
  }

  async refundOrder(orderId) {
    const order = await Order.findById(orderId);
    if (!order) throw new AppError('Order not found', 404);

    order.orderStatus = 'refunded';
    order.paymentStatus = 'pending';
    await order.save();

    if (order.customer) {
      const customer = await Customer.findById(order.customer);
      if (customer) {
        customer.totalSpent = Math.max(0, customer.totalSpent - order.grandTotal);
        await customer.save();
      }
    }

    return order;
  }

  async deleteOrder(orderId) {
    const order = await Order.findByIdAndDelete(orderId);
    if (!order) throw new AppError('Order not found', 404);
    return { message: 'Order deleted successfully' };
  }
}

module.exports = new OrderService();
