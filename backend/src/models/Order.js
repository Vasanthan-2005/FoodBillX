const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  menuItem: {
    type: mongoose.Schema.Types.Mixed,
    ref: 'MenuItem',
    default: null,
  },
  name: {
    type: String,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  gstPercentage: {
    type: Number,
    default: 0.0,
  },
  subtotal: {
    type: Number,
    required: true,
  },
  notes: {
    type: String,
    default: '',
  },
});

const orderSchema = new mongoose.Schema(
  {
    orderNumber: {
      type: String,
      required: true,
      unique: true,
    },
    customer: {
      type: mongoose.Schema.Types.Mixed,
      ref: 'Customer',
      default: null,
    },
    customerName: {
      type: String,
      default: 'Walk-in Customer',
    },
    customerPhone: {
      type: String,
      default: '',
    },
    loyaltyCardNumber: {
      type: String,
      default: '',
    },
    visitCount: {
      type: Number,
      default: 1,
    },
    rewardStatus: {
      type: String,
      default: '',
    },
    orderStatus: {
      type: String,
      enum: ['completed', 'edited', 'refunded'],
      default: 'completed',
    },
    items: [orderItemSchema],
    subtotal: {
      type: Number,
      required: true,
    },
    discountAmount: {
      type: Number,
      default: 0.0,
    },
    gstAmount: {
      type: Number,
      default: 0.0,
    },
    serviceChargeAmount: {
      type: Number,
      default: 0.0,
      min: 0,
    },
    grandTotal: {
      type: Number,
      required: true,
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'upi', 'card', 'wallet'],
      default: 'cash',
    },
    paymentStatus: {
      type: String,
      enum: ['paid', 'pending'],
      default: 'paid',
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

orderSchema.index({ createdAt: -1 });

const Order = mongoose.model('Order', orderSchema);
module.exports = Order;
