const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Existing routes
router.post('/register', authController.register);
router.post('/login', authController.login);

// --- NEW ROUTES FOR FORGOT PASSWORD ---
// Step 1: Fetch the question for a specific email
router.post('/get-security-question', authController.getSecurityQuestion);
// Step 2: Submit the answer and new password
router.post('/reset-password', authController.resetPassword);

module.exports = router;