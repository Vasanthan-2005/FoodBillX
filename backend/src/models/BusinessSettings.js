const mongoose = require('mongoose');

const businessSettingsSchema = new mongoose.Schema(
  {
    businessName: {
      type: String,
      required: [true, 'Business name is required'],
      trim: true,
      default: 'My Food Outlet',
    },
    logo: {
      type: String,
      default: '',
    },
    phone: {
      type: String,
      default: '',
      trim: true,
    },
    address: {
      type: String,
      default: '',
      trim: true,
    },
    gstin: {
      type: String,
      default: '',
      trim: true,
    },
    currency: {
      type: String,
      default: '₹',
      trim: true,
    },
    invoicePrefix: {
      type: String,
      default: 'B',
      trim: true,
    },
    lastBillSequenceNumber: {
      type: Number,
      default: 0,
      min: 0,
    },
    taxPercentage: {
      type: Number,
      default: 0.0,
      min: 0,
      max: 100,
    },
    serviceChargePercentage: {
      type: Number,
      default: 0.0,
      min: 0,
      max: 100,
    },
    invoiceFooter: {
      type: String,
      default: 'Thank you for dining with us!',
      trim: true,
    },
    loyaltyTargetVisits: {
      type: Number,
      default: 6,
      min: 1,
    },
    loyaltyRewardType: {
      type: String,
      default: 'Free Drink',
      trim: true,
    },
    loyaltyRewardDescription: {
      type: String,
      default: 'Free Drink',
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

const BusinessSettings = mongoose.model('BusinessSettings', businessSettingsSchema);
module.exports = BusinessSettings;
