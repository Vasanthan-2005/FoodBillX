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
      default: 'INV-',
      trim: true,
    },
    taxPercentage: {
      type: Number,
      default: 5.0,
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
  },
  {
    timestamps: true,
  }
);

const BusinessSettings = mongoose.model('BusinessSettings', businessSettingsSchema);
module.exports = BusinessSettings;
