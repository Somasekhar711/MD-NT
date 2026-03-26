const express = require('express');
const fs = require('fs');
const path = require('path');
const sequelize = require('./src/config/database');
const upload = require('./src/middleware/upload');
const Report = require('./src/models/report');
require('./src/models/user');
const authRoutes = require('./src/routes/authRoutes');

const app = express();
app.use(express.json());

// Serve the uploads folder so Flutter can load images
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

async function normalizeReportsUserIdColumn() {
  const queryInterface = sequelize.getQueryInterface();

  try {
    const tableDefinition = await queryInterface.describeTable('Reports');
    if (!tableDefinition.userId) {
      return;
    }

    const currentType = String(tableDefinition.userId.type).toUpperCase();
    if (currentType.includes('INTEGER')) {
      return;
    }

    await sequelize.query(`
      ALTER TABLE "Reports"
      ALTER COLUMN "userId" TYPE INTEGER
      USING ("userId"::integer);
    `);
  } catch (error) {
    // If the table doesn't exist yet, sync will create it.
    if (error.name !== 'SequelizeDatabaseError') {
      return;
    }
    throw error;
  }
}

// Initialize database schema before serving requests
sequelize
  .authenticate()
  .then(async () => {
    console.log('PostgreSQL Connected');
    await normalizeReportsUserIdColumn();
    await sequelize.sync({ alter: true });
    console.log('Tables synced');
  })
  .catch((err) => console.error('DB Error:', err));

// Authentication
app.use('/api/auth', authRoutes);

// Get all reports for a specific user
app.get('/api/auth/reports/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const reports = await Report.findAll({
      where: { userId },
      order: [['reportDate', 'DESC']],
    });
    res.json(reports);
  } catch (error) {
    console.error('Fetch Error:', error);
    res.status(500).json({ message: 'Error fetching reports' });
  }
});

// Add report route
app.post('/api/auth/add-report', upload.single('reportImage'), async (req, res) => {
  try {
    const { doctorName, hospitalName, reportDate, disease, userId } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: 'Image is required' });
    }

    const newReport = await Report.create({
      doctorName,
      hospitalName,
      reportDate,
      disease: disease || 'General',
      imageUrl: req.file.path,
      userId: parseInt(userId, 10),
    });

    res.status(201).json({ message: 'Report Digitized!', report: newReport });
  } catch (error) {
    console.error('Upload Error:', error);
    res.status(500).json({ message: 'Server upload error' });
  }
});

// Update report details
app.put('/api/auth/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { doctorName, hospitalName, reportDate, disease } = req.body;

    const report = await Report.findByPk(id);
    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }

    report.doctorName = doctorName ?? report.doctorName;
    report.hospitalName = hospitalName ?? report.hospitalName;
    report.reportDate = reportDate ?? report.reportDate;
    report.disease = disease && disease.trim() ? disease.trim() : 'General';

    await report.save();
    res.json({ message: 'Report updated successfully', report });
  } catch (error) {
    console.error('Update Error:', error);
    res.status(500).json({ message: 'Server update error' });
  }
});

// Delete report
app.delete('/api/auth/reports/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const report = await Report.findByPk(id);

    if (!report) {
      return res.status(404).json({ message: 'Report not found' });
    }

    const normalizedImagePath = String(report.imageUrl || '').replaceAll('\\', '/');
    const relativeImagePath = normalizedImagePath.startsWith('/uploads/')
        ? normalizedImagePath.replaceFirst('/uploads/', 'uploads/')
        : normalizedImagePath;
    const filePath = path.join(__dirname, relativeImagePath);

    if (relativeImagePath && fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }

    await report.destroy();
    res.json({ message: 'Report deleted successfully' });
  } catch (error) {
    console.error('Delete Error:', error);
    res.status(500).json({ message: 'Server delete error' });
  }
});

// Start Server
const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
