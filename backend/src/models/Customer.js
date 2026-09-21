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
      default: null,
      trim: true,
      // Null/undefined values are excluded from unique constraint (sparse)
    },
  },
  {
    timestamps: true,
  }
);

// Sparse unique index: only enforce uniqueness when loyaltyCardNumber is non-null
customerSchema.index({ loyaltyCardNumber: 1 }, { unique: true, sparse: true });

// Convert empty string loyalty card to null so the sparse unique index works correctly
customerSchema.pre('save', function (next) {
  if (this.loyaltyCardNumber === '') this.loyaltyCardNumber = null;
  next();
});

const Customer = mongoose.model('Customer', customerSchema);
module.exports = Customer;
