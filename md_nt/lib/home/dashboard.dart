import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/authentication/login_page.dart';
import 'package:md_nt/home/add_report_page.dart';
import 'package:md_nt/home/report_gallery_page.dart';
import 'package:md_nt/home/medicine_reminder.dart'; // <--- NEW IMPORT ADDED HERE

class DashboardPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final String userName;

  const DashboardPage({super.key, required this.toggleTheme, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  
  // This function shows the "Add" and "View" options as a Bottom Sheet
  void _showMedicalOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              const Text(
                "Medical Digitizer",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.add_a_photo, color: Colors.blue),
                title: const Text("Add New Report"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddReportPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_shared, color: Colors.green),
                title: const Text("View Saved Reports"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ReportGalleryPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              accountName: Text(widget.userName, style: const TextStyle(fontSize: 18)),
              accountEmail: const Text("User Settings"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Light / Dark Mode'),
              onTap: () {
                Navigator.pop(context);
                widget.toggleTheme();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage(toggleTheme: widget.toggleTheme)),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome back, ${widget.userName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your medical history efficiently.', 
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 16)
            ),
            const SizedBox(height: 40),
            
            // Medical Reports Action Button
            ElevatedButton.icon(
              onPressed: () => _showMedicalOptions(context), 
              icon: const Icon(Icons.medical_services, color: Colors.white),
              label: const Text('Medical Reports', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), 
                backgroundColor: Colors.blue
              ),
            ),
            
            const SizedBox(height: 20),
            
            // --- NEW: Medicine Reminders Button ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MedicineReminderPage()),
                );
              },
              icon: const Icon(Icons.alarm_add, color: Colors.white),
              label: const Text('Medicine Reminders', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), 
                backgroundColor: Colors.green, // Different color to stand out
              ),
            ),
          ],
        ),
      ),
    );
  }
}