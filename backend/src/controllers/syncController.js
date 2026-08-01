const syncService = require('../services/syncService');
const { sendSuccess } = require('../utils/apiResponse');

class SyncController {
  async pull(req, res, next) {
    try {
      const { since } = req.query;
      const changes = await syncService.pullChanges(since);
      return sendSuccess(res, 200, 'Sync pull completed successfully', changes);
    } catch (error) {
      next(error);
    }
  }

  async push(req, res, next) {
    try {
      const { operations } = req.body;
      const results = await syncService.pushBatch(operations);
      return sendSuccess(res, 200, 'Sync push batch processed', { results });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SyncController();
