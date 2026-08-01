const orderService = require('../services/orderService');
const { sendSuccess } = require('../utils/apiResponse');

class OrderController {
  async createOrder(req, res, next) {
    try {
      const order = await orderService.createOrder(req.body);
      return sendSuccess(res, 201, 'Order created successfully', { order });
    } catch (error) {
      next(error);
    }
  }

  async getOrders(req, res, next) {
    try {
      const { orders, total } = await orderService.getOrders(req.query);
      return sendSuccess(res, 200, 'Orders retrieved successfully', orders, { total });
    } catch (error) {
      next(error);
    }
  }

  async getOrderById(req, res, next) {
    try {
      const order = await orderService.getOrderById(req.params.id);
      return sendSuccess(res, 200, 'Order details retrieved', { order });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new OrderController();
