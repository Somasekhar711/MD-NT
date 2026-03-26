const Report = require('../models/report');
const fs = require('fs');
const path = require('path');

exports.uploadReport = async (req, res) => {
  try {
    const { doctorName, hospitalName, reportDate, disease, userId } = req.body;
    const imageUrl = `/uploads/${req.file.filename}`;

    const report = await Report.create({
      doctorName, hospitalName, reportDate, 
      disease: disease || 'General', 
      userId, imageUrl
    });
    res.status(201).json(report);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getUserReports = async (req, res) => {
  try {
    const reports = await Report.findAll({ 
      where: { userId: req.params.userId },
      order: [['reportDate', 'DESC']] 
    });
    res.json(reports);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteReport = async (req, res) => {
  try {
    const report = await Report.findByPk(req.params.id);
    if (!report) return res.status(404).json({ message: "Not found" });

    // Delete file from disk
    const filePath = path.join(__dirname, '..', '..', 'src', report.imageUrl);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);

    await report.destroy();
    res.json({ message: "Deleted" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};