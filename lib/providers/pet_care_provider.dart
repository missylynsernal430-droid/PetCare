import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/care_items.dart';
import '../models/pet.dart';
import '../services/local_database.dart';
import '../services/notification_service.dart';

class PetCareProvider extends ChangeNotifier {
  PetCareProvider(this._database, this._notifications);

  final LocalDatabase _database;
  final NotificationService _notifications;
  final _uuid = const Uuid();

  List<Pet> pets = [];
  List<Feeding> feedings = [];
  List<HealthReminder> healthReminders = [];
  List<GroomingLog> groomingLogs = [];
  List<CareTask> careTasks = [];
  bool isLoading = true;

  Future<void> load() async {
    final results = await Future.wait([
      _database.readAll('pets'),
      _database.readAll('feedings'),
      _database.readAll('health_reminders'),
      _database.readAll('grooming_logs'),
      _database.readAll('care_tasks'),
    ]);
    pets = results[0].map(Pet.fromMap).toList();
    feedings = results[1].map(Feeding.fromMap).toList();
    healthReminders = results[2].map(HealthReminder.fromMap).toList();
    groomingLogs = results[3].map(GroomingLog.fromMap).toList();
    careTasks = results[4].map(CareTask.fromMap).toList();
    isLoading = false;
    notifyListeners();
    for (final feeding in feedings) {
      await _notifications.scheduleFeeding(feeding, petName(feeding.petId));
    }
    for (final reminder in healthReminders) {
      await _notifications.scheduleHealth(reminder, petName(reminder.petId));
    }
    for (final log in groomingLogs) {
      await _notifications.scheduleGrooming(log, petName(log.petId));
    }
  }

  String petName(String id) =>
      pets.where((pet) => pet.id == id).firstOrNull?.name ?? 'Your pet';

