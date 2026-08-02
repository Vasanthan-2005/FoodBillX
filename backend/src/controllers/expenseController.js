const expenseService = require('../services/expenseService');
const { sendSuccess } = require('../utils/apiResponse');

class ExpenseController {
  async getExpenses(req, res, next) {
    try {
      const { expenses, totalExpenseAmount } = await expenseService.getExpenses(req.query);
      return sendSuccess(res, 200, 'Expenses retrieved successfully', expenses, { totalExpenseAmount });
    } catch (error) {
      next(error);
    }
  }

  async createExpense(req, res, next) {
    try {
      const expense = await expenseService.createExpense(req.body);
      req.io?.emit('expense_added', { expense });
      req.io?.emit('data_updated', { type: 'expense' });
      return sendSuccess(res, 201, 'Expense logged successfully', { expense });
    } catch (error) {
      next(error);
    }
  }

  async updateExpense(req, res, next) {
    try {
      const expense = await expenseService.updateExpense(req.params.id, req.body);
      req.io?.emit('data_updated', { type: 'expense' });
      return sendSuccess(res, 200, 'Expense updated successfully', { expense });
    } catch (error) {
      next(error);
    }
  }

  async deleteExpense(req, res, next) {
    try {
      const result = await expenseService.deleteExpense(req.params.id);
      req.io?.emit('data_updated', { type: 'expense' });
      return sendSuccess(res, 200, result.message);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ExpenseController();
