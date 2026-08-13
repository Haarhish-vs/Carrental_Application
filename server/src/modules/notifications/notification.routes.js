// notification.routes.js
const express = require('express');
const router = express.Router();
const notificationController = require('./notification.controller');
const { protect } = require('../../shared/middlewares/auth.middleware');

// Protect notification endpoints with JWT auth
router.use(protect);

router.post('/register-token', (req, res) => notificationController.registerToken(req, res));
router.post('/unregister-token', (req, res) => notificationController.unregisterToken(req, res));

module.exports = router;
