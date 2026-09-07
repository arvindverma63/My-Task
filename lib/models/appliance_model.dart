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
  });

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
    };
  }

  factory Appliance.fromMap(Map<String, dynamic> map) {
    return Appliance(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      brand: map['brand'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      warrantyStart: map['warrantyStart'] != null ? DateTime.parse(map['warrantyStart']) : null,
      warrantyEnd: map['warrantyEnd'] != null ? DateTime.parse(map['warrantyEnd']) : null,
      invoicePath: map['invoicePath'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
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
    return ServiceRecord(
      id: map['id'] ?? '',
      applianceId: map['applianceId'] ?? '',
      serviceDate: map['serviceDate'] != null ? DateTime.parse(map['serviceDate']) : DateTime.now(),
      price: map['price'] != null ? (double.tryParse(map['price'].toString()) ?? 0.0) : 0.0,
      remarks: map['remarks'] ?? '',
      billPath: map['billPath'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceRecord.fromJson(String source) => ServiceRecord.fromMap(json.decode(source));
}
