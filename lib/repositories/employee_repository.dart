import '../models/employee_model.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<void> saveEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  
  Future<List<AttendanceEntry>> getAttendance(String employeeId);
  Future<void> saveAttendance(AttendanceEntry entry);
  Future<void> updateAttendance(AttendanceEntry entry);
  
  Future<void> clearAll();
}
