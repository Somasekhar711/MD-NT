import 'dart:convert';
<<<<<<< HEAD
import 'package:android_intent_plus/android_intent.dart';
import 'package:intl/intl.dart';
=======

import 'package:flutter/material.dart';
import 'package:md_nt/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)

class MedicineReminderPage extends StatefulWidget {
  const MedicineReminderPage({super.key});

  @override
  State<MedicineReminderPage> createState() => _MedicineReminderPageState();
}

class _MedicineReminderPageState extends State<MedicineReminderPage> {
  final Color medicalBlue = const Color.fromARGB(255, 0, 132, 255);
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // --- DATA LOGIC ---
  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('medicine_reminders_v3');
<<<<<<< HEAD
    if (savedData != null) {
      setState(
        () =>
            _reminders = List<Map<String, dynamic>>.from(jsonDecode(savedData)),
      );
=======

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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicine_reminders_v3', jsonEncode(_reminders));
  }

<<<<<<< HEAD
  void _toggleTaken(int index) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      if (_reminders[index]['lastTakenDate'] == today) {
        _reminders[index]['lastTakenDate'] = "";
        _reminders[index]['stockCount']++;
      } else {
        _reminders[index]['lastTakenDate'] = today;
        if (_reminders[index]['stockCount'] > 0)
          _reminders[index]['stockCount']--;
      }
    });
    _saveReminders();
  }

  // 🔥 NEW: DELETE CONFIRMATION POPUP 🔥
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text(
          'This removes the medicine from your list. \n\n'
          '⚠️ IMPORTANT: You must manually delete the repeating alarm from your phone\'s Clock app.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _reminders.removeAt(index));
              _saveReminders();
              Navigator.pop(context);
              // Open clock immediately after delete to help the user
              const AndroidIntent(
                action: 'android.intent.action.SHOW_ALARMS',
              ).launch();
            },
            child: const Text(
              'Delete & Open Clock',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI DIALOG (Add/Edit) ---
  void _showMedDialog({int? index}) {
    final bool isEditing = index != null;
    final nameController = TextEditingController(
      text: isEditing ? _reminders[index]['name'] : "",
    );
    final stockController = TextEditingController(
      text: isEditing ? _reminders[index]['stockCount'].toString() : "30",
    );
    String selectedType = isEditing ? _reminders[index]['type'] : 'Pill';
    String selectedInstruction = isEditing
        ? _reminders[index]['instruction']
        : 'Before Food';
    List<TimeOfDay> selectedTimes = isEditing
        ? (_reminders[index]['times'] as List)
              .map((t) => TimeOfDay(hour: t['hour'], minute: t['minute']))
              .toList()
        : [TimeOfDay.now()];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEditing ? 'Edit Medicine' : 'Add Medicine',
            style: TextStyle(color: medicalBlue),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
=======
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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
<<<<<<< HEAD
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        items: ['Pill', 'Syrup', 'Injection']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setDialogState(() => selectedType = val!),
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Qty',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedInstruction,
                  items: ['Before Food', 'After Food', 'Empty Stomach']
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedInstruction = val!),
                  decoration: const InputDecoration(
                    labelText: 'Instruction',
                    border: OutlineInputBorder(),
=======
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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  children: selectedTimes
                      .asMap()
                      .entries
                      .map(
                        (e) => InputChip(
                          label: Text(e.value.format(context)),
                          onPressed: () async {
                            final p = await showTimePicker(
                              context: context,
                              initialTime: e.value,
                            );
                            if (p != null)
                              setDialogState(() => selectedTimes[e.key] = p);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
<<<<<<< HEAD
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: medicalBlue),
              onPressed: () {
                final name = nameController.text.trim();
                final stock = int.tryParse(stockController.text) ?? 0;
                if (name.isNotEmpty) {
                  for (var t in selectedTimes) {
                    AndroidIntent(
                      action: 'android.intent.action.SET_ALARM',
                      arguments: <String, dynamic>{
                        'android.intent.extra.alarm.HOUR': t.hour,
                        'android.intent.extra.alarm.MINUTES': t.minute,
                        'android.intent.extra.alarm.MESSAGE':
                            "[$selectedInstruction] $name",
                        'android.intent.extra.alarm.DAYS': [
                          1,
                          2,
                          3,
                          4,
                          5,
                          6,
                          7,
                        ],
                        'android.intent.extra.alarm.SKIP_UI': true,
                      },
                    ).launch();
                  }
                  setState(() {
                    final data = {
                      'name': name,
                      'type': selectedType,
                      'instruction': selectedInstruction,
                      'stockCount': stock,
                      'lastTakenDate': isEditing
                          ? _reminders[index]['lastTakenDate']
                          : "",
                      'times': selectedTimes
                          .map((t) => {'hour': t.hour, 'minute': t.minute})
                          .toList(),
                    };
                    isEditing ? _reminders[index] = data : _reminders.add(data);
                  });
                  _saveReminders();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
=======
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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
            ),
          ],
        ),
      ),
<<<<<<< HEAD
=======
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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
    );
  }

  @override
  Widget build(BuildContext context) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Pharmacy',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: medicalBlue,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 🔥 RESTORED: EMPTY STATE LABEL 🔥
      body: _reminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_information_outlined,
                    size: 100,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your medicine list is empty.\nTap the + button to stay on track!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
<<<<<<< HEAD
                final r = _reminders[index];
                bool isTaken = r['lastTakenDate'] == today;
                bool lowStock = r['stockCount'] <= 5;
=======
                final reminder = _reminders[index];
                final timesList = reminder['times'] as List<dynamic>;
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)

                return Card(
                  elevation: isTaken ? 1 : 4,
                  color: isTaken ? Colors.green.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
<<<<<<< HEAD
                  child: ListTile(
                    leading: IconButton(
                      icon: Icon(
                        isTaken
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isTaken ? Colors.green : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () => _toggleTaken(index),
                    ),
                    title: Text(
                      r['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isTaken ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      "${r['instruction']} • Stock: ${r['stockCount']}",
                    ),
                    trailing: PopupMenuButton(
                      onSelected: (val) => val == 'edit'
                          ? _showMedDialog(index: index)
                          : _confirmDelete(index),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
=======
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
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
                      ],
                    ),
                  ),
                );
              },
            ),
<<<<<<< HEAD
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedDialog(),
        backgroundColor: medicalBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
=======
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReminderDialog(),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.alarm_add, color: Colors.white),
        label: const Text(
          'Add Pill',
          style: TextStyle(color: Colors.white),
        ),
>>>>>>> 0c81094 (Completed medicine reminder and added export option to medical reports digitizer)
      ),
    );
  }
}
