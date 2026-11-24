import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../models/care_items.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    timezone.setLocalLocation(timezone.getLocation(localTimezone.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  int _idFor(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x7fffffff;
    }
    return hash % 80000000;
  }

  NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'petcare_reminders',
      'Pet care reminders',
      channelDescription: 'Feeding times and pet care appointments',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> scheduleFeeding(Feeding feeding, String petName) async {
    final id = _idFor('feeding:${feeding.id}');
    await _plugin.cancel(id: id);
    if (!feeding.isEnabled) return;
    await _requestPermission();
    final now = timezone.TZDateTime.now(timezone.local);
    final hour = feeding.timeMinutes ~/ 60;
    final minute = feeding.timeMinutes % 60;
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: 'Feeding time',
      body:
          '${feeding.note.isEmpty ? 'Time to feed' : feeding.note} · $petName',
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelFeeding(String id) =>
      _plugin.cancel(id: _idFor('feeding:$id'));

  Future<void> scheduleHealth(HealthReminder reminder, String petName) async {
    final id = _idFor('health:${reminder.id}');
    await _plugin.cancel(id: id);
    final notificationAt = reminder.scheduledAt.subtract(
      const Duration(hours: 1),
    );
    if (!notificationAt.isAfter(DateTime.now())) return;
    await _requestPermission();
    await _plugin.zonedSchedule(
      id: id,
      title: 'Vet appointment coming up',
      body: '${reminder.title} · $petName · in 1 hour',
      scheduledDate: timezone.TZDateTime.from(notificationAt, timezone.local),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelHealth(String id) =>
      _plugin.cancel(id: _idFor('health:$id'));

  Future<void> scheduleGrooming(GroomingLog log, String petName) async {
    final baseId = _idFor('grooming:${log.id}') * 24;
    for (var index = 0; index < 24; index++) {
      await _plugin.cancel(id: baseId + index);
    }
    if (log.repeatDays == null || log.repeatDays! <= 0) return;
    await _requestPermission();
    var next = timezone.TZDateTime.from(
      log.date.add(Duration(days: log.repeatDays!)),
      timezone.local,
    );
    final now = timezone.TZDateTime.now(timezone.local);
    while (!next.isAfter(now)) {
      next = next.add(Duration(days: log.repeatDays!));
    }
    for (var index = 0; index < 24; index++) {
      await _plugin.zonedSchedule(
        id: baseId + index,
        title: 'Grooming day',
        body: 'Time for ${log.type.toLowerCase()} for $petName',
        scheduledDate: next,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      next = next.add(Duration(days: log.repeatDays!));
    }
  }

  Future<void> cancelGrooming(String id) async {
    final baseId = _idFor('grooming:$id') * 24;
    for (var index = 0; index < 24; index++) {
      await _plugin.cancel(id: baseId + index);
    }
  }
}
