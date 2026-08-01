const menuService = require('../services/menuService');
const { sendSuccess } = require('../utils/apiResponse');

class MenuController {
  // Category controllers
  async getCategories(req, res, next) {
    try {
      const categories = await menuService.getCategories();
      return sendSuccess(res, 200, 'Categories retrieved successfully', { categories });
    } catch (error) {
      next(error);
    }
  }

  async createCategory(req, res, next) {
    try {
      const category = await menuService.createCategory(req.body);
      return sendSuccess(res, 201, 'Category created successfully', { category });
    } catch (error) {
      next(error);
    }
  }

  async updateCategory(req, res, next) {
    try {
      const category = await menuService.updateCategory(req.params.id, req.body);
      return sendSuccess(res, 200, 'Category updated successfully', { category });
    } catch (error) {
      next(error);
    }
  }

  async deleteCategory(req, res, next) {
    try {
      const result = await menuService.deleteCategory(req.params.id);
      return sendSuccess(res, 200, result.message);
    } catch (error) {
      next(error);
    }
  }

  // Menu Item controllers
  async getMenuItems(req, res, next) {
    try {
      const result = await menuService.getMenuItems(req.query);
      return sendSuccess(res, 200, 'Menu items retrieved successfully', result.items, result.pagination);
    } catch (error) {
      next(error);
    }
  }

  async createMenuItem(req, res, next) {
    try {
      const item = await menuService.createMenuItem(req.body);
      return sendSuccess(res, 201, 'Menu item created successfully', { item });
    } catch (error) {
      next(error);
    }
  }

  async updateMenuItem(req, res, next) {
    try {
      const item = await menuService.updateMenuItem(req.params.id, req.body);
      return sendSuccess(res, 200, 'Menu item updated successfully', { item });
    } catch (error) {
      next(error);
    }
  }

  async toggleAvailability(req, res, next) {
    try {
      const item = await menuService.toggleAvailability(req.params.id);
      return sendSuccess(res, 200, 'Item availability updated', { item });
    } catch (error) {
      next(error);
    }
  }

  async deleteMenuItem(req, res, next) {
    try {
      const result = await menuService.deleteMenuItem(req.params.id);
      return sendSuccess(res, 200, result.message);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new MenuController();
