import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../repositories/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository _repository;
  List<Employee> _employees = [];
  List<IroningWorker> _ironingWorkers = [];
  Map<String, List<AttendanceEntry>> _attendanceData = {};
  Map<String, List<IronRate>> _ironRates = {};
  Map<String, List<IroningRecord>> _ironingRecords = {};
  Map<String, List<IroningPayment>> _ironingPayments = {};
  bool _isLoading = true;

  EmployeeProvider(this._repository) {
    _loadAllData();
  }

  bool get isLoading => _isLoading;
  List<Employee> get employees => _employees;
  List<IroningWorker> get ironingWorkers => _ironingWorkers;

  Future<void> _loadAllData({bool setLoader = true}) async {
    if (setLoader) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      _employees = await _repository.getEmployees();
      _ironingWorkers = await _repository.getIroningWorkers();
    } finally {
      if (setLoader) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addEmployee(Employee employee) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveEmployee(employee);
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateEmployee(Employee employee) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateEmployee(employee);
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteEmployee(id);
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AttendanceEntry>> getAttendance(String employeeId) async {
    if (!_attendanceData.containsKey(employeeId)) {
      _attendanceData[employeeId] = await _repository.getAttendance(employeeId);
    }
    return _attendanceData[employeeId]!;
  }

  Future<void> markAttendance(AttendanceEntry entry) async {
    _isLoading = true;
    notifyListeners();
    try {
      final existing = await _repository.getAttendance(entry.employeeId);
      final sameDateEntries = existing.where((e) =>
        e.date.year == entry.date.year &&
        e.date.month == entry.date.month &&
        e.date.day == entry.date.day
      ).toList();

      if (sameDateEntries.isNotEmpty) {
        // Clean up any stale duplicate entries for this day if there are multiple
        for (int i = 1; i < sameDateEntries.length; i++) {
          await _repository.deleteAttendance(entry.employeeId, sameDateEntries[i].id);
        }

        final targetId = sameDateEntries.first.id;
        final updated = AttendanceEntry(
          id: targetId,
          employeeId: entry.employeeId,
          date: entry.date,
          status: entry.status,
          checkInTime: entry.checkInTime,
          checkOutTime: entry.checkOutTime,
          lateTime: entry.lateTime,
          earlyTime: entry.earlyTime,
          amountGiven: entry.amountGiven > 0 ? entry.amountGiven : sameDateEntries.first.amountGiven,
          paymentDescription: entry.paymentDescription ?? sameDateEntries.first.paymentDescription,
        );
        await _repository.updateAttendance(updated);
      } else {
        await _repository.saveAttendance(entry);
      }
      
      _attendanceData.remove(entry.employeeId);
      _attendanceData[entry.employeeId] = await _repository.getAttendance(entry.employeeId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAttendance(String employeeId, String entryId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteAttendance(employeeId, entryId);
      _attendanceData.remove(employeeId);
      _attendanceData[employeeId] = await _repository.getAttendance(employeeId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteDailyAttendance(String employeeId, DateTime date) async {
    _isLoading = true;
    notifyListeners();
    try {
      final existing = await _repository.getAttendance(employeeId);
      final sameDateEntries = existing.where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day
      ).toList();

      for (final entry in sameDateEntries) {
        await _repository.deleteAttendance(employeeId, entry.id);
      }
      _attendanceData.remove(employeeId);
      _attendanceData[employeeId] = await _repository.getAttendance(employeeId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Ironing worker operations
  Future<void> addIroningWorker(IroningWorker worker) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveIroningWorker(worker);
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteIroningWorker(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteIroningWorker(id);
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<IronRate>> getIronRates(String workerId) async {
    if (!_ironRates.containsKey(workerId)) {
      _ironRates[workerId] = await _repository.getIronRates(workerId);
    }
    return _ironRates[workerId]!;
  }

  Future<void> saveIronRate(String workerId, IronRate rate) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveIronRate(workerId, rate);
      _ironRates.remove(workerId); // Force reload
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateIronRate(String workerId, IronRate rate) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.updateIronRate(workerId, rate);
      _ironRates.remove(workerId); // Force reload
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<IroningRecord>> getIroningRecords(String workerId) async {
    if (!_ironingRecords.containsKey(workerId)) {
      _ironingRecords[workerId] = await _repository.getIroningRecords(workerId);
    }
    return _ironingRecords[workerId]!;
  }

  Future<void> saveIroningRecord(String workerId, IroningRecord record) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveIroningRecord(workerId, record);
      _ironingRecords.remove(workerId); // Force reload
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<IroningPayment>> getIroningPayments(String workerId) async {
    if (!_ironingPayments.containsKey(workerId)) {
      _ironingPayments[workerId] = await _repository.getIroningPayments(workerId);
    }
    return _ironingPayments[workerId]!;
  }

  Future<void> saveIroningPayment(String workerId, IroningPayment payment) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.saveIroningPayment(workerId, payment);
      _ironingPayments.remove(workerId); // Force reload
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.clearAll();
      _employees = [];
      _ironingWorkers = [];
      _attendanceData = {};
      _ironRates = {};
      _ironingRecords = {};
      _ironingPayments = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();
    _attendanceData.clear();
    _ironRates.clear();
    _ironingRecords.clear();
    _ironingPayments.clear();
    try {
      await _loadAllData(setLoader: false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
