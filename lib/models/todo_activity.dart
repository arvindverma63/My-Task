enum TodoActivityType { note, created, completed, reopened }

extension TodoActivityTypeX on TodoActivityType {
  String get label => switch (this) {
        TodoActivityType.note => 'Note',
        TodoActivityType.created => 'Created',
        TodoActivityType.completed => 'Completed',
        TodoActivityType.reopened => 'Reopened',
      };
}

TodoActivityType todoActivityTypeFromString(String value) {
  return TodoActivityType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TodoActivityType.note,
  );
}

class TodoActivity {
  final String id;
  final TodoActivityType type;
  final String title;
  final String description;
  final DateTime createdAt;

  const TodoActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoActivity.fromMap(Map<String, dynamic> map) {
    return TodoActivity(
      id: map['id'] ?? '',
      type: todoActivityTypeFromString(map['type'] ?? 'note'),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
