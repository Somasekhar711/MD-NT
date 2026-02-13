const express = require('express');
const path = require('path');
const sequelize = require('./src/config/database'); // Ensure this path is correct
const upload = require('./src/middleware/upload');
const Report = require('./src/models/report');
const User = require('./src/models/user'); // Required for relationships
const authRoutes = require('./src/routes/authRoutes');

const app = express();

// 1. Middleware
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 2. Database Connection & Sync
sequelize.authenticate()
  .then(() => {
    console.log('PostgreSQL Connected');
    return sequelize.sync(); // This ensures the 'Reports' table actually exists
  })
  .then(() => console.log('Tables Synced'))
  .catch(err => console.error('DB Error:', err));

// 3. Routes (All routes MUST be above app.listen)

// Authentication routes
app.use('/api/auth', authRoutes);

// Get all reports for a specific user
app.get('/api/auth/reports/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    console.log(`Fetching reports for user: ${userId}`); // Debug log
    const reports = await Report.findAll({
      where: { userId: userId },
      order: [['reportDate', 'DESC']]
    });
    res.json(reports);
  } catch (error) {
    console.error("Fetch Error:", error);
    res.status(500).json({ message: "Error fetching reports" });
  }
});

// Add report route
app.post('/api/auth/add-report', upload.single('reportImage'), async (req, res) => {
  try {
    const { doctorName, hospitalName, reportDate, userId } = req.body;
    if (!req.file) return res.status(400).json({ message: "Image is required" });

    const newReport = await Report.create({
      doctorName,
      hospitalName,
      reportDate,
      imageUrl: req.file.path, 
      userId: parseInt(userId)
    });

    res.status(201).json({ message: 'Report Digitized!', report: newReport });
  } catch (error) {
    console.error("Upload Error:", error);
    res.status(500).json({ message: 'Server upload error' });
  }
});

// 4. Start Server (Always at the very bottom)
const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));