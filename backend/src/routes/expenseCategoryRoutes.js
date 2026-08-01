const express = require('express');
const expenseCategoryController = require('../controllers/expenseCategoryController');

const router = express.Router();

router.get('/', expenseCategoryController.getCategories);
router.post('/', expenseCategoryController.createCategory);
router.put('/:id', expenseCategoryController.updateCategory);
router.delete('/:id', expenseCategoryController.deleteCategory);

module.exports = router;
