const Expense = require('../models/Expense');
const AppError = require('../utils/appError');

class ExpenseService {
  async getExpenses(query = {}) {
    const { startDate, endDate, category, search } = query;
    const filter = {};

    if (category) filter.category = { $regex: category, $options: 'i' };
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { category: { $regex: search, $options: 'i' } },
        { notes: { $regex: search, $options: 'i' } },
      ];
    }
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
    const data = {
      ...expenseData,
      title: expenseData.title || expenseData.name || expenseData.category || 'Expense',
      category: expenseData.category || 'Miscellaneous',
    };
    return await Expense.create(data);
  }

  async updateExpense(expenseId, expenseData) {
    const expense = await Expense.findByIdAndUpdate(
      expenseId,
      {
        ...expenseData,
        title: expenseData.title || expenseData.name || expenseData.category,
      },
      { new: true, runValidators: true }
    );
    if (!expense) throw new AppError('Expense record not found', 404);
    return expense;
  }

  async deleteExpense(expenseId) {
    const expense = await Expense.findByIdAndDelete(expenseId);
    if (!expense) throw new AppError('Expense record not found', 404);
    return { message: 'Expense record deleted' };
  }
}

module.exports = new ExpenseService();
