const express = require('express');
const authController = require('../controllers/authController');

const router = express.Router();

router.post('/verify-owner', authController.verifyOwnerIdentity);
router.post('/master-login', authController.masterLogin);

module.exports = router;
