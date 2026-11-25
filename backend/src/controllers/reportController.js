const reportService = require('../services/reportService');
const { sendSuccess } = require('../utils/apiResponse');
const AppError = require('../utils/appError');

class ReportController {
  async getDashboard(req, res, next) {
    try {
      const summary = await reportService.getDashboardSummary();
      return sendSuccess(res, 200, 'Dashboard summary retrieved', { summary });
    } catch (error) {
      next(error);
    }
  }

  async getAnalytics(req, res, next) {
    try {
      const analytics = await reportService.getFilteredAnalytics(req.query);
      return sendSuccess(res, 200, 'Analytics reports retrieved', { analytics });
    } catch (error) {
      next(error);
    }
  }

  async getOrders(req, res, next) {
    try {
      const ordersData = await reportService.getOrdersList(req.query);
      return sendSuccess(res, 200, 'Orders retrieved successfully', ordersData);
    } catch (error) {
      next(error);
    }
  }

  async deleteOrder(req, res, next) {
    try {
      const { id } = req.params;
      const result = await reportService.deleteOrderById(id);
      if (!result) {
        throw new AppError('Order not found', 404);
      }
      if (req.io) {
        req.io.emit('data_updated', {
          source: 'order_deleted',
          orderId: id,
          timestamp: new Date().toISOString(),
        });
      }
      return sendSuccess(res, 200, 'Order deleted and customer totals recalculated', result);
    } catch (error) {
      next(error);
    }
  }

  async getCustomers(req, res, next) {
    try {
      const customersData = await reportService.getCustomersList(req.query);
      return sendSuccess(res, 200, 'Customers retrieved successfully', customersData);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportController();
