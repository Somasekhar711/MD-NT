import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:md_nt/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final String? savedData = prefs.getString('medicine_reminders_v3');

    if (savedData == null) {
      return;
    }

    try {
      final decoded = List<Map<String, dynamic>>.from(jsonDecode(savedData));
      if (!mounted) {
        return;
      }
      setState(() {
        _reminders = decoded;
      });
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicine_reminders_v3', jsonEncode(_reminders));
  }

  int _generateReminderId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(1000000);
  }

  int _notificationIdFor(int reminderId, int index) {
    return reminderId * 100 + index;
  }

  Future<void> _scheduleDailyNotifications(
    String medicineName,
    List<Map<String, dynamic>> times,
  ) async {
    for (final time in times) {
      final displayTime = TimeOfDay(
        hour: time['hour'] as int,
        minute: time['minute'] as int,
      ).format(context);

      await NotificationService.instance.scheduleDailyReminder(
        id: time['notificationId'] as int,
        medicineName: medicineName,
        title: medicineName,
        body: 'Time to take $medicineName at $displayTime',
        hour: time['hour'] as int,
        minute: time['minute'] as int,
      );
    }
  }

  Future<bool> _addReminder(String name, List<TimeOfDay> times) async {
    try {
      final reminderId = _generateReminderId();
      final sortedTimes = [...times]
        ..sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      final formattedTimes = List<Map<String, dynamic>>.generate(
        sortedTimes.length,
        (index) => {
          'hour': sortedTimes[index].hour,
          'minute': sortedTimes[index].minute,
          'notificationId': _notificationIdFor(reminderId, index),
        },
      );

      await _scheduleDailyNotifications(name, formattedTimes);

      if (!mounted) {
        return false;
      }

      setState(() {
        _reminders.add({
          'reminderId': reminderId,
          'name': name,
          'times': formattedTimes,
        });
      });
      await _saveReminders();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Add reminder error: $e');
      debugPrint('$stackTrace');
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save reminder: $e')),
      );
      return false;
    }
  }

  Future<bool> _updateReminder(
    int index,
    String name,
    List<TimeOfDay> times,
  ) async {
    try {
      final existing = _reminders[index];
      final reminderId = existing['reminderId'] as int? ?? _generateReminderId();
      final oldNotificationIds = List<int>.from(
        (existing['times'] as List).map((time) => time['notificationId'] as int),
      );

      await NotificationService.instance.cancelMany(oldNotificationIds);

      final sortedTimes = [...times]
        ..sort((a, b) =>
            (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

      final formattedTimes = List<Map<String, dynamic>>.generate(
        sortedTimes.length,
        (timeIndex) => {
          'hour': sortedTimes[timeIndex].hour,
          'minute': sortedTimes[timeIndex].minute,
          'notificationId': _notificationIdFor(reminderId, timeIndex),
        },
      );

      await _scheduleDailyNotifications(name, formattedTimes);

      if (!mounted) {
        return false;
      }

      setState(() {
        _reminders[index] = {
          'reminderId': reminderId,
          'name': name,
          'times': formattedTimes,
        };
      });
      await _saveReminders();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Update reminder error: $e');
      debugPrint('$stackTrace');
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reminder: $e')),
      );
      return false;
    }
  }

  Future<void> _snoozeTime(int medicineIndex, int timeIndex) async {
    try {
      final reminder = _reminders[medicineIndex];
      final medicineName = reminder['name'].toString();
      final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(2000000000);

      await NotificationService.instance.scheduleOneTimeReminder(
        id: notificationId,
        medicineName: medicineName,
        title: medicineName,
        body: 'Snoozed reminder for $medicineName',
        scheduledFor: snoozeTime,
      );

      if (!mounted) {
        return;
      }

      final displayTime = TimeOfDay.fromDateTime(snoozeTime).format(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snoozed to $displayTime')),
      );
    } catch (e, stackTrace) {
      debugPrint('Snooze reminder error: $e');
      debugPrint('$stackTrace');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not snooze reminder: $e')),
      );
    }
  }

  Future<void> _deleteReminder(int index) async {
    final reminder = _reminders[index];
    final notificationIds = List<int>.from(
      (reminder['times'] as List).map((time) => time['notificationId'] as int),
    );

    await NotificationService.instance.cancelMany(notificationIds);

    if (!mounted) {
      return;
    }

    setState(() {
      _reminders.removeAt(index);
    });
    await _saveReminders();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine reminder deleted')),
    );
  }

  Future<void> _showDeleteConfirmation(int index) async {
    final reminder = _reminders[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete reminder for ${reminder['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteReminder(index);
    }
  }

  Future<void> _showReminderDialog({int? index}) async {
    final existingReminder = index != null ? _reminders[index] : null;
    final nameController = TextEditingController(
      text: existingReminder?['name']?.toString() ?? '',
    );
    List<TimeOfDay> selectedTimes = existingReminder == null
        ? [TimeOfDay.now()]
        : List<TimeOfDay>.from(
            (existingReminder['times'] as List).map(
              (time) => TimeOfDay(
                hour: time['hour'] as int,
                minute: time['minute'] as int,
              ),
            ),
          );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(index == null ? 'Add Medicine' : 'Edit Medicine'),
          content: SingleChildScrollView(
            child: Column(
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
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(selectedTimes.length, (timeIndex) {
                    return InputChip(
                      label: Text(selectedTimes[timeIndex].format(dialogContext)),
                      avatar: const Icon(Icons.edit, size: 16),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedTimes[timeIndex],
                        );
                        if (picked != null) {
                          setDialogState(() => selectedTimes[timeIndex] = picked);
                        }
                      },
                      deleteIcon: const Icon(Icons.cancel, size: 18),
                      onDeleted: selectedTimes.length > 1
                          ? () => setDialogState(
                                () => selectedTimes.removeAt(timeIndex),
                              )
                          : null,
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null &&
                        !selectedTimes.any(
                          (time) =>
                              time.hour == picked.hour &&
                              time.minute == picked.minute,
                        )) {
                      setDialogState(() => selectedTimes.add(picked));
                    }
                  },
                  icon: Icon(Icons.add_alarm, color: primaryColor),
                  label: Text(
                    'Add Another Time',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Medicine name is required')),
                  );
                  return;
                }

                Navigator.pop(dialogContext, {
                  'name': name,
                  'times': List<TimeOfDay>.from(selectedTimes),
                });
              },
              child: Text(
                index == null ? 'Save Reminder' : 'Update Reminder',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    final name = result['name'] as String;
    final times = List<TimeOfDay>.from(result['times'] as List);
    final success = index == null
        ? await _addReminder(name, times)
        : await _updateReminder(index, name, times);

    if (!success || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == null
              ? 'Medicine reminder saved'
              : 'Medicine reminder updated',
        ),
      ),
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
                final timesList = reminder['times'] as List<dynamic>;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.2),
                              child: Icon(
                                Icons.medical_services,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                reminder['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showReminderDialog(index: index);
                                } else if (value == 'delete') {
                                  _showDeleteConfirmation(index);
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
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(),
                        ),
                        ...timesList.asMap().entries.map((entry) {
                          final timeIndex = entry.key;
                          final time = entry.value as Map<String, dynamic>;
                          final displayTime = TimeOfDay(
                            hour: time['hour'] as int,
                            minute: time['minute'] as int,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
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
                                  onPressed: () => _snoozeTime(index, timeIndex),
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
                                    side: const BorderSide(color: Colors.orange),
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
        onPressed: () => _showReminderDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.alarm_add, color: Colors.white),
        label: const Text(
          'Add Pill',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
