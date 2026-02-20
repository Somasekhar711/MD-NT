import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/config.dart';

class ReportGalleryPage extends StatefulWidget {
  const ReportGalleryPage({super.key});

  @override
  State<ReportGalleryPage> createState() => _ReportGalleryPageState();
}

class _ReportGalleryPageState extends State<ReportGalleryPage> {
  List reports = [];
  bool _isLoading = true;
  String _currentSort = 'Recent'; 
  String _selectedDisease = 'All'; // Tracks the active "Smart Folder"

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  // --- 1. Fetch Data from Node.js ---
  Future<void> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('userId') ?? "1";

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/reports/$userId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          reports = jsonDecode(response.body);
          _sortReports('Recent'); // Default sort when data loads
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching reports: $e");
      setState(() => _isLoading = false);
    }
  }

  // --- 2. Sorting Logic ---
  void _sortReports(String sortType) {
    setState(() {
      _currentSort = sortType;
      
      if (sortType == 'Recent') {
        reports.sort((a, b) => b['reportDate'].compareTo(a['reportDate']));
      } 
      else if (sortType == 'Oldest') {
        reports.sort((a, b) => a['reportDate'].compareTo(b['reportDate']));
      } 
      else if (sortType == 'Doctor') {
        reports.sort((a, b) => a['doctorName'].toString().toLowerCase().compareTo(b['doctorName'].toString().toLowerCase()));
      } 
      else if (sortType == 'Hospital') {
        reports.sort((a, b) => a['hospitalName'].toString().toLowerCase().compareTo(b['hospitalName'].toString().toLowerCase()));
      }
    });
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
        backgroundColor: Colors.blue,
        actions: [
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
                            selectedColor: Colors.blue,
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
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(5)
                                        ),
                                        child: Text(
                                          "Tag: $conditionTag", 
                                          style: TextStyle(color: Colors.blue.shade700, fontSize: 12)
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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