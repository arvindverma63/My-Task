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

  EmployeeProvider(this._repository) {
    _loadAllData();
  }

  List<Employee> get employees => _employees;
  List<IroningWorker> get ironingWorkers => _ironingWorkers;

  Future<void> _loadAllData() async {
    _employees = await _repository.getEmployees();
    _ironingWorkers = await _repository.getIroningWorkers();
    notifyListeners();
  }

  Future<void> addEmployee(Employee employee) async {
    await _repository.saveEmployee(employee);
    await _loadAllData();
  }

  Future<void> updateEmployee(Employee employee) async {
    await _repository.updateEmployee(employee);
    await _loadAllData();
  }

  Future<void> deleteEmployee(String id) async {
    await _repository.deleteEmployee(id);
    await _loadAllData();
  }

  Future<List<AttendanceEntry>> getAttendance(String employeeId) async {
    if (!_attendanceData.containsKey(employeeId)) {
      _attendanceData[employeeId] = await _repository.getAttendance(employeeId);
    }
    return _attendanceData[employeeId]!;
  }

  Future<void> markAttendance(AttendanceEntry entry) async {
    final existing = await _repository.getAttendance(entry.employeeId);
    final index = existing.indexWhere((e) => e.id == entry.id);

    if (index != -1) {
      await _repository.updateAttendance(entry);
    } else {
      await _repository.saveAttendance(entry);
    }
    
    _attendanceData.remove(entry.employeeId); // Force reload
    notifyListeners();
  }

  Future<void> deleteAttendance(String employeeId, String entryId) async {
    await _repository.deleteAttendance(employeeId, entryId);
    _attendanceData.remove(employeeId); // Force reload
    notifyListeners();
  }

  // Ironing worker operations
  Future<void> addIroningWorker(IroningWorker worker) async {
    await _repository.saveIroningWorker(worker);
    await _loadAllData();
  }

  Future<void> deleteIroningWorker(String id) async {
    await _repository.deleteIroningWorker(id);
    await _loadAllData();
  }

  Future<List<IronRate>> getIronRates(String workerId) async {
    if (!_ironRates.containsKey(workerId)) {
      _ironRates[workerId] = await _repository.getIronRates(workerId);
    }
    return _ironRates[workerId]!;
  }

  Future<void> saveIronRate(String workerId, IronRate rate) async {
    await _repository.saveIronRate(workerId, rate);
    _ironRates.remove(workerId); // Force reload
    notifyListeners();
  }

  Future<void> updateIronRate(String workerId, IronRate rate) async {
    await _repository.updateIronRate(workerId, rate);
    _ironRates.remove(workerId); // Force reload
    notifyListeners();
  }

  Future<List<IroningRecord>> getIroningRecords(String workerId) async {
    if (!_ironingRecords.containsKey(workerId)) {
      _ironingRecords[workerId] = await _repository.getIroningRecords(workerId);
    }
    return _ironingRecords[workerId]!;
  }

  Future<void> saveIroningRecord(String workerId, IroningRecord record) async {
    await _repository.saveIroningRecord(workerId, record);
    _ironingRecords.remove(workerId); // Force reload
    notifyListeners();
  }

  Future<List<IroningPayment>> getIroningPayments(String workerId) async {
    if (!_ironingPayments.containsKey(workerId)) {
      _ironingPayments[workerId] = await _repository.getIroningPayments(workerId);
    }
    return _ironingPayments[workerId]!;
  }

  Future<void> saveIroningPayment(String workerId, IroningPayment payment) async {
    await _repository.saveIroningPayment(workerId, payment);
    _ironingPayments.remove(workerId); // Force reload
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _repository.clearAll();
    _employees = [];
    _ironingWorkers = [];
    _attendanceData = {};
    _ironRates = {};
    _ironingRecords = {};
    _ironingPayments = {};
    notifyListeners();
  }

  Future<void> refreshData() async {
    _attendanceData.clear();
    _ironRates.clear();
    _ironingRecords.clear();
    _ironingPayments.clear();
    await _loadAllData();
  }
}
