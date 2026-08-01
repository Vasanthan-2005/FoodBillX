const { body } = require('express-validator');

const categoryValidator = [
  body('name').trim().notEmpty().withMessage('Category name is required'),
  body('icon').optional().trim(),
  body('sortOrder').optional().isNumeric().withMessage('Sort order must be a number'),
];

const menuItemValidator = [
  body('name').trim().notEmpty().withMessage('Item name is required'),
  body('category').notEmpty().withMessage('Category ID is required').isMongoId().withMessage('Invalid Category ID'),
  body('price').isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('discount').optional().isFloat({ min: 0 }).withMessage('Discount must be a positive number'),
  body('gstPercentage').optional().isFloat({ min: 0, max: 100 }).withMessage('GST % must be between 0 and 100'),
  body('isVeg').optional().isBoolean().withMessage('isVeg must be a boolean'),
  body('isAvailable').optional().isBoolean().withMessage('isAvailable must be a boolean'),
];

module.exports = {
  categoryValidator,
  menuItemValidator,
};
