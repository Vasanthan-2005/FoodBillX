const settingsService = require('../services/settingsService');
const { sendSuccess } = require('../utils/apiResponse');

class SettingsController {
  async getSettings(req, res, next) {
    try {
      const settings = await settingsService.getSettings();
      return sendSuccess(res, 200, 'Settings retrieved successfully', { settings });
    } catch (error) {
      next(error);
    }
  }

  async updateSettings(req, res, next) {
    try {
      const settings = await settingsService.updateSettings(req.body);
      return sendSuccess(res, 200, 'Settings updated successfully', { settings });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new SettingsController();
