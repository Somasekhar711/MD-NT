const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// When someone posts to '/register', run the register logic
router.post('/register', authController.register);
// When someone posts to '/login', run the login logic
router.post('/login', authController.login);

module.exports = router;