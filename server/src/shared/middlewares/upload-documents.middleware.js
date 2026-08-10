const multer = require('multer');
const path = require('path');

const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/jpg',
  'application/pdf',
];

const allowedExtensions = ['.jpg', '.jpeg', '.png', '.pdf'];

const storage = multer.memoryStorage();

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();
  if (!allowedExtensions.includes(ext) || !allowedMimeTypes.includes(file.mimetype)) {
    return cb(new Error('Unsupported file type. Allowed types: jpg, jpeg, png, pdf'));
  }
  cb(null, true);
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB
    files: 5,
  },
});

const uploadDocuments = upload.fields([
  { name: 'rc', maxCount: 1 },
  { name: 'insurance', maxCount: 1 },
  { name: 'fc', maxCount: 1 },
  { name: 'puc', maxCount: 1 },
  { name: 'permit', maxCount: 1 },
]);

module.exports = {
  uploadDocuments,
};
