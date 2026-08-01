const express = require('express');
const menuController = require('../controllers/menuController');

const router = express.Router();

router.get('/', menuController.getCategories);
router.post('/', menuController.createCategory);
router.put('/:id', menuController.updateCategory);
router.delete('/:id', menuController.deleteCategory);

module.exports = router;
