const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

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
    type: DataTypes.DATEONLY,
    allowNull: false,
  },
  disease: {
    type: DataTypes.STRING,
    defaultValue: 'General', // If left blank, it becomes 'General'
  },
  imageUrl: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  }
});

module.exports = Report;