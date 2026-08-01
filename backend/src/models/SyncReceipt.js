const mongoose = require('mongoose');

const syncReceiptSchema = new mongoose.Schema(
  {
    operationId: { type: String, required: true, unique: true, index: true },
    entityType: { type: String, required: true },
    localId: { type: Number, required: true },
    serverId: { type: String, default: null },
  },
  { timestamps: true }
);

// Receipts bound retry idempotency without growing indefinitely.
syncReceiptSchema.index({ createdAt: 1 }, { expireAfterSeconds: 60 * 60 * 24 * 30 });

module.exports = mongoose.model('SyncReceipt', syncReceiptSchema);
