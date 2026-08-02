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

/**
 * Master Level 1 Authentication
 * 
 * Verifies Master ID and Master Password against backend environment variables.
 */
exports.masterLogin = async (req, res, next) => {
  try {
    const { masterId, masterPassword } = req.body;

    if (!masterId || !masterPassword || typeof masterId !== 'string' || typeof masterPassword !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Master ID and Master Password are required.',
      });
    }

    const envMasterId = process.env.MASTER_ID || 'admin';
    const envMasterPassword = process.env.MASTER_PASSWORD || 'masterpass123';

    const cleanInputId = masterId.trim();
    const cleanInputPass = masterPassword.trim();

    if (cleanInputId === envMasterId && cleanInputPass === envMasterPassword) {
      return res.status(200).json({
        success: true,
        message: 'Master authentication successful.',
        data: {
          authenticated: true,
        },
      });
    }

    return res.status(401).json({
      success: false,
      message: 'Invalid Master ID or Password. Access denied.',
    });
  } catch (error) {
    next(error);
  }
};
