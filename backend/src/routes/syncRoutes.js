const express = require('express');
const syncController = require('../controllers/syncController');

const router = express.Router();

router.get('/pull', syncController.pull);
router.post('/push', syncController.push);
router.get('/export', syncController.export);
router.get('/status', syncController.status);

module.exports = router;
