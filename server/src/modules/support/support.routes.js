// support.routes.js
const express = require('express');
const router = express.Router();
const supportCtrl = require('./support.controller');

// Public route to fetch support contact details & published policies
router.get('/details', supportCtrl.getSupportDetails);

module.exports = router;
