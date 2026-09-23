import 'package:flutter/material.dart';
import '../models/appliance_model.dart';
import '../repositories/appliance_repository.dart';
import '../services/notification_service.dart';

class ApplianceProvider with ChangeNotifier {
  final ApplianceRepository _repository;
  List<Appliance> _appliances = [];
  bool _isLoading = true;

  ApplianceProvider(this._repository) {
    loadAppliances();
  }

  bool get isLoading => _isLoading;
  List<Appliance> get appliances => _appliances;

  List<Appliance> get dueAppliances =>
      _appliances.where((a) => a.isRecurringDueActive).toList();

  List<Appliance> get pendingOrOverdueAppliances {
    return _appliances.where((a) {
      if (!a.isRecurringDueActive) return false;
      final status = a.dueStatus;
      return status == 'overdue' || status == 'due_today' || status == 'due_soon';
    }).toList();
  }

  Future<void> loadAppliances({bool setLoader = true}) async {
    if (setLoader) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _appliances = await _repository.getAppliances();
      // Sync active notifications in background
      NotificationService().rescheduleAll(_appliances);
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
      await NotificationService().scheduleApplianceDueNotification(appliance);
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
      await NotificationService().cancelApplianceNotification(id);
      await loadAppliances(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markDuePaid(
    String applianceId, {
    double? amountPaid,
    String? remarks,
    DateTime? paidDate,
    String? billPath,
  }) async {
    final index = _appliances.indexWhere((a) => a.id == applianceId);
    if (index == -1) return;

    final appliance = _appliances[index];
    final date = paidDate ?? DateTime.now();
    final cost = amountPaid ?? appliance.dueAmount ?? 0.0;
    final note = remarks ??
        '${appliance.dueFrequency != null ? appliance.dueFrequency!.toUpperCase() : ""} Due Payment cleared';

    // 1. Record service log
    final record = ServiceRecord(
      id: '${appliance.id}_srv_${DateTime.now().millisecondsSinceEpoch}',
      applianceId: appliance.id,
      serviceDate: date,
      price: cost,
      remarks: note,
      billPath: billPath,
      createdAt: DateTime.now(),
    );
    await addServiceRecord(record);

    // 2. Advance next due date to next cycle if recurring
    if (appliance.isRecurringDueActive) {
      final updatedNextDue = appliance.getNextCycleDueDate(appliance.nextDueDate ?? date);
      final updatedAppliance = appliance.copyWith(nextDueDate: updatedNextDue);
      await addAppliance(updatedAppliance);
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
