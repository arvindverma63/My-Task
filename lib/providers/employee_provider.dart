import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../repositories/employee_repository.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeRepository _repository;
  List<Employee> _employees = [];
  Map<String, List<AttendanceEntry>> _attendanceData = {};

  EmployeeProvider(this._repository) {
    _loadEmployees();
  }

  List<Employee> get employees => _employees;

  Future<void> _loadEmployees() async {
    _employees = await _repository.getEmployees();
    notifyListeners();
  }

  Future<void> addEmployee(Employee employee) async {
    await _repository.saveEmployee(employee);
    await _loadEmployees();
  }

  Future<void> updateEmployee(Employee employee) async {
    await _repository.updateEmployee(employee);
    await _loadEmployees();
  }

  Future<void> deleteEmployee(String id) async {
    await _repository.deleteEmployee(id);
    await _loadEmployees();
  }

  Future<List<AttendanceEntry>> getAttendance(String employeeId) async {
    if (!_attendanceData.containsKey(employeeId)) {
      _attendanceData[employeeId] = await _repository.getAttendance(employeeId);
    }
    return _attendanceData[employeeId]!;
  }

  Future<void> markAttendance(AttendanceEntry entry) async {
    final existing = await _repository.getAttendance(entry.employeeId);
    final index = existing.indexWhere((e) => 
      e.date.year == entry.date.year && 
      e.date.month == entry.date.month && 
      e.date.day == entry.date.day
    );

    if (index != -1) {
      final old = existing[index];
      // Merge: only replace non-null values or use the new values
      final updated = AttendanceEntry(
        id: old.id,
        employeeId: old.employeeId,
        date: old.date,
        status: entry.status, 
        checkInTime: entry.checkInTime ?? old.checkInTime,
        checkOutTime: entry.checkOutTime ?? old.checkOutTime,
        lateTime: entry.lateTime ?? old.lateTime,
        earlyTime: entry.earlyTime ?? old.earlyTime,
        amountGiven: old.amountGiven + entry.amountGiven,
        paymentDescription: (old.paymentDescription != null && old.paymentDescription!.isNotEmpty)
            ? (entry.paymentDescription != null && entry.paymentDescription!.isNotEmpty)
                ? '${old.paymentDescription}, ${entry.paymentDescription}'
                : old.paymentDescription
            : entry.paymentDescription,
      );
      await _repository.updateAttendance(updated);
    } else {
      await _repository.saveAttendance(entry);
    }
    
    _attendanceData.remove(entry.employeeId); // Force reload
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _repository.clearAll();
    _employees = [];
    _attendanceData = {};
    notifyListeners();
  }
}
