const router = require('express').Router();
const { protect } = require('../../shared/middlewares/auth.middleware');
const upload = require('../../shared/middlewares/upload.middleware');
const controller = require('./profile.controller');

router.get('/', protect, controller.getProfile);
router.patch('/', protect, controller.updateProfile);
router.post('/roles/owner', protect, controller.becomeOwner);
router.post('/photo', protect, upload.single('photo'), controller.uploadPhoto);
router.post('/ratings', protect, controller.submitRating);

module.exports = router;
