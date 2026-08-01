const ExpenseCategory = require('../models/ExpenseCategory');
const AppError = require('../utils/appError');

// Default categories seeded on first call
const DEFAULT_CATEGORIES = [
  { name: 'Rent', icon: 'home' },
  { name: 'Gas', icon: 'local_fire_department' },
  { name: 'Electricity', icon: 'bolt' },
  { name: 'Vegetables', icon: 'eco' },
  { name: 'Chicken', icon: 'set_meal' },
  { name: 'Meat', icon: 'restaurant' },
  { name: 'Salary', icon: 'people' },
  { name: 'Miscellaneous', icon: 'category' },
];

class ExpenseCategoryService {
  async getCategories() {
    const count = await ExpenseCategory.countDocuments({ isActive: true });
    if (count === 0) {
      // Seed defaults on first fetch
      await ExpenseCategory.insertMany(DEFAULT_CATEGORIES);
    }
    return await ExpenseCategory.find({ isActive: true }).sort({ name: 1 });
  }

  async createCategory(data) {
    const existing = await ExpenseCategory.findOne({ name: { $regex: `^${data.name.trim()}$`, $options: 'i' } });
    if (existing) {
      if (!existing.isActive) {
        existing.isActive = true;
        await existing.save();
        return existing;
      }
      throw new AppError('Expense category with this name already exists', 400);
    }
    return await ExpenseCategory.create(data);
  }

  async updateCategory(categoryId, data) {
    const category = await ExpenseCategory.findByIdAndUpdate(
      categoryId,
      { name: data.name, icon: data.icon },
      { new: true, runValidators: true }
    );
    if (!category) throw new AppError('Expense category not found', 404);
    return category;
  }

  async deleteCategory(categoryId) {
    const category = await ExpenseCategory.findByIdAndUpdate(
      categoryId,
      { isActive: false },
      { new: true }
    );
    if (!category) throw new AppError('Expense category not found', 404);
    return { message: 'Expense category deleted' };
  }
}

module.exports = new ExpenseCategoryService();
