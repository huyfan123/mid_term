const multer = require('multer');

// Store file in memory as Buffer for fast Cloudinary upload
const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  // Check if MIME type is an image
  const isImageMime = file.mimetype && file.mimetype.startsWith('image/');
  
  // Check extension from original filename
  const isImageExt = file.originalname && /\.(jpe?g|png|webp|gif|bmp|heic|svg)$/i.test(file.originalname);

  // Accept if it is an image MIME type, or has an image extension (handles octet-stream from mobile/web)
  if (isImageMime || isImageExt || file.mimetype === 'application/octet-stream') {
    cb(null, true);
  } else {
    cb(new Error('Chỉ chấp nhận file định dạng hình ảnh!'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
});

module.exports = upload;
