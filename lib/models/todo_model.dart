import 'dart:convert';
import 'todo_activity.dart';
import 'todo_attendance.dart';
import 'todo_field.dart';

enum TodoType { task, service }

class Todo {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? reminderAt;
  final TodoType type;
  final double? basePrice;
  final List<TodoField> customFields;
  final List<TodoActivity> activities;
  final List<TodoAttendanceRecord> attendanceRecords;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.reminderAt,
    this.type = TodoType.task,
    this.basePrice,
    this.customFields = const [],
    this.activities = const [],
    this.attendanceRecords = const [],
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? reminderAt,
    TodoType? type,
    double? basePrice,
    List<TodoField>? customFields,
    List<TodoActivity>? activities,
    List<TodoAttendanceRecord>? attendanceRecords,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      reminderAt: reminderAt ?? this.reminderAt,
      type: type ?? this.type,
      basePrice: basePrice ?? this.basePrice,
      customFields: customFields ?? this.customFields,
      activities: activities ?? this.activities,
      attendanceRecords: attendanceRecords ?? this.attendanceRecords,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      if (reminderAt != null) 'reminderAt': reminderAt!.toIso8601String(),
      'type': type.name,
      if (basePrice != null) 'basePrice': basePrice,
      'customFields': customFields.map((field) => field.toMap()).toList(),
      'activities': activities.map((activity) => activity.toMap()).toList(),
      'attendanceRecords': attendanceRecords.map((record) => record.toMap()).toList(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    final customFieldsRaw = map['customFields'];
    final activitiesRaw = map['activities'];
    final attendanceRecordsRaw = map['attendanceRecords'];
    final reminderAtRaw = map['reminderAt'];
    return Todo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      type: TodoType.values.firstWhere((e) => e.name == map['type'], orElse: () => TodoType.task),
      basePrice: (map['basePrice'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      reminderAt: reminderAtRaw == null ? null : DateTime.tryParse(reminderAtRaw.toString()),
      customFields: customFieldsRaw is List
          ? customFieldsRaw
              .whereType<Map>()
              .map((item) => TodoField.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      activities: activitiesRaw is List
          ? activitiesRaw
              .whereType<Map>()
              .map((item) => TodoActivity.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      attendanceRecords: attendanceRecordsRaw is List
          ? attendanceRecordsRaw
              .whereType<Map>()
              .map((item) => TodoAttendanceRecord.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Todo.fromJson(String source) => Todo.fromMap(json.decode(source));
}
