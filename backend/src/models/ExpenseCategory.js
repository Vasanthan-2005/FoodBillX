const mongoose = require('mongoose');

const expenseCategorySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Category name is required'],
      trim: true,
      unique: true,
    },
    icon: {
      type: String,
      default: 'attach_money',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

const ExpenseCategory = mongoose.model('ExpenseCategory', expenseCategorySchema);
module.exports = ExpenseCategory;
