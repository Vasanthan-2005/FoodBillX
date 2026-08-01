const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Customer name is required'],
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
      unique: true,
    },
    email: {
      type: String,
      lowercase: true,
      trim: true,
      default: '',
    },
    address: {
      type: String,
      default: '',
      trim: true,
    },
    birthday: {
      type: Date,
    },
    notes: {
      type: String,
      default: '',
    },
    totalVisits: {
      type: Number,
      default: 0,
    },
    totalSpent: {
      type: Number,
      default: 0.0,
    },
    loyaltyPoints: {
      type: Number,
      default: 0,
    },
    loyaltyCardNumber: {
      type: String,
      default: '',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

customerSchema.index({ loyaltyCardNumber: 1 });

const Customer = mongoose.model('Customer', customerSchema);
module.exports = Customer;
