const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    // category is a free-text string referencing an ExpenseCategory name
    category: {
      type: String,
      required: [true, 'Expense category is required'],
      trim: true,
      default: 'Miscellaneous',
    },
    // title mirrors category for display; auto-set by the service
    title: {
      type: String,
      trim: true,
      default: '',
    },
    amount: {
      type: Number,
      required: [true, 'Expense amount is required'],
      min: [0, 'Amount cannot be negative'],
    },
    date: {
      type: Date,
      default: Date.now,
    },
    notes: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

expenseSchema.index({ date: -1 });
expenseSchema.index({ category: 1 });

const Expense = mongoose.model('Expense', expenseSchema);
module.exports = Expense;
