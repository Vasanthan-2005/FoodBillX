const express = require('express');
const syncController = require('../controllers/syncController');

const router = express.Router();

router.get('/pull', syncController.pull);
router.post('/push', syncController.push);

module.exports = router;
