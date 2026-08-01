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
}

module.exports = new ReportController();
