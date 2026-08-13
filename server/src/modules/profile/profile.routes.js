// profile.routes.js
const express = require('express');
const router = express.Router();
const profileController = require('./profile.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');
const upload = require('../../shared/middlewares/upload.middleware');

// All profile routes are authenticated
router.use(protect);

// GET /api/profile -> Fetch user profile and activity stats
router.get('/', profileController.getProfile);

// PUT /api/profile -> Update user profile details
router.put('/', profileController.updateProfile);

// POST /api/profile/upload-image -> Upload profile avatar
router.post('/upload-image', upload.single('image'), profileController.uploadProfileImage);

// DELETE /api/profile/account -> Delete user account from database
router.delete('/account', profileController.deleteAccount);
router.delete('/', profileController.deleteAccount);

module.exports = router;
