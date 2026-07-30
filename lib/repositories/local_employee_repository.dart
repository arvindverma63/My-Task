import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import 'employee_repository.dart';

class LocalEmployeeRepository implements EmployeeRepository {
  static const String _employeeKey = 'employees';
  static const String _attendanceKey = 'attendance';
  
  static const String _workersKey = 'ironing_workers';
  static const String _ratesKey = 'iron_rates';
  static const String _recordsKey = 'iron_records';
  static const String _paymentsKey = 'iron_payments';

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
  Future<void> deleteAttendance(String employeeId, String entryId) async {
    final list = await getAttendance(employeeId);
    list.removeWhere((e) => e.id == entryId);
    await _saveAttendance(employeeId, list);
  }

  @override
  Future<List<IroningWorker>> getIroningWorkers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_workersKey);
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => IroningWorker.fromMap(item)).toList();
  }

  @override
  Future<void> saveIroningWorker(IroningWorker worker) async {
    final list = await getIroningWorkers();
    list.add(worker);
    await _saveIroningWorkers(list);
  }

  @override
  Future<void> deleteIroningWorker(String id) async {
    final list = await getIroningWorkers();
    list.removeWhere((w) => w.id == id);
    await _saveIroningWorkers(list);
  }

  Future<void> _saveIroningWorkers(List<IroningWorker> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString(_workersKey, encoded);
  }

  @override
  Future<List<IronRate>> getIronRates(String workerId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('${_ratesKey}_$workerId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => IronRate.fromMap(item)).toList();
  }

  @override
  Future<void> saveIronRate(String workerId, IronRate rate) async {
    final list = await getIronRates(workerId);
    list.add(rate);
    await _saveIronRates(workerId, list);
  }

  @override
  Future<void> updateIronRate(String workerId, IronRate rate) async {
    final list = await getIronRates(workerId);
    final index = list.indexWhere((e) => e.id == rate.id);
    if (index != -1) {
      list[index] = rate;
      await _saveIronRates(workerId, list);
    }
  }

  Future<void> _saveIronRates(String workerId, List<IronRate> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString('${_ratesKey}_$workerId', encoded);
  }

  @override
  Future<List<IroningRecord>> getIroningRecords(String workerId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('${_recordsKey}_$workerId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => IroningRecord.fromMap(item)).toList();
  }

  @override
  Future<void> saveIroningRecord(String workerId, IroningRecord record) async {
    final list = await getIroningRecords(workerId);
    list.add(record);
    await _saveIroningRecords(workerId, list);
  }

  @override
  Future<void> updateIroningRecord(String workerId, IroningRecord record) async {
    final list = await getIroningRecords(workerId);
    final index = list.indexWhere((e) => e.id == record.id);
    if (index != -1) {
      list[index] = record;
      await _saveIroningRecords(workerId, list);
    }
  }

  Future<void> _saveIroningRecords(String workerId, List<IroningRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString('${_recordsKey}_$workerId', encoded);
  }

  @override
  Future<List<IroningPayment>> getIroningPayments(String workerId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('${_paymentsKey}_$workerId');
    if (jsonStr == null) return [];
    final List<dynamic> decoded = json.decode(jsonStr);
    return decoded.map((item) => IroningPayment.fromMap(item)).toList();
  }

  @override
  Future<void> saveIroningPayment(String workerId, IroningPayment payment) async {
    final list = await getIroningPayments(workerId);
    list.add(payment);
    await _saveIroningPayments(workerId, list);
  }

  @override
  Future<void> updateIroningPayment(String workerId, IroningPayment payment) async {
    final list = await getIroningPayments(workerId);
    final index = list.indexWhere((e) => e.id == payment.id);
    if (index != -1) {
      list[index] = payment;
      await _saveIroningPayments(workerId, list);
    }
  }

  Future<void> _saveIroningPayments(String workerId, List<IroningPayment> list) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(list.map((e) => e.toMap()).toList());
    await prefs.setString('${_paymentsKey}_$workerId', encoded);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear Employee Attendance Data
    final employees = await getEmployees();
    for (var emp in employees) {
      await prefs.remove('${_attendanceKey}_${emp.id}');
    }
    await prefs.remove(_employeeKey);

    // Clear Ironing Workers Data
    final workers = await getIroningWorkers();
    for (var w in workers) {
      await prefs.remove('${_ratesKey}_${w.id}');
      await prefs.remove('${_recordsKey}_${w.id}');
      await prefs.remove('${_paymentsKey}_${w.id}');
    }
    await prefs.remove(_workersKey);
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
