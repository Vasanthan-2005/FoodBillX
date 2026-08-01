const express = require('express');
const menuController = require('../controllers/menuController');

const router = express.Router();

router.get('/', menuController.getMenuItems);
router.post('/', menuController.createMenuItem);
router.put('/:id', menuController.updateMenuItem);
router.patch('/:id/toggle-availability', menuController.toggleAvailability);
router.delete('/:id', menuController.deleteMenuItem);

module.exports = router;
