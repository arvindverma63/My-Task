enum AttendanceStatus { present, absent }

extension AttendanceStatusX on AttendanceStatus {
  String get label => switch (this) {
        AttendanceStatus.present => 'Present',
        AttendanceStatus.absent => 'Absent',
      };
}

AttendanceStatus attendanceStatusFromString(String value) {
  return AttendanceStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => AttendanceStatus.present,
  );
}

class TodoAttendanceRecord {
  final String id;
  final DateTime date;
  final AttendanceStatus status;
  final String note;
  final double? price;
  final DateTime createdAt;

  const TodoAttendanceRecord({
    required this.id,
    required this.date,
    required this.status,
    this.note = '',
    this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'status': status.name,
      'note': note,
      if (price != null) 'price': price,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoAttendanceRecord.fromMap(Map<String, dynamic> map) {
    final date = DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now();
    return TodoAttendanceRecord(
      id: map['id'] ?? '',
      date: DateTime(date.year, date.month, date.day),
      status: attendanceStatusFromString(map['status'] ?? 'present'),
      note: map['note'] ?? '',
      price: (map['price'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
