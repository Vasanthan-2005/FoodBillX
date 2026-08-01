const express = require('express');
const customerController = require('../controllers/customerController');

const router = express.Router();

router.get('/', customerController.getCustomers);
router.post('/', customerController.createCustomer);
router.put('/:id', customerController.updateCustomer);
router.delete('/:id', customerController.deleteCustomer);
router.post('/:id/assign-card', customerController.assignLoyaltyCard);

module.exports = router;
