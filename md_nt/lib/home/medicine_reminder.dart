import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:android_intent_plus/android_intent.dart';
import 'package:intl/intl.dart';

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
    if (savedData != null) {
      setState(
        () =>
            _reminders = List<Map<String, dynamic>>.from(jsonDecode(savedData)),
      );
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medicine_reminders_v3', jsonEncode(_reminders));
  }

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
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                  ),
                ),
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
            ),
          ],
        ),
      ),
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
                final r = _reminders[index];
                bool isTaken = r['lastTakenDate'] == today;
                bool lowStock = r['stockCount'] <= 5;

                return Card(
                  elevation: isTaken ? 1 : 4,
                  color: isTaken ? Colors.green.shade50 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
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
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMedDialog(),
        backgroundColor: medicalBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}
