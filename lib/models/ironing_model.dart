class IroningWorker {
  final String id;
  final String name;
  final String contact;
  final DateTime joiningDate;

  IroningWorker({
    required this.id,
    required this.name,
    required this.contact,
    required this.joiningDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'joiningDate': joiningDate.toIso8601String(),
    };
  }

  factory IroningWorker.fromMap(Map<String, dynamic> map) {
    return IroningWorker(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      contact: map['contact'] ?? '',
      joiningDate: DateTime.tryParse(map['joiningDate']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class IronRate {
  final String id;
  final String clothingType; // e.g. Shirt, Pant, Saree
  final double rate;
  final DateTime date;

  IronRate({
    required this.id,
    required this.clothingType,
    required this.rate,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clothingType': clothingType,
      'rate': rate,
      'date': date.toIso8601String(),
    };
  }

  factory IronRate.fromMap(Map<String, dynamic> map) {
    return IronRate(
      id: map['id'] ?? '',
      clothingType: map['clothingType'] ?? '',
      rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class IroningRecord {
  final String id;
  final String workerId;
  final DateTime date;
  final Map<String, int> clothesCount; // e.g. {'Shirt': 5, 'Pant': 3}
  final double totalWage;
  final DateTime createdAt;

  IroningRecord({
    required this.id,
    required this.workerId,
    required this.date,
    required this.clothesCount,
    required this.totalWage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'clothesCount': clothesCount,
      'totalWage': totalWage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IroningRecord.fromMap(Map<String, dynamic> map) {
    final rawCount = map['clothesCount'];
    final Map<String, int> parsedCount = {};
    if (rawCount is Map) {
      rawCount.forEach((k, v) {
        parsedCount[k.toString()] = (v as num).toInt();
      });
    }
    return IroningRecord(
      id: map['id'] ?? '',
      workerId: map['workerId'] ?? map['employeeId'] ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      clothesCount: parsedCount,
      totalWage: (map['totalWage'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class IroningPayment {
  final String id;
  final String workerId;
  final DateTime date;
  final double amount;
  final String description;
  final DateTime createdAt;

  IroningPayment({
    required this.id,
    required this.workerId,
    required this.date,
    required this.amount,
    this.description = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workerId': workerId,
      'date': date.toIso8601String(),
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IroningPayment.fromMap(Map<String, dynamic> map) {
    return IroningPayment(
      id: map['id'] ?? '',
      workerId: map['workerId'] ?? map['employeeId'] ?? '',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
