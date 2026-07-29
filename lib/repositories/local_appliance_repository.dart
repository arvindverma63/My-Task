import 'package:shared_preferences/shared_preferences.dart';
import '../models/appliance_model.dart';
import 'appliance_repository.dart';

class LocalApplianceRepository implements ApplianceRepository {
  static const String _keyAppliances = 'appliances';
  static const String _keyServiceRecords = 'service_records';

  @override
  Future<List<Appliance>> getAppliances() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyAppliances) ?? [];
    return list.map((item) => Appliance.fromJson(item)).toList();
  }

  @override
  Future<void> saveAppliance(Appliance appliance) async {
    final prefs = await SharedPreferences.getInstance();
    final appliances = await getAppliances();
    final index = appliances.indexWhere((a) => a.id == appliance.id);
    if (index >= 0) {
      appliances[index] = appliance;
    } else {
      appliances.add(appliance);
    }
    final list = appliances.map((a) => a.toJson()).toList();
    await prefs.setStringList(_keyAppliances, list);
  }

  @override
  Future<void> deleteAppliance(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final appliances = await getAppliances();
    appliances.removeWhere((a) => a.id == id);
    final list = appliances.map((a) => a.toJson()).toList();
    await prefs.setStringList(_keyAppliances, list);

    // Clean up corresponding service logs as well
    final records = await _getAllServiceRecords();
    records.removeWhere((r) => r.applianceId == id);
    final recordList = records.map((r) => r.toJson()).toList();
    await prefs.setStringList(_keyServiceRecords, recordList);
  }

  @override
  Future<List<ServiceRecord>> getServiceRecords(String applianceId) async {
    final records = await _getAllServiceRecords();
    return records.where((r) => r.applianceId == applianceId).toList();
  }

  @override
  Future<void> saveServiceRecord(ServiceRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _getAllServiceRecords();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    final list = records.map((r) => r.toJson()).toList();
    await prefs.setStringList(_keyServiceRecords, list);
  }

  @override
  Future<void> deleteServiceRecord(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await _getAllServiceRecords();
    records.removeWhere((r) => r.id == recordId);
    final list = records.map((r) => r.toJson()).toList();
    await prefs.setStringList(_keyServiceRecords, list);
  }

  Future<List<ServiceRecord>> _getAllServiceRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyServiceRecords) ?? [];
    return list.map((item) => ServiceRecord.fromJson(item)).toList();
  }
}
