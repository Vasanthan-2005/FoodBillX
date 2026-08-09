const reportService = require('../services/reportService');
const { sendSuccess } = require('../utils/apiResponse');

class ReportController {
  async getDashboard(req, res, next) {
    try {
      const summary = await reportService.getDashboardSummary();
      return sendSuccess(res, 200, 'Dashboard summary retrieved', { summary });
    } catch (error) {
      next(error);
    }
  }

  async getAnalytics(req, res, next) {
    try {
      const analytics = await reportService.getFilteredAnalytics(req.query);
      return sendSuccess(res, 200, 'Analytics reports retrieved', { analytics });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ReportController();
