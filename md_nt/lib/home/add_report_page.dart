import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/config.dart';

class AddReportPage extends StatefulWidget {
  const AddReportPage({super.key});

  @override
  State<AddReportPage> createState() => _AddReportPageState();
}

class _AddReportPageState extends State<AddReportPage> {
  final TextEditingController docController = TextEditingController();
  final TextEditingController hospController = TextEditingController();
  final TextEditingController diseaseController = TextEditingController(); // NEW: Condition Controller
  
  File? _image;
  final picker = ImagePicker();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future getImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 50
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked; 
      });
    }
  }

  Future<void> uploadReport() async {
    if (_image == null || docController.text.isEmpty || hospController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields and take a photo")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('userId') ?? "1"; 

    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${AppConfig.baseUrl}/add-report')
      );
      
      request.fields['doctorName'] = docController.text;
      request.fields['hospitalName'] = hospController.text;
      request.fields['reportDate'] = _selectedDate.toLocal().toString().split(' ')[0];
      
      // NEW: Send the disease condition to the backend
      request.fields['disease'] = diseaseController.text.trim().isEmpty 
          ? 'General' 
          : diseaseController.text.trim();
          
      request.fields['userId'] = userId;

      request.files.add(await http.MultipartFile.fromPath(
        'reportImage', 
        _image!.path
      ));

      var response = await request.send();

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Report Digitized Successfully!")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload Failed. Check Server.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection Error")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Digitize Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: docController, 
              decoration: const InputDecoration(labelText: "Doctor Name", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            TextField(
              controller: hospController, 
              decoration: const InputDecoration(labelText: "Hospital Name", border: OutlineInputBorder())
            ),
            const SizedBox(height: 15),
            
            // --- NEW: Disease / Condition Text Field ---
            TextField(
              controller: diseaseController, 
              decoration: const InputDecoration(
                labelText: "Condition (e.g., Asthma, Diabetes)", 
                hintText: "Leave blank for 'General'",
                border: OutlineInputBorder()
              )
            ),
            const SizedBox(height: 15),
            // ------------------------------------------

            ListTile(
              title: Text(
                "Date: ${_selectedDate.toLocal().toString().split(' ')[0]}", 
                style: const TextStyle(fontSize: 16),
              ),
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              onTap: () => _selectDate(context),
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            
            const SizedBox(height: 20),
            
            _image == null 
              ? Container(
                  height: 200, 
                  width: double.infinity, 
                  color: Colors.grey[300], 
                  child: const Icon(Icons.camera_alt, size: 50)
                )
              : Image.file(_image!, height: 250),
            
            const SizedBox(height: 10),
            ElevatedButton(onPressed: getImage, child: const Text("Capture Image")),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : uploadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, 
                  padding: const EdgeInsets.all(15)
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save to Vault", style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}