  DateTime? lastGrooming(String petId) {
    final logs = groomingLogs.where((log) => log.petId == petId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return logs.firstOrNull?.date;
  }

  Future<void> savePet(Pet? original, String name, String type, int age) async {
    final pet = Pet(
      id: original?.id ?? _uuid.v4(),
      name: name,
      type: type,
      age: age,
    );
    if (original == null) {
      await _database.insert('pets', pet.toMap());
      pets = [...pets, pet];
    } else {
      await _database.update('pets', pet.toMap());
      pets = pets.map((item) => item.id == pet.id ? pet : item).toList();
    }
    notifyListeners();
  }

  Future<void> deletePet(Pet pet) async {
    await _database.delete('pets', pet.id);
    pets = pets.where((item) => item.id != pet.id).toList();
    final deletedFeedings = feedings
        .where((item) => item.petId == pet.id)
        .toList();
    final deletedReminders = healthReminders
        .where((item) => item.petId == pet.id)
        .toList();
    final deletedLogs = groomingLogs
        .where((item) => item.petId == pet.id)
        .toList();
    for (final item in deletedFeedings) {
      await _notifications.cancelFeeding(item.id);
    }
    for (final item in deletedReminders) {
      await _notifications.cancelHealth(item.id);
    }
    for (final item in deletedLogs) {
      await _notifications.cancelGrooming(item.id);
    }
    feedings = feedings.where((item) => item.petId != pet.id).toList();
    healthReminders = healthReminders
        .where((item) => item.petId != pet.id)
        .toList();
    groomingLogs = groomingLogs.where((item) => item.petId != pet.id).toList();
    careTasks = careTasks.where((item) => item.petId != pet.id).toList();
    notifyListeners();
  }

  Future<void> saveFeeding(Feeding? original, Feeding value) async {
    final feeding = Feeding(
      id: original?.id ?? _uuid.v4(),
      petId: value.petId,
      timeMinutes: value.timeMinutes,
      note: value.note,
      isEnabled: value.isEnabled,
    );
    if (original == null) {
      await _database.insert('feedings', feeding.toMap());
      feedings = [...feedings, feeding];
    } else {
      await _database.update('feedings', feeding.toMap());
      feedings = feedings
          .map((item) => item.id == feeding.id ? feeding : item)
          .toList();
    }
    await _notifications.scheduleFeeding(feeding, petName(feeding.petId));
    notifyListeners();
  }

  Future<void> toggleFeeding(Feeding feeding, bool enabled) => saveFeeding(
    feeding,
    Feeding(
      id: feeding.id,
      petId: feeding.petId,
      timeMinutes: feeding.timeMinutes,
      note: feeding.note,
      isEnabled: enabled,
    ),
  );

  Future<void> deleteFeeding(Feeding feeding) async {
    await _database.delete('feedings', feeding.id);
    await _notifications.cancelFeeding(feeding.id);
    feedings = feedings.where((item) => item.id != feeding.id).toList();
    notifyListeners();
  }

  Future<void> saveHealth(
    HealthReminder? original,
    HealthReminder value,
  ) async {
    final reminder = HealthReminder(
      id: original?.id ?? _uuid.v4(),
      petId: value.petId,
      title: value.title,
      scheduledAt: value.scheduledAt,
      notes: value.notes,
    );
    if (original == null) {
      await _database.insert('health_reminders', reminder.toMap());
      healthReminders = [...healthReminders, reminder];
    } else {
      await _database.update('health_reminders', reminder.toMap());
      healthReminders = healthReminders
          .map((item) => item.id == reminder.id ? reminder : item)
          .toList();
    }
    await _notifications.scheduleHealth(reminder, petName(reminder.petId));
    notifyListeners();
  }

  Future<void> deleteHealth(HealthReminder reminder) async {
    await _database.delete('health_reminders', reminder.id);
    await _notifications.cancelHealth(reminder.id);
    healthReminders = healthReminders
        .where((item) => item.id != reminder.id)
        .toList();
    notifyListeners();
  }

  Future<void> saveGrooming(GroomingLog? original, GroomingLog value) async {
    final log = GroomingLog(
      id: original?.id ?? _uuid.v4(),
      petId: value.petId,
      type: value.type,
      date: value.date,
      notes: value.notes,
      repeatDays: value.repeatDays,
    );
    if (original == null) {
      await _database.insert('grooming_logs', log.toMap());
      groomingLogs = [...groomingLogs, log];
    } else {
      await _database.update('grooming_logs', log.toMap());
      groomingLogs = groomingLogs
          .map((item) => item.id == log.id ? log : item)
          .toList();
    }
    await _notifications.scheduleGrooming(log, petName(log.petId));
    notifyListeners();
  }

  Future<void> deleteGrooming(GroomingLog log) async {
    await _database.delete('grooming_logs', log.id);
    await _notifications.cancelGrooming(log.id);
    groomingLogs = groomingLogs.where((item) => item.id != log.id).toList();
    notifyListeners();
  }

  Future<void> saveTask(CareTask? original, CareTask value) async {
    final task = CareTask(
      id: original?.id ?? _uuid.v4(),
      petId: value.petId,
      title: value.title,
      notes: value.notes,
      isCompleted: value.isCompleted,
      createdAt: original?.createdAt ?? value.createdAt,
    );
    if (original == null) {
      await _database.insert('care_tasks', task.toMap());
      careTasks = [...careTasks, task];
    } else {
      await _database.update('care_tasks', task.toMap());
      careTasks = careTasks
          .map((item) => item.id == task.id ? task : item)
          .toList();
    }
    notifyListeners();
  }

  Future<void> toggleTask(CareTask task, bool completed) => saveTask(
    task,
    CareTask(
      id: task.id,
      petId: task.petId,
      title: task.title,
      notes: task.notes,
      isCompleted: completed,
      createdAt: task.createdAt,
    ),
  );

  Future<void> deleteTask(CareTask task) async {
    await _database.delete('care_tasks', task.id);
    careTasks = careTasks.where((item) => item.id != task.id).toList();
    notifyListeners();
  }
}
