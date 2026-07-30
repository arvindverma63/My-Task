import '../models/employee_model.dart';
import '../models/ironing_model.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees();
  Future<void> saveEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String id);
  
  Future<List<AttendanceEntry>> getAttendance(String employeeId);
  Future<void> saveAttendance(AttendanceEntry entry);
  Future<void> updateAttendance(AttendanceEntry entry);
  Future<void> deleteAttendance(String employeeId, String entryId);

  Future<List<IroningWorker>> getIroningWorkers();
  Future<void> saveIroningWorker(IroningWorker worker);
  Future<void> deleteIroningWorker(String id);

  Future<List<IronRate>> getIronRates(String workerId);
  Future<void> saveIronRate(String workerId, IronRate rate);
  Future<void> updateIronRate(String workerId, IronRate rate);
  
  Future<List<IroningRecord>> getIroningRecords(String workerId);
  Future<void> saveIroningRecord(String workerId, IroningRecord record);
  Future<void> updateIroningRecord(String workerId, IroningRecord record);
  
  Future<List<IroningPayment>> getIroningPayments(String workerId);
  Future<void> saveIroningPayment(String workerId, IroningPayment payment);
  Future<void> updateIroningPayment(String workerId, IroningPayment payment);
  
  Future<void> clearAll();
}
