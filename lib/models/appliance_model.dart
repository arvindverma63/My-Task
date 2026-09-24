import 'dart:convert';

class Appliance {
  final String id;
  final String name;
  final String type;
  final String brand;
  final String serialNumber;
  final DateTime? warrantyStart;
  final DateTime? warrantyEnd;
  final String? invoicePath;
  final DateTime createdAt;

  // Recurring Due & Notification Fields
  final String? dueFrequency; // 'none', 'daily', 'weekly', 'monthly', 'quarterly', 'yearly'
  final double? dueAmount;
  final DateTime? nextDueDate;
  final int dueReminderDaysBefore; // default: 1
  final bool isDueNotificationEnabled;

  Appliance({
    required this.id,
    required this.name,
    required this.type,
    required this.brand,
    required this.serialNumber,
    this.warrantyStart,
    this.warrantyEnd,
    this.invoicePath,
    required this.createdAt,
    this.dueFrequency,
    this.dueAmount,
    this.nextDueDate,
    this.dueReminderDaysBefore = 1,
    this.isDueNotificationEnabled = true,
  });

  bool get isRecurringDueActive =>
      dueFrequency != null && dueFrequency != 'none' && nextDueDate != null;

  int? get daysUntilDue {
    if (nextDueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate!.year, nextDueDate!.month, nextDueDate!.day);
    return due.difference(today).inDays;
  }

  String get dueStatus {
    final days = daysUntilDue;
    if (days == null || !isRecurringDueActive) return 'none';
    if (days < 0) return 'overdue';
    if (days == 0) return 'due_today';
    if (days <= 7) return 'due_soon';
    return 'upcoming';
  }

  static DateTime calculateNextDueDate(DateTime base, String? frequency) {
    switch (frequency?.toLowerCase()) {
      case 'daily':
        return base.add(const Duration(days: 1));
      case 'weekly':
        return base.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(base.year, base.month + 1, base.day);
      case 'quarterly':
        return DateTime(base.year, base.month + 3, base.day);
      case 'yearly':
        return DateTime(base.year + 1, base.month, base.day);
      default:
        return base.add(const Duration(days: 30));
    }
  }

  DateTime getNextCycleDueDate([DateTime? fromDate]) {
    final base = fromDate ?? nextDueDate ?? DateTime.now();
    return calculateNextDueDate(base, dueFrequency);
  }

  Appliance copyWith({
    String? id,
    String? name,
    String? type,
    String? brand,
    String? serialNumber,
    DateTime? warrantyStart,
    DateTime? warrantyEnd,
    String? invoicePath,
    DateTime? createdAt,
    String? dueFrequency,
    double? dueAmount,
    DateTime? nextDueDate,
    int? dueReminderDaysBefore,
    bool? isDueNotificationEnabled,
  }) {
    return Appliance(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyStart: warrantyStart ?? this.warrantyStart,
      warrantyEnd: warrantyEnd ?? this.warrantyEnd,
      invoicePath: invoicePath ?? this.invoicePath,
      createdAt: createdAt ?? this.createdAt,
      dueFrequency: dueFrequency ?? this.dueFrequency,
      dueAmount: dueAmount ?? this.dueAmount,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      dueReminderDaysBefore: dueReminderDaysBefore ?? this.dueReminderDaysBefore,
      isDueNotificationEnabled: isDueNotificationEnabled ?? this.isDueNotificationEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'brand': brand,
      'serialNumber': serialNumber,
      'warrantyStart': warrantyStart?.toIso8601String(),
      'warrantyEnd': warrantyEnd?.toIso8601String(),
      'invoicePath': invoicePath,
      'createdAt': createdAt.toIso8601String(),
      'dueFrequency': dueFrequency,
      'dueAmount': dueAmount,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'dueReminderDaysBefore': dueReminderDaysBefore,
      'isDueNotificationEnabled': isDueNotificationEnabled,
    };
  }

  factory Appliance.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final notifVal = map['isDueNotificationEnabled'];
    final bool isDueNotificationEnabled = notifVal == null
        ? true
        : (notifVal is bool
            ? notifVal
            : (notifVal == 1 || notifVal == '1' || notifVal.toString().toLowerCase() == 'true'));

    final reminderVal = map['dueReminderDaysBefore'];
    final int dueReminderDaysBefore = reminderVal is int
        ? reminderVal
        : (int.tryParse(reminderVal?.toString() ?? '') ?? 1);

    final dueAmtVal = map['dueAmount'];
    final double? dueAmount = dueAmtVal != null ? double.tryParse(dueAmtVal.toString()) : null;

    final freqVal = map['dueFrequency']?.toString();
    final String? dueFrequency = (freqVal != null && freqVal.isNotEmpty && freqVal != 'null') ? freqVal : null;

    return Appliance(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      brand: map['brand']?.toString() ?? '',
      serialNumber: map['serialNumber']?.toString() ?? '',
      warrantyStart: parseDate(map['warrantyStart']),
      warrantyEnd: parseDate(map['warrantyEnd']),
      invoicePath: map['invoicePath']?.toString(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      dueFrequency: dueFrequency,
      dueAmount: dueAmount,
      nextDueDate: parseDate(map['nextDueDate']),
      dueReminderDaysBefore: dueReminderDaysBefore,
      isDueNotificationEnabled: isDueNotificationEnabled,
    );
  }

  String toJson() => json.encode(toMap());

  factory Appliance.fromJson(String source) => Appliance.fromMap(json.decode(source));
}

class ServiceRecord {
  final String id;
  final String applianceId;
  final DateTime serviceDate;
  final double price;
  final String remarks;
  final String? billPath;
  final DateTime createdAt;

  ServiceRecord({
    required this.id,
    required this.applianceId,
    required this.serviceDate,
    required this.price,
    required this.remarks,
    this.billPath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'applianceId': applianceId,
      'serviceDate': serviceDate.toIso8601String(),
      'price': price,
      'remarks': remarks,
      'billPath': billPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    final priceVal = map['price'];
    final double price = priceVal != null ? (double.tryParse(priceVal.toString()) ?? 0.0) : 0.0;

    return ServiceRecord(
      id: map['id']?.toString() ?? '',
      applianceId: map['applianceId']?.toString() ?? '',
      serviceDate: parseDate(map['serviceDate']) ?? DateTime.now(),
      price: price,
      remarks: map['remarks']?.toString() ?? '',
      billPath: map['billPath']?.toString(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceRecord.fromJson(String source) => ServiceRecord.fromMap(json.decode(source));
}
