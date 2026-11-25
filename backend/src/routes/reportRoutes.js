const express = require('express');
const reportController = require('../controllers/reportController');

const router = express.Router();

router.get('/dashboard', reportController.getDashboard);
router.get('/analytics', reportController.getAnalytics);
router.get('/orders', reportController.getOrders);
router.delete('/orders/:id', reportController.deleteOrder);
router.get('/customers', reportController.getCustomers);

module.exports = router;
