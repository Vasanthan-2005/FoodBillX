const BusinessSettings = require('../models/BusinessSettings');

class SettingsService {
  async getSettings() {
    let settings = await BusinessSettings.findOne();
    if (!settings) {
      settings = await BusinessSettings.create({
        businessName: 'My Food Outlet',
        phone: '9876543210',
        currency: '₹',
        invoicePrefix: 'INV-',
        invoiceFooter: 'Thank you for dining with us!',
      });
    }
    return settings;
  }

  async updateSettings(updateData) {
    let settings = await BusinessSettings.findOne();
    if (!settings) {
      settings = new BusinessSettings(updateData);
    } else {
      Object.assign(settings, updateData);
    }
    await settings.save();
    return settings;
  }
}

module.exports = new SettingsService();
