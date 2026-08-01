const syncService = require('../services/syncService');
const { sendSuccess } = require('../utils/apiResponse');
const AppError = require('../utils/appError');

class SyncController {
  async pull(req, res, next) {
    try {
      const { since } = req.query;
      if (since && Number.isNaN(Date.parse(since))) {
        throw new AppError('Invalid since timestamp', 400);
      }
      const changes = await syncService.pullChanges(since);
      return sendSuccess(res, 200, 'Sync pull completed successfully', changes);
    } catch (error) {
      next(error);
    }
  }

  async push(req, res, next) {
    try {
      const { operations } = req.body;
      if (!Array.isArray(operations)) {
        throw new AppError('operations must be an array', 400);
      }
      if (operations.length > 100) {
        throw new AppError('A sync batch cannot exceed 100 operations', 400);
      }
      const results = await syncService.pushBatch(operations);
      return sendSuccess(res, 200, 'Sync push batch processed', { results });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SyncController();
