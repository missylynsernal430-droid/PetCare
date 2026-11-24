class Feeding {
  const Feeding({
    required this.id,
    required this.petId,
    required this.timeMinutes,
    required this.note,
    required this.isEnabled,
  });

  final String id;
  final String petId;
  final int timeMinutes;
  final String note;
  final bool isEnabled;

  Map<String, Object?> toMap() => {
    'id': id,
    'petId': petId,
    'timeMinutes': timeMinutes,
    'note': note,
    'isEnabled': isEnabled ? 1 : 0,
  };

  factory Feeding.fromMap(Map<String, Object?> map) => Feeding(
    id: map['id']! as String,
    petId: map['petId']! as String,
    timeMinutes: map['timeMinutes']! as int,
    note: map['note']! as String,
    isEnabled: map['isEnabled'] == 1,
  );
}

class HealthReminder {
  const HealthReminder({
    required this.id,
    required this.petId,
    required this.title,
    required this.scheduledAt,
    required this.notes,
  });

  final String id;
  final String petId;
  final String title;
  final DateTime scheduledAt;
  final String notes;

  Map<String, Object?> toMap() => {
    'id': id,
    'petId': petId,
    'title': title,
    'scheduledAt': scheduledAt.toIso8601String(),
    'notes': notes,
  };

  factory HealthReminder.fromMap(Map<String, Object?> map) => HealthReminder(
    id: map['id']! as String,
    petId: map['petId']! as String,
    title: map['title']! as String,
    scheduledAt: DateTime.parse(map['scheduledAt']! as String),
    notes: map['notes']! as String,
  );
}

class GroomingLog {
  const GroomingLog({
    required this.id,
    required this.petId,
    required this.type,
    required this.date,
    required this.notes,
    required this.repeatDays,
  });

  final String id;
  final String petId;
  final String type;
  final DateTime date;
  final String notes;
  final int? repeatDays;

  Map<String, Object?> toMap() => {
    'id': id,
    'petId': petId,
    'type': type,
    'date': date.toIso8601String(),
    'notes': notes,
    'repeatDays': repeatDays,
  };

  factory GroomingLog.fromMap(Map<String, Object?> map) => GroomingLog(
    id: map['id']! as String,
    petId: map['petId']! as String,
    type: map['type']! as String,
    date: DateTime.parse(map['date']! as String),
    notes: map['notes']! as String,
    repeatDays: map['repeatDays'] as int?,
  );
}

class CareTask {
  const CareTask({
    required this.id,
    required this.petId,
    required this.title,
    required this.notes,
    required this.isCompleted,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String title;
  final String notes;
  final bool isCompleted;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'petId': petId,
    'title': title,
    'notes': notes,
    'isCompleted': isCompleted ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CareTask.fromMap(Map<String, Object?> map) => CareTask(
    id: map['id']! as String,
    petId: map['petId']! as String,
    title: map['title']! as String,
    notes: map['notes']! as String,
    isCompleted: map['isCompleted'] == 1,
    createdAt: DateTime.parse(map['createdAt']! as String),
  );
}
