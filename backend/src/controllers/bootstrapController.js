const bootstrapService = require('../services/bootstrapService');
const { sendSuccess } = require('../utils/apiResponse');

class BootstrapController {
  async getBootstrap(req, res, next) {
    try {
      const data = await bootstrapService.getBootstrapData();
      return sendSuccess(res, 200, 'Application bootstrap data retrieved successfully', data);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new BootstrapController();
