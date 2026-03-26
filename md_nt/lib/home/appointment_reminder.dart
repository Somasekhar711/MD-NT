import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart'; // Handles the link to Calendar
import 'package:intl/intl.dart';

class AppointmentReminderPage extends StatefulWidget {
  const AppointmentReminderPage({super.key});

  @override
  State<AppointmentReminderPage> createState() =>
      _AppointmentReminderPageState();
}

class _AppointmentReminderPageState extends State<AppointmentReminderPage> {
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('appointments_v1');
    if (data != null) {
      setState(() {
        _appointments = List<Map<String, dynamic>>.from(jsonDecode(data));
        _appointments.sort((a, b) => a['date'].compareTo(b['date']));
      });
    }
  }

  Future<void> _saveAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appointments_v1', jsonEncode(_appointments));
  }

  void _addAppointment() async {
    final nameCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text("New Appointment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Doctor/Clinic Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text(
                  "Date: ${DateFormat('yMMMd').format(selectedDate)}",
                ),
                trailing: const Icon(
                  Icons.calendar_today,
                  color: Colors.orange,
                ),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setDialogState(() => selectedDate = d);
                },
              ),
              ListTile(
                title: Text("Time: ${selectedTime.format(context)}"),
                trailing: const Icon(Icons.access_time, color: Colors.orange),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (t != null) setDialogState(() => selectedTime = t);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  // --- CALENDAR INTEGRATION LOGIC ---
                  final DateTime startDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  // This opens the System Calendar "Add Event" screen with pre-filled info
                  final AndroidIntent intent = AndroidIntent(
                    action: 'android.intent.action.INSERT',
                    data: 'content://com.android.calendar/events',
                    arguments: <String, dynamic>{
                      'title': 'Doctor Appointment: ${nameCtrl.text}',
                      'beginTime': startDateTime.millisecondsSinceEpoch,
                      'endTime': startDateTime
                          .add(const Duration(hours: 1))
                          .millisecondsSinceEpoch,
                      'description':
                          'Appointment scheduled via My Health Tracker app.',
                    },
                  );
                  intent.launch();

                  setState(() {
                    _appointments.add({
                      'name': nameCtrl.text,
                      'date': selectedDate.toIso8601String(),
                      'time': selectedTime.format(context),
                    });
                  });
                  _saveAppointments();
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "Add to Calendar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Doctor Appointments",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _appointments.isEmpty
          ? const Center(child: Text("No appointments scheduled"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final apt = _appointments[index];
                final dt = DateTime.parse(apt['date']);
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      apt['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${DateFormat('EEEE, MMM d').format(dt)} at ${apt['time']}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _appointments.removeAt(index));
                        _saveAppointments();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _addAppointment,
        child: const Icon(Icons.add_task, color: Colors.white),
      ),
    );
  }
}
