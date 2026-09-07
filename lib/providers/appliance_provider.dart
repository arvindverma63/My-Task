import 'package:flutter/material.dart';
import '../models/appliance_model.dart';
import '../repositories/appliance_repository.dart';

class ApplianceProvider with ChangeNotifier {
  final ApplianceRepository _repository;
  List<Appliance> _appliances = [];
  bool _isLoading = true;

  ApplianceProvider(this._repository) {
    loadAppliances();
  }

  bool get isLoading => _isLoading;
  List<Appliance> get appliances => _appliances;

  Future<void> loadAppliances({bool setLoader = true}) async {
    if (setLoader) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _appliances = await _repository.getAppliances();
    } finally {
      if (setLoader) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addAppliance(Appliance appliance) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveAppliance(appliance);
      await loadAppliances(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAppliance(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteAppliance(id);
      await loadAppliances(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ServiceRecord>> getServiceRecords(String applianceId) async {
    final list = await _repository.getServiceRecords(applianceId);
    list.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
    return list;
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveServiceRecord(record);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteServiceRecord(String recordId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteServiceRecord(recordId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
