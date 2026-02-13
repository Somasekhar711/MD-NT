const express = require('express');
const sequelize = require('./config/database'); // Import the connection
const User = require('./models/user'); // Import your model (we created this earlier)

const app = express();

// Test the DB connection
sequelize.authenticate()
  .then(() => console.log('Database connected...'))
  .catch(err => console.log('Error: ' + err));

// Sync models (This creates the table in the DB if it doesn't exist)
sequelize.sync()
  .then(() => console.log('Tables created!'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, console.log(`Server started on port ${PORT}`));