const { Sequelize } = require('sequelize');

// Update 'YOUR_PASSWORD' again here!
const sequelize = new Sequelize('flutter_backend', 'postgres', 'somasekhar', {
  host: 'localhost',
  dialect: 'postgres',
  logging: false, 
});

module.exports = sequelize;