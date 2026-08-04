// auth.routes.js
const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Public OTP auth endpoints
router.post('/send-otp', authController.sendOtp);
router.post('/verify-otp', authController.verifyOtp);

// Authenticated user endpoints
router.post('/complete-profile', protect, authController.completeProfile);
router.get('/me', protect, authController.getMe);

module.exports = router;
