const path = require('path');
const fs = require('fs');
const multer = require('multer');
const AppError = require('../utils/appError');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../../public/uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Multer Storage Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const filename = `dish_${Date.now()}_${Math.round(Math.random() * 1e9)}${ext}`;
    cb(null, filename);
  },
});

// File Filter (Images Only)
const fileFilter = (req, file, cb) => {
  if (file.mimetype.startsWith('image/')) {
    cb(null, true);
  } else {
    cb(new AppError('Only image files (JPEG, PNG, WebP) are allowed!', 400), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB Limit
});

// Controller Action: Upload Single Image
const uploadSingleImage = (req, res, next) => {
  if (!req.file) {
    return next(new AppError('Please select an image file to upload', 400));
  }

  const protocol = req.protocol;
  const host = req.get('host');
  const imageUrl = `${protocol}://${host}/uploads/${req.file.filename}`;

  res.status(201).json({
    success: true,
    message: 'Image uploaded successfully',
    filename: req.file.filename,
    url: imageUrl,
    relativeUrl: `/uploads/${req.file.filename}`,
  });
};

// Controller Action: Delete Image from Server Disk
const deleteImageFile = (req, res, next) => {
  const { filename } = req.params;
  if (!filename) {
    return next(new AppError('Filename is required', 400));
  }

  const filePath = path.join(uploadsDir, path.basename(filename));
  if (fs.existsSync(filePath)) {
    try {
      fs.unlinkSync(filePath);
    } catch (e) {
      console.error('Failed to delete file:', e);
    }
  }

  res.status(200).json({
    success: true,
    message: 'Image deleted successfully',
  });
};

module.exports = {
  uploadMiddleware: upload.single('image'),
  uploadSingleImage,
  deleteImageFile,
};
