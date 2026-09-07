
enum AttendanceStatus { present, absent, late, early }

class Employee {
  final String id;
  final String name;
  final String contact;
  final String? photoPath;
  final DateTime joiningDate;
  final DateTime? relievingDate;
  final double baseSalary; // Monthly or Daily base for calculation
  final String salaryBasis; // 'daily' or 'monthly'

  Employee({
    required this.id,
    required this.name,
    required this.contact,
    this.photoPath,
    required this.joiningDate,
    this.relievingDate,
    required this.baseSalary,
    this.salaryBasis = 'daily',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'photoPath': photoPath,
      'joiningDate': joiningDate.toIso8601String(),
      'relievingDate': relievingDate?.toIso8601String(),
      'baseSalary': baseSalary,
      'salaryBasis': salaryBasis,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      contact: map['contact'],
      photoPath: map['photoPath'],
      joiningDate: DateTime.parse(map['joiningDate']),
      relievingDate: map['relievingDate'] != null ? DateTime.parse(map['relievingDate']) : null,
      baseSalary: map['baseSalary'] != null ? (double.tryParse(map['baseSalary'].toString()) ?? 0.0) : 0.0,
      salaryBasis: map['salaryBasis'] ?? 'daily',
    );
  }
}

class AttendanceEntry {
  final String id;
  final String employeeId;
  final DateTime date;
  final AttendanceStatus status;
  final String? checkInTime;
  final String? checkOutTime;
  final String? lateTime;
  final String? earlyTime;
  final double amountGiven; // Date wise money given/advance
  final String? paymentDescription;

  AttendanceEntry({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.lateTime,
    this.earlyTime,
    this.amountGiven = 0,
    this.paymentDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'status': status.name,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'lateTime': lateTime,
      'earlyTime': earlyTime,
      'amountGiven': amountGiven,
      'paymentDescription': paymentDescription,
    };
  }

  factory AttendanceEntry.fromMap(Map<String, dynamic> map) {
    return AttendanceEntry(
      id: map['id'],
      employeeId: map['employeeId'],
      date: DateTime.parse(map['date']),
      status: AttendanceStatus.values.firstWhere((e) => e.name == map['status']),
      checkInTime: map['checkInTime'],
      checkOutTime: map['checkOutTime'],
      lateTime: map['lateTime'],
      earlyTime: map['earlyTime'],
      amountGiven: map['amountGiven'] != null ? (double.tryParse(map['amountGiven'].toString()) ?? 0.0) : 0.0,
      paymentDescription: map['paymentDescription'],
    );
  }
}
