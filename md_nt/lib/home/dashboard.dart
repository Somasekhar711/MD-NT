import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:md_nt/authentication/login_page.dart';
import 'package:md_nt/home/add_report_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final String userName; // Accept the name from Login

  const DashboardPage({super.key, required this.toggleTheme, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
                await prefs.clear(); // This deletes the saved token and name
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
            const Text('Welcome to MediNutrition!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportGalleryPage()), // Go to Gallery
    );
  },
              icon: const Icon(Icons.medical_services, color: Colors.white),
              label: const Text('Medical Reports', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.food_bank, color: Colors.white),
              label: const Text('Nutrition Tracker', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}