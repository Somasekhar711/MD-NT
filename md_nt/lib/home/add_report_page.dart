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

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

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
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We need the IP and Port to load the image from the server
    String serverUrl = "http://${AppConfig.ipAddress}:5000/";

    return Scaffold(
      appBar: AppBar(title: const Text("My Medical Vault")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reports found. Add one!"))
              : ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    // The path in DB is "uploads/filename.jpg"
                    // We combine it with the server URL
                    String fullImageUrl = serverUrl + report['imageUrl'].replaceAll('\\', '/');

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: Image.network(
                          fullImageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                        ),
                        title: Text(report['doctorName']),
                        subtitle: Text("${report['hospitalName']} \n${report['reportDate']}"),
                        isThreeLine: true,
                        onTap: () {
                          // TODO: Show full screen image
                        },
                      ),
                    );
                  },
                ),
    );
  }
}