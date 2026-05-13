import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import 'employee_repository.dart';

class LocalEmployeeRepository implements EmployeeRepository {
  static const String _employeeKey = 'employees';
  static const String _attendanceKey = 'attendance';

  @override
  Future<List<Employee>> getEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_employeeKey);
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => Employee.fromMap(item)).toList();
  }

  @override
  Future<void> saveEmployee(Employee employee) async {
    final list = await getEmployees();
    list.add(employee);
    await _saveEmployees(list);
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    final list = await getEmployees();
    final index = list.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      list[index] = employee;
      await _saveEmployees(list);
    }
  }

  @override
  Future<void> deleteEmployee(String id) async {
    final list = await getEmployees();
    list.removeWhere((e) => e.id == id);
    await _saveEmployees(list);
  }

  @override
  Future<List<AttendanceEntry>> getAttendance(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('${_attendanceKey}_$employeeId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => AttendanceEntry.fromMap(item)).toList();
  }

  @override
  Future<void> saveAttendance(AttendanceEntry entry) async {
    final list = await getAttendance(entry.employeeId);
    list.add(entry);
    await _saveAttendance(entry.employeeId, list);
  }

  @override
  Future<void> updateAttendance(AttendanceEntry entry) async {
    final list = await getAttendance(entry.employeeId);
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      list[index] = entry;
      await _saveAttendance(entry.employeeId, list);
    }
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final employees = await getEmployees();
    for (var emp in employees) {
      await prefs.remove('${_attendanceKey}_${emp.id}');
    }
    await prefs.remove(_employeeKey);
  }

  Future<void> _saveEmployees(List<Employee> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString(_employeeKey, encoded);
  }

  Future<void> _saveAttendance(String empId, List<AttendanceEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString('${_attendanceKey}_$empId', encoded);
  }
}
