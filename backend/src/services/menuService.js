const Category = require('../models/Category');
const MenuItem = require('../models/MenuItem');
const AppError = require('../utils/appError');

class MenuService {
  // Categories
  async getCategories() {
    return await Category.find({ isActive: true }).sort({ sortOrder: 1, name: 1 });
  }

  async createCategory(data) {
    const existing = await Category.findOne({ name: data.name.trim() });
    if (existing) {
      if (!existing.isActive) {
        existing.isActive = true;
        if (data.icon) existing.icon = data.icon;
        await existing.save();
        return existing;
      }
      throw new AppError('Category with this name already exists', 400);
    }
    return await Category.create(data);
  }

  async updateCategory(categoryId, data) {
    const category = await Category.findByIdAndUpdate(
      categoryId,
      data,
      { new: true, runValidators: true }
    );
    if (!category) {
      throw new AppError('Category not found', 404);
    }
    return category;
  }

  async deleteCategory(categoryId) {
    const category = await Category.findByIdAndUpdate(
      categoryId,
      { isActive: false },
      { new: true }
    );
    if (!category) {
      throw new AppError('Category not found', 404);
    }
    await MenuItem.updateMany({ category: categoryId }, { isAvailable: false });
    return { message: 'Category deleted successfully' };
  }

  // Menu Items
  async getMenuItems(query = {}) {
    const { category, search, isVeg, isAvailable, page = 1, limit = 100 } = query;
    const filter = {};

    if (category) filter.category = category;
    if (isVeg !== undefined) filter.isVeg = isVeg === 'true';
    if (isAvailable !== undefined) filter.isAvailable = isAvailable === 'true';

    if (search) {
      filter.name = { $regex: search, $options: 'i' };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [items, total] = await Promise.all([
      MenuItem.find(filter)
        .populate('category', 'name icon')
        .sort({ category: 1, sortOrder: 1, name: 1 })
        .skip(skip)
        .limit(parseInt(limit)),
      MenuItem.countDocuments(filter),
    ]);

    return {
      items,
      pagination: {
        total,
        page: parseInt(page),
        pages: Math.ceil(total / parseInt(limit)),
      },
    };
  }

  async createMenuItem(data) {
    const categoryExists = await Category.findOne({ _id: data.category, isActive: true });
    if (!categoryExists) {
      throw new AppError('Invalid category selected', 400);
    }
    const item = await MenuItem.create(data);
    return await item.populate('category', 'name icon');
  }

  async updateMenuItem(itemId, data) {
    const item = await MenuItem.findByIdAndUpdate(
      itemId,
      data,
      { new: true, runValidators: true }
    ).populate('category', 'name icon');

    if (!item) {
      throw new AppError('Menu item not found', 404);
    }
    return item;
  }

  async toggleAvailability(itemId) {
    const item = await MenuItem.findById(itemId);
    if (!item) {
      throw new AppError('Menu item not found', 404);
    }
    item.isAvailable = !item.isAvailable;
    await item.save();
    return item;
  }

  async deleteMenuItem(itemId) {
    const item = await MenuItem.findByIdAndDelete(itemId);
    if (!item) {
      throw new AppError('Menu item not found', 404);
    }
    return { message: 'Menu item deleted successfully' };
  }
}

module.exports = new MenuService();
