const bcrypt = require('bcryptjs');
const User = require('../models/user'); // Import your User model

// Logic for Registering a new user
exports.register = async (req, res) => {
  try {
    // 1. Get data from the frontend (Flutter)
    const { name, email, password } = req.body;

    // 2. Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // 3. Hash the password (security!)
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // 4. Create the new user in the database
    const newUser = await User.create({
      name,
      email,
      password: hashedPassword
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

const jwt = require('jsonwebtoken'); // <--- Import this at the top!
// ... (your existing register code) ...

// --- Add this NEW function ---
exports.login = async (req, res) => {
  try {
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
    // This token proves who they are. They will send it with future requests.
    const token = jwt.sign({ id: user.id }, 'YOUR_SECRET_KEY', { expiresIn: '1h' });

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