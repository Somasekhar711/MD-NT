import 'package:flutter/services.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const MethodChannel _channel = MethodChannel('md_nt/alarm');

  Future<void> initialize() async {}

  Future<void> scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _channel.invokeMethod('scheduleDailyAlarm', {
      'id': id,
      'medicineName': medicineName,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
    });
  }

  Future<void> scheduleOneTimeReminder({
    required int id,
    required String medicineName,
    required String title,
    required String body,
    required DateTime scheduledFor,
  }) async {
    await _channel.invokeMethod('scheduleOneTimeAlarm', {
      'id': id,
      'medicineName': medicineName,
      'title': title,
      'body': body,
      'timestamp': scheduledFor.millisecondsSinceEpoch,
    });
  }

  Future<void> cancel(int id) async {
    await _channel.invokeMethod('cancelAlarm', {'id': id});
  }

  Future<void> cancelMany(List<int> ids) async {
    await _channel.invokeMethod('cancelManyAlarms', {'ids': ids});
  }
}
