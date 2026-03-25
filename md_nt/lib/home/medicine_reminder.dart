import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_alarm_clock/flutter_alarm_clock.dart'; // NEW NATIVE ALARM PACKAGE

class MedicineReminderPage extends StatefulWidget {
  const MedicineReminderPage({super.key});

  @override
  State<MedicineReminderPage> createState() => _MedicineReminderPageState();
}

class _MedicineReminderPageState extends State<MedicineReminderPage> {
  final Color primaryColor = const Color.fromARGB(255, 0, 132, 255);
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('medicine_reminders_v2');

    if (savedData != null) {
      try {
        setState(() {
          _reminders = List<Map<String, dynamic>>.from(jsonDecode(savedData));
        });
      } catch (e) {
        print("Error loading data: $e");
      }
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicine_reminders_v2', jsonEncode(_reminders));
  }

  void _addReminder(String name, List<TimeOfDay> times) {
    List<Map<String, dynamic>> formattedTimes = times.map((t) {
      int id =
          DateTime.now().millisecondsSinceEpoch.remainder(100000) +
          t.hour +
          t.minute;

      // 🔥 OPEN NATIVE CLOCK APP 🔥
      FlutterAlarmClock.createAlarm(
        hour: t.hour,
        minutes: t.minute,
        title: "Medicine: $name",
      );

      return {'hour': t.hour, 'minute': t.minute, 'id': id};
    }).toList();

    setState(() {
      _reminders.add({'name': name, 'times': formattedTimes});
    });
    _saveReminders();
  }

  void _snoozeTime(int medicineIndex, int timeIndex) {
    var timeData = _reminders[medicineIndex]['times'][timeIndex];
    int h = timeData['hour'];
    int m = timeData['minute'];

    m += 10;
    if (m >= 60) {
      h += 1;
      m -= 60;
    }
    if (h >= 24) h -= 24;

    int newId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    // 🔥 SNOOZE VIA NATIVE CLOCK APP 🔥
    FlutterAlarmClock.createAlarm(
      hour: h,
      minutes: m,
      title: "Snooze: ${_reminders[medicineIndex]['name']}",
    );

    setState(() {
      _reminders[medicineIndex]['times'][timeIndex] = {
        'hour': h,
        'minute': m,
        'id': newId,
      };
    });
    _saveReminders();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snoozed! (Sent to Clock App)')),
    );
  }

  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine deleted from tracker')),
    );
  }

  void _showAddDialog() {
    final TextEditingController nameController = TextEditingController();
    List<TimeOfDay> selectedTimes = [TimeOfDay.now()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Medicine'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medicine Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tap a time to edit it:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8.0,
                    children: List.generate(selectedTimes.length, (index) {
                      return InputChip(
                        label: Text(selectedTimes[index].format(context)),
                        avatar: const Icon(Icons.edit, size: 16),
                        onPressed: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTimes[index],
                          );
                          if (picked != null) {
                            setDialogState(() => selectedTimes[index] = picked);
                          }
                        },
                        deleteIcon: const Icon(Icons.cancel, size: 18),
                        onDeleted: selectedTimes.length > 1
                            ? () {
                                setDialogState(
                                  () => selectedTimes.removeAt(index),
                                );
                              }
                            : null,
                      );
                    }),
                  ),

                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null && !selectedTimes.contains(picked)) {
                        setDialogState(() => selectedTimes.add(picked));
                      }
                    },
                    icon: Icon(Icons.add_alarm, color: primaryColor),
                    label: Text(
                      "Add Another Time",
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      _addReminder(nameController.text.trim(), selectedTimes);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text(
                    'Save & Set Alarm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medicine Reminders',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _reminders.isEmpty
          ? const Center(
              child: Text(
                'No medicines scheduled.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];
                List<dynamic> timesList = reminder['times'];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: primaryColor.withOpacity(
                                    0.2,
                                  ),
                                  child: Icon(
                                    Icons.medical_services,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  reminder['name'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteReminder(index),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(),
                        ),

                        ...timesList.asMap().entries.map((entry) {
                          int timeIndex = entry.key;
                          var t = entry.value;
                          TimeOfDay displayTime = TimeOfDay(
                            hour: t['hour'],
                            minute: t['minute'],
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      displayTime.format(context),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _snoozeTime(index, timeIndex),
                                  icon: const Icon(
                                    Icons.snooze,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  label: const Text(
                                    'Snooze',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Colors.orange,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.alarm_add, color: Colors.white),
        label: const Text('Add Pill', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
