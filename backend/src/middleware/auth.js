const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';

  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authorization token missing' });
  }

  const token = header.slice(7).trim();
  if (!token) {
    return res.status(401).json({ message: 'Authorization token missing' });
  }

  const secret = process.env.JWT_SECRET;
  if (!secret || !secret.trim()) {
    return res.status(500).json({ message: 'JWT secret is not configured' });
  }

  try {
    const decoded = jwt.verify(token, secret);
    req.user = { id: Number(decoded.id) };
    return next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
}

module.exports = authMiddleware;
