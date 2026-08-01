const mongoose = require('mongoose');

const syncTombstoneSchema = new mongoose.Schema({
  entityType: { type: String, required: true, index: true },
  serverId: { type: String, required: true },
  deletedAt: { type: Date, default: Date.now, index: true },
});

syncTombstoneSchema.index({ entityType: 1, serverId: 1 }, { unique: true });

module.exports = mongoose.model('SyncTombstone', syncTombstoneSchema);
