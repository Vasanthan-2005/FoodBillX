const express = require('express');
const {
  uploadMiddleware,
  uploadSingleImage,
  deleteImageFile,
} = require('../controllers/uploadController');

const router = express.Router();

router.post('/', uploadMiddleware, uploadSingleImage);
router.delete('/:filename', deleteImageFile);

module.exports = router;
