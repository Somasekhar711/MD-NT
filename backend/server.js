const express = require('express');
const path = require('path');
const sequelize = require('./src/config/database'); 
const upload = require('./src/middleware/upload');
const Report = require('./src/models/report');
const User = require('./src/models/user'); 
const authRoutes = require('./src/routes/authRoutes');

const app = express();
app.use(express.json());

// Serve the uploads folder so Flutter can load images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// ----------------------------------------------------
// IMPORTANT: Database Sync
// { alter: true } forces Postgres to add the new 'disease' column.
// After you run 'npm start' successfully once, you can remove '{ alter: true }'.
// ----------------------------------------------------
sequelize.authenticate()
  .then(() => {
    console.log('✅ PostgreSQL Connected');
    return sequelize.sync({ alter: true }); 
  })
  .then(() => console.log('✅ Tables Synced'))
  .catch(err => console.error('❌ DB Error:', err));


// --- ROUTES ---

// Authentication
app.use('/api/auth', authRoutes);

// Get all reports for a specific user
app.get('/api/auth/reports/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
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

// Add report route (Now accepts 'disease')
app.post('/api/auth/add-report', upload.single('reportImage'), async (req, res) => {
  try {
    const { doctorName, hospitalName, reportDate, disease, userId } = req.body;
    
    if (!req.file) return res.status(400).json({ message: "Image is required" });

    const newReport = await Report.create({
      doctorName,
      hospitalName,
      reportDate,
      disease: disease || 'General', // Save the tag!
      imageUrl: req.file.path, 
      userId: parseInt(userId)
    });

    res.status(201).json({ message: 'Report Digitized!', report: newReport });
  } catch (error) {
    console.error("Upload Error:", error);
    res.status(500).json({ message: 'Server upload error' });
  }
});

// Start Server
const PORT = 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));