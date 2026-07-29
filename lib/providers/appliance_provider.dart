import 'package:flutter/material.dart';
import '../models/appliance_model.dart';
import '../repositories/appliance_repository.dart';

class ApplianceProvider with ChangeNotifier {
  final ApplianceRepository _repository;
  List<Appliance> _appliances = [];

  ApplianceProvider(this._repository) {
    loadAppliances();
  }

  List<Appliance> get appliances => _appliances;

  Future<void> loadAppliances() async {
    _appliances = await _repository.getAppliances();
    notifyListeners();
  }

  Future<void> addAppliance(Appliance appliance) async {
    await _repository.saveAppliance(appliance);
    await loadAppliances();
  }

  Future<void> deleteAppliance(String id) async {
    await _repository.deleteAppliance(id);
    await loadAppliances();
  }

  Future<List<ServiceRecord>> getServiceRecords(String applianceId) async {
    final list = await _repository.getServiceRecords(applianceId);
    list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return list;
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    await _repository.saveServiceRecord(record);
    notifyListeners();
  }

  Future<void> deleteServiceRecord(String recordId) async {
    await _repository.deleteServiceRecord(recordId);
    notifyListeners();
  }
}
