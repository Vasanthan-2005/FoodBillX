const express = require('express');
const bootstrapController = require('../controllers/bootstrapController');

const router = express.Router();

router.get('/', bootstrapController.getBootstrap);

module.exports = router;
