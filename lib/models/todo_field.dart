enum TodoFieldType { text, image, video, number }

extension TodoFieldTypeX on TodoFieldType {
  String get label => switch (this) {
        TodoFieldType.text => 'Text',
        TodoFieldType.image => 'Image',
        TodoFieldType.video => 'Video',
        TodoFieldType.number => 'Number',
      };

  String get storageValue => name;
}

TodoFieldType todoFieldTypeFromString(String value) {
  return TodoFieldType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TodoFieldType.text,
  );
}

class TodoField {
  final String id;
  final TodoFieldType type;
  final String label;
  final String value;

  const TodoField({
    required this.id,
    required this.type,
    required this.label,
    required this.value,
  });

  TodoField copyWith({
    String? id,
    TodoFieldType? type,
    String? label,
    String? value,
  }) {
    return TodoField(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'label': label,
      'value': value,
    };
  }

  factory TodoField.fromMap(Map<String, dynamic> map) {
    return TodoField(
      id: map['id'] ?? '',
      type: todoFieldTypeFromString(map['type'] ?? 'text'),
      label: map['label'] ?? '',
      value: map['value'] ?? '',
    );
  }
}
