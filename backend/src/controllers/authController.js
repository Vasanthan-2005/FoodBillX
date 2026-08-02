const BusinessSettings = require('../models/BusinessSettings');

/**
 * Verify Store Owner Identity
 * 
 * Verifies the registered store owner's phone number against BusinessSettings.
 */
exports.verifyOwnerIdentity = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone || typeof phone !== 'string' || phone.trim().isEmpty) {
      return res.status(400).json({
        success: false,
        message: 'Registered store phone number is required.',
      });
    }

    const cleanInputPhone = phone.trim().replace(/\D/g, '');
    if (cleanInputPhone.length < 7) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid phone number.',
      });
    }

    let settings = await BusinessSettings.findOne();
    if (!settings) {
      settings = await BusinessSettings.create({
        businessName: 'My Food Outlet',
        phone: cleanInputPhone,
      });
    }

    const registeredPhone = (settings.phone || '').trim().replace(/\D/g, '');

    // If no phone was previously saved in settings, bind the initial verified owner phone
    if (!registeredPhone) {
      settings.phone = phone.trim();
      await settings.save();
      return res.status(200).json({
        success: true,
        message: 'Owner identity verified successfully.',
        data: {
          verified: true,
          businessName: settings.businessName,
        },
      });
    }

    if (cleanInputPhone !== registeredPhone) {
      return res.status(400).json({
        success: false,
        message: 'Phone number does not match registered store owner records.',
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Owner identity verified successfully.',
      data: {
        verified: true,
        businessName: settings.businessName,
      },
    });
  } catch (error) {
    next(error);
  }
};
