const expenseCategoryService = require('../services/expenseCategoryService');
const { sendSuccess } = require('../utils/apiResponse');

class ExpenseCategoryController {
  async getCategories(req, res, next) {
    try {
      const categories = await expenseCategoryService.getCategories();
      return sendSuccess(res, 200, 'Expense categories retrieved', { categories });
    } catch (error) {
      next(error);
    }
  }

  async createCategory(req, res, next) {
    try {
      const category = await expenseCategoryService.createCategory(req.body);
      return sendSuccess(res, 201, 'Expense category created', { category });
    } catch (error) {
      next(error);
    }
  }

  async updateCategory(req, res, next) {
    try {
      const category = await expenseCategoryService.updateCategory(req.params.id, req.body);
      return sendSuccess(res, 200, 'Expense category updated', { category });
    } catch (error) {
      next(error);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const result = await expenseCategoryService.deleteCategory(req.params.id);
      return sendSuccess(res, 200, result.message);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ExpenseCategoryController();
