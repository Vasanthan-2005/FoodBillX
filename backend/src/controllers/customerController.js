const customerService = require('../services/customerService');
const { sendSuccess } = require('../utils/apiResponse');

class CustomerController {
  async getCustomers(req, res, next) {
    try {
      const customers = await customerService.getCustomers(req.query);
      return sendSuccess(res, 200, 'Customers retrieved successfully', customers);
    } catch (error) {
      next(error);
    }
  }

  async createCustomer(req, res, next) {
    try {
      const customer = await customerService.createCustomer(req.body);
      return sendSuccess(res, 201, 'Customer created successfully', { customer });
    } catch (error) {
      next(error);
    }
  }

  async updateCustomer(req, res, next) {
    try {
      const customer = await customerService.updateCustomer(req.params.id, req.body);
      return sendSuccess(res, 200, 'Customer updated successfully', { customer });
    } catch (error) {
      next(error);
    }
  }

  async deleteCustomer(req, res, next) {
    try {
      const result = await customerService.deleteCustomer(req.params.id);
      return sendSuccess(res, 200, result.message);
    } catch (error) {
      next(error);
    }
  }

  async assignLoyaltyCard(req, res, next) {
    try {
      const { cardNumber } = req.body;
      const customer = await customerService.assignLoyaltyCard(req.params.id, cardNumber);
      return sendSuccess(res, 200, 'Loyalty card assigned successfully', { customer });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CustomerController();
