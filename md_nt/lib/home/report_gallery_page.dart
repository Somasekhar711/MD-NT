import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/config.dart';
import 'package:md_nt/theme/app_colors.dart';

class ReportGalleryPage extends StatefulWidget {
  const ReportGalleryPage({super.key});

  @override
  State<ReportGalleryPage> createState() => _ReportGalleryPageState();
}

class _ReportGalleryPageState extends State<ReportGalleryPage> {
  List reports = [];
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;
  String _currentSort = 'Recent'; 
  String _selectedDisease = 'All'; // Tracks the active "Smart Folder"

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  // --- 1. Fetch Data from Node.js ---
  Future<void> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    final String? token = await _getToken();

    if (userId == null || userId.isEmpty || token == null) {
      setState(() {
        _errorMessage = 'Session data missing. Please login again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reports/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
          _errorMessage = null;
          _currentSort = 'Recent';
          _applySort('Recent');
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load reports.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(Map<String, dynamic> report) async {
    setState(() => _isMutating = true);
    final String? token = await _getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        setState(() => _isMutating = false);
      }
      return;
    }

    try {
      final response = await http
          .delete(
            Uri.parse('${AppConfig.baseUrl}/reports/${report['id']}'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 12));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          reports.removeWhere((item) => item['id'] == report['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete report')),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete timed out. Please try again.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete report')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> report) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: Text(
          'Delete the report for Dr. ${report['doctorName']} from ${report['reportDate']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteReport(report);
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> report) async {
    final doctorController = TextEditingController(text: report['doctorName'] ?? '');
    final hospitalController = TextEditingController(text: report['hospitalName'] ?? '');
    final diseaseController = TextEditingController(text: report['disease'] ?? 'General');
    DateTime selectedDate =
        DateTime.tryParse(report['reportDate'] ?? '') ?? DateTime.now();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: doctorController,
                  decoration: const InputDecoration(
                    labelText: 'Doctor Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hospitalController,
                  decoration: const InputDecoration(
                    labelText: 'Hospital Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diseaseController,
                  decoration: const InputDecoration(
                    labelText: 'Condition/Disease',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text('Date: ${selectedDate.toIso8601String().split('T')[0]}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (doctorController.text.trim().isEmpty ||
                    hospitalController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Doctor and hospital are required')),
                  );
                  return;
                }

                final updated = await _updateReport(
                  report['id'],
                  doctorName: doctorController.text.trim(),
                  hospitalName: hospitalController.text.trim(),
                  disease: diseaseController.text.trim(),
                  reportDate: selectedDate.toIso8601String().split('T')[0],
                );

                if (context.mounted && updated) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    doctorController.dispose();
    hospitalController.dispose();
    diseaseController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated successfully')),
      );
    }
  }

  Future<void> _showExportMenu() async {
    final String? exportType = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Export Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.primary),
              title: const Text('Export by Doctor'),
              onTap: () => Navigator.pop(context, 'doctor'),
            ),
            ListTile(
              leading: const Icon(Icons.local_hospital_outlined, color: AppColors.success),
              title: const Text('Export by Disease'),
              onTap: () => Navigator.pop(context, 'disease'),
            ),
            ListTile(
              leading: const Icon(Icons.business_outlined, color: AppColors.warning),
              title: const Text('Export by Hospital'),
              onTap: () => Navigator.pop(context, 'hospital'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (exportType == null) {
      return;
    }

    final Map<String, dynamic>? selectedOption =
        await _showExportValueChooser(exportType);

    if (selectedOption == null) {
      return;
    }

    await _exportMatchingReports(
      List<Map<String, dynamic>>.from(selectedOption['reports']),
      exportType,
      selectedOption['label'].toString(),
    );
  }

  Future<Map<String, dynamic>?> _showExportValueChooser(String exportType) async {
    final Map<String, List<Map<String, dynamic>>> groupedReports = {};

    for (final rawReport in reports) {
      final report = Map<String, dynamic>.from(rawReport);
      String key;

      if (exportType == 'doctor') {
        key = report['doctorName']?.toString() ?? 'Unknown Doctor';
      } else if (exportType == 'disease') {
        key = report['disease']?.toString() ?? 'General';
      } else {
        key = report['hospitalName']?.toString() ?? 'Unknown Hospital';
      }

      groupedReports.putIfAbsent(key, () => []).add(report);
    }

    final options = groupedReports.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 12),
            ListTile(
              title: Text(
                'Choose ${exportType[0].toUpperCase()}${exportType.substring(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...options.map(
              (entry) => ListTile(
                title: Text(entry.key),
                subtitle: Text('${entry.value.length} report(s)'),
                onTap: () => Navigator.pop(
                  context,
                  {'label': entry.key, 'reports': entry.value},
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _exportMatchingReports(
    List<Map<String, dynamic>> matchingReports,
    String exportType,
    String label,
  ) async {
    if (matchingReports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reports available to export')),
      );
      return;
    }

    setState(() => _isMutating = true);

    try {
      final directory = await getTemporaryDirectory();
      final safeLabel = _sanitizeFileName(label);
      final file = File(
        '${directory.path}/reports_${exportType}_$safeLabel.pdf',
      );
      final serverUrl = 'http://${AppConfig.ipAddress}:5000/';
      final pdf = pw.Document();
      final generatedAt = DateTime.now();

      final sortedReports = [...matchingReports]
        ..sort(
          (a, b) => (b['reportDate'] ?? '')
              .toString()
              .compareTo((a['reportDate'] ?? '').toString()),
        );

      for (var i = 0; i < sortedReports.length; i++) {
        final report = sortedReports[i];
        final imagePath = (report['imageUrl'] ?? '').toString().replaceAll('\\', '/');
        final imageUrl = '$serverUrl$imagePath';
        final imageBytes = await _fetchImageBytes(imageUrl);
        final imageWidget = imageBytes == null
            ? pw.Container(
                height: 420,
                alignment: pw.Alignment.center,
                color: PdfColors.grey300,
                child: pw.Text('Image not available'),
              )
            : pw.Image(
                pw.MemoryImage(imageBytes),
                height: 420,
                fit: pw.BoxFit.contain,
              );

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(color: PdfColors.blue300, width: 0.7),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MediTrack - Medical Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Filter: ${exportType[0].toUpperCase()}${exportType.substring(1)} = $label',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'Report ${i + 1} of ${sortedReports.length}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.Text(
                        'Generated: ${generatedAt.toLocal().toString().split('.')[0]}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue600, width: 0.8),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Entry ${i + 1}',
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.Text(
                            _formatReportDate(report['reportDate']),
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Doctor: ${report['doctorName'] ?? '-'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Hospital: ${report['hospitalName'] ?? '-'}'),
                      pw.Text('Condition: ${report['disease'] ?? 'General'}'),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: imageWidget,
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Page ${i + 1} of ${sortedReports.length}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Medical reports export',
        text: 'Exported reports for $exportType: $label',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export ready for $label')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export reports')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  String _sanitizeFileName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _formatReportDate(dynamic rawDate) {
    final text = (rawDate ?? '').toString();
    if (text.isEmpty) return '-';
    try {
      return DateTime.parse(text).toIso8601String().split('T')[0];
    } catch (_) {
      return text;
    }
  }

  Future<Uint8List?> _fetchImageBytes(String imageUrl) async {
    try {
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return null;
      }

      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _updateReport(
    dynamic reportId, {
    required String doctorName,
    required String hospitalName,
    required String disease,
    required String reportDate,
  }) async {
    setState(() => _isMutating = true);
    final String? token = await _getToken();

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        setState(() => _isMutating = false);
      }
      return false;
    }

    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.baseUrl}/reports/$reportId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'doctorName': doctorName,
              'hospitalName': hospitalName,
              'disease': disease.isEmpty ? 'General' : disease,
              'reportDate': reportDate,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final updatedReport = body['report'];
        setState(() {
          final index = reports.indexWhere((item) => item['id'] == reportId);
          if (index != -1) {
            reports[index] = updatedReport;
          }
          _applySort(_currentSort);
        });
        return true;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update report')),
        );
      }
      return false;
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update timed out. Please try again.')),
        );
      }
      return false;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update report')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  // --- 2. Sorting Logic ---
  void _sortReports(String sortType) {
    setState(() {
      _currentSort = sortType;
      _applySort(sortType);
    });
  }

  void _applySort(String sortType) {
    if (sortType == 'Recent') {
      reports.sort((a, b) => b['reportDate'].compareTo(a['reportDate']));
    } else if (sortType == 'Oldest') {
      reports.sort((a, b) => a['reportDate'].compareTo(b['reportDate']));
    } else if (sortType == 'Doctor') {
      reports.sort(
        (a, b) => a['doctorName']
            .toString()
            .toLowerCase()
            .compareTo(b['doctorName'].toString().toLowerCase()),
      );
    } else if (sortType == 'Hospital') {
      reports.sort(
        (a, b) => a['hospitalName']
            .toString()
            .toLowerCase()
            .compareTo(b['hospitalName'].toString().toLowerCase()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String serverUrl = "http://${AppConfig.ipAddress}:5000/";

    // --- 3. Smart Folder Logic (Extract unique diseases) ---
    Set<String> uniqueDiseases = {'All'};
    for (var report in reports) {
      // If 'disease' doesn't exist in the DB yet, it defaults to 'General'
      uniqueDiseases.add(report['disease'] ?? 'General'); 
    }

    // --- 4. Filter logic based on selected chip ---
    List filteredReports = _selectedDisease == 'All' 
        ? reports 
        : reports.where((r) => (r['disease'] ?? 'General') == _selectedDisease).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medical Vault"),
        backgroundColor: AppColors.primary,
        actions: [
          if (_isMutating)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
            tooltip: 'Export Reports',
            onPressed: reports.isEmpty || _isMutating ? null : _showExportMenu,
          ),
          // Sort Dropdown Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Sort Reports',
            onSelected: (String result) {
              _sortReports(result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'Recent', child: Text('Sort by: Recent')),
              const PopupMenuItem<String>(value: 'Oldest', child: Text('Sort by: Oldest')),
              const PopupMenuItem<String>(value: 'Doctor', child: Text('Sort by: Doctor')),
              const PopupMenuItem<String>(value: 'Hospital', child: Text('Sort by: Hospital')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
          : Column(
              children: [
                // --- TOP ROW: Disease/Condition Filter Chips ---
                if (reports.isNotEmpty)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: uniqueDiseases.map((disease) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              disease, 
                              style: TextStyle(
                                color: _selectedDisease == disease ? Colors.white : Colors.black87,
                                fontWeight: _selectedDisease == disease ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                            selected: _selectedDisease == disease,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedDisease = disease;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // --- BOTTOM SECTION: The Filtered List of Cards ---
                Expanded(
                  child: filteredReports.isEmpty
                      ? const Center(child: Text("No reports found."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            String fullImageUrl = serverUrl + report['imageUrl'].replaceAll('\\', '/');
                            String conditionTag = report['disease'] ?? 'General';

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(10),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    fullImageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => 
                                        const Icon(Icons.broken_image, size: 40),
                                  ),
                                ),
                                title: Text(
                                  "Doctor: ${report['doctorName']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Hospital: ${report['hospitalName']}"),
                                      Text("Date: ${report['reportDate']}"),
                                      const SizedBox(height: 4),
                                      // Display the tag on the card
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(5)
                                        ),
                                        child: Text(
                                          "Tag: $conditionTag", 
                                          style: TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 12,
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditDialog(report);
                                    } else if (value == 'delete') {
                                      _showDeleteConfirmation(report);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  _showFullScreenImage(context, fullImageUrl, report);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // --- 5. Full Screen Interactive Viewer ---
  void _showFullScreenImage(BuildContext context, String url, dynamic data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Dr. ${data['doctorName']} - Report"),
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }
}
