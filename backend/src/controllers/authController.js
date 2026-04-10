const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken'); // Moved to the top for a cleaner file!
const User = require('../models/user'); 
const jwtSecret = process.env.JWT_SECRET;

// Logic for Registering a new user
exports.register = async (req, res) => {
  try {
    // 1. Get data from the frontend (Flutter)
    const { name, email, password, securityQuestion, securityAnswer } = req.body;

    // 2. Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // 3. Hash sensitive values (security!)
    const hashedPassword = await bcrypt.hash(password, 10);
    const normalizedSecurityAnswer = (securityAnswer || 'none').trim().toLowerCase();
    const hashedSecurityAnswer = await bcrypt.hash(normalizedSecurityAnswer, 10);

    // 4. Create the new user in the database (Now with security fields)
    const newUser = await User.create({
      name,
      email,
      password: hashedPassword,
      securityQuestion: securityQuestion || "What is your childhood pet's name?", // Fallback default
      securityAnswer: hashedSecurityAnswer
    });

    // 5. Send success message back to Flutter
    res.status(201).json({
      message: 'User registered successfully!',
      user: {
        id: newUser.id,
        name: newUser.name,
        email: newUser.email
      }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// Logic for Login
exports.login = async (req, res) => {
  try {
    if (!jwtSecret || !jwtSecret.trim()) {
      return res.status(500).json({ message: 'JWT secret is not configured' });
    }

    const { email, password } = req.body;

    // 1. Check if user exists
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // 2. Check if password matches
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // 3. Generate a Token (The "VIP Badge")
    const token = jwt.sign({ id: user.id }, jwtSecret, { expiresIn: '1h' });

    res.json({
      message: 'Login successful',
      token, 
      user: { id: user.id, name: user.name, email: user.email }
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ============================================================
// NEW: FORGOT PASSWORD CONTROLLERS
// ============================================================

// --- 1. Fetch Security Question ---
exports.getSecurityQuestion = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ where: { email } });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json({ question: user.securityQuestion });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// --- 2. Reset the Password ---
exports.resetPassword = async (req, res) => {
  try {
    const { email, answer, newPassword } = req.body;
    
    // 1. Find the user
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const submittedAnswer = (answer || '').trim().toLowerCase();
    if (!submittedAnswer) {
      return res.status(400).json({ message: 'Answer is required' });
    }

    const storedAnswer = String(user.securityAnswer || '');
    const isHashedAnswer = storedAnswer.startsWith('$2a$') ||
      storedAnswer.startsWith('$2b$') ||
      storedAnswer.startsWith('$2y$');
    const isValidAnswer = isHashedAnswer
      ? await bcrypt.compare(submittedAnswer, storedAnswer)
      : storedAnswer === submittedAnswer;

    // 2. Check if the answer matches (supports old plaintext rows too)
    if (!isValidAnswer) {
      return res.status(400).json({ message: 'Incorrect security answer' });
    }

    // 3. Hash the new password and upgrade legacy plaintext answers.
    const hashedNewPassword = await bcrypt.hash(newPassword, 10);
    if (!isHashedAnswer) {
      user.securityAnswer = await bcrypt.hash(submittedAnswer, 10);
    }

    // 4. Update the user's password in the database
    user.password = hashedNewPassword;
    await user.save(); // Saves the updated row in PostgreSQL

    res.json({ message: 'Password reset successfully!' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};
