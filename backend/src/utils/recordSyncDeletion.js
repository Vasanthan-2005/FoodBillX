const SyncTombstone = require('../models/SyncTombstone');

module.exports = async function recordSyncDeletion(entityType, serverId) {
  await SyncTombstone.updateOne(
    { entityType, serverId: serverId.toString() },
    { $set: { deletedAt: new Date() } },
    { upsert: true }
  );
};
