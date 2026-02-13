const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./user');

const Report = sequelize.define('Report', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
  },
  doctorName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  hospitalName: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  reportDate: {
    type: DataTypes.DATEONLY, // Stores only YYYY-MM-DD
    allowNull: false,
  },
  imageUrl: {
    type: DataTypes.STRING, // Stores the path: uploads/170...jpg
    allowNull: false,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  }
});

// Relationships
User.hasMany(Report, { foreignKey: 'userId' });
Report.belongsTo(User, { foreignKey: 'userId' });

module.exports = Report;