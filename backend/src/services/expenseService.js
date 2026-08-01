const Expense = require('../models/Expense');
const AppError = require('../utils/appError');

class ExpenseService {
  async getExpenses(query = {}) {
    const { startDate, endDate, category } = query;
    const filter = {};

    if (category) filter.category = { $regex: category, $options: 'i' };
    if (startDate || endDate) {
      filter.date = {};
      if (startDate) filter.date.$gte = new Date(startDate);
      if (endDate) filter.date.$lte = new Date(endDate);
    }

    const expenses = await Expense.find(filter).sort({ date: -1 });
    const totalExpenseAmount = expenses.reduce((sum, item) => sum + item.amount, 0);

    return { expenses, totalExpenseAmount };
  }

  async createExpense(expenseData) {
    // Auto-set title from category name so category is the identifier
    const data = {
      ...expenseData,
      title: expenseData.category || expenseData.title || 'Expense',
    };
    return await Expense.create(data);
  }

  async deleteExpense(expenseId) {
    const expense = await Expense.findByIdAndDelete(expenseId);
    if (!expense) throw new AppError('Expense record not found', 404);
    return { message: 'Expense record deleted' };
  }
}

module.exports = new ExpenseService();
