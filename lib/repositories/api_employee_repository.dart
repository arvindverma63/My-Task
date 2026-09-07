import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../utils/session_manager.dart';
import 'employee_repository.dart';

class ApiEmployeeRepository implements EmployeeRepository {
  static const String _baseUrl = 'https://slateblue-guanaco-751834.hostingersite.com';

  Future<Map<String, String>> _getHeaders() async {
    final userId = await SessionManager().getUserId();
    final headers = {'Content-Type': 'application/json'};
    if (userId != null) {
      headers['X-User-Id'] = userId;
    }
    return headers;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      try {
        final err = json.decode(response.body);
        SessionManager().handleUnauthorized(err['error'] ?? 'Your session is no longer active. Please sign in.');
      } catch (_) {
        SessionManager().handleUnauthorized('Your session has ended or this account was removed.');
      }
    }
  }

  Future<String?> _uploadIfLocal(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('uploads/') || path.startsWith('http')) return path;

    try {
      final url = Uri.parse('$_baseUrl/api/upload');
      final request = http.MultipartRequest('POST', url);
      final userId = await SessionManager().getUserId();
      if (userId != null) {
        request.headers['X-User-Id'] = userId;
      }
      request.files.add(await http.MultipartFile.fromPath('file', path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = json.decode(resBody);
        return data['path'];
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        SessionManager().handleUnauthorized('Session expired or account removed.');
      }
    } catch (e) {
      // Log error
    }
    return path;
  }

  @override
  Future<List<Employee>> getEmployees() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/employees'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => Employee.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveEmployee(Employee employee) async {
    try {
      final photo = await _uploadIfLocal(employee.photoPath);
      final updated = Employee(
        id: employee.id,
        name: employee.name,
        contact: employee.contact,
        photoPath: photo,
        joiningDate: employee.joiningDate,
        relievingDate: employee.relievingDate,
        baseSalary: employee.baseSalary,
        salaryBasis: employee.salaryBasis,
      );

      final current = await getEmployees();
      final exists = current.any((e) => e.id == employee.id);
      final headers = await _getHeaders();

      final response = exists
          ? await http.put(
              Uri.parse('$_baseUrl/api/employees/${employee.id}'),
              headers: headers,
              body: json.encode(updated.toMap()),
            )
          : await http.post(
              Uri.parse('$_baseUrl/api/employees'),
              headers: headers,
              body: json.encode(updated.toMap()),
            );

      _checkResponse(response);

      if (response.statusCode != 200 && response.statusCode != 201) {
        try {
          final errData = json.decode(response.body);
          throw Exception(errData['error'] ?? 'Server error (${response.statusCode})');
        } catch (_) {
          throw Exception('Server error (${response.statusCode})');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await saveEmployee(employee);
  }

  @override
  Future<void> deleteEmployee(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/employees/$id'),
        headers: headers,
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<List<AttendanceEntry>> getAttendance(String employeeId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/attendance?employeeId=$employeeId'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => AttendanceEntry.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveAttendance(AttendanceEntry entry) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/attendance'),
        headers: headers,
        body: json.encode(entry.toMap()),
      );
      _checkResponse(response);
      if (response.statusCode != 200 && response.statusCode != 201) {
        // If save failed (e.g., duplicate key in DB), delete existing and retry
        await deleteAttendance(entry.employeeId, entry.id);
        final retryRes = await http.post(
          Uri.parse('$_baseUrl/api/attendance'),
          headers: headers,
          body: json.encode(entry.toMap()),
        );
        _checkResponse(retryRes);
      }
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> updateAttendance(AttendanceEntry entry) async {
    try {
      final headers = await _getHeaders();
      final delRes = await http.delete(
        Uri.parse('$_baseUrl/api/attendance/${entry.id}'),
        headers: headers,
      );
      _checkResponse(delRes);
      final postRes = await http.post(
        Uri.parse('$_baseUrl/api/attendance'),
        headers: headers,
        body: json.encode(entry.toMap()),
      );
      _checkResponse(postRes);
    } catch (e) {
      await saveAttendance(entry);
    }
  }

  @override
  Future<void> deleteAttendance(String employeeId, String entryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/attendance/$entryId'),
        headers: headers,
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<List<IroningWorker>> getIroningWorkers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ironing-workers'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => IroningWorker.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveIroningWorker(IroningWorker worker) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ironing-workers'),
        headers: headers,
        body: json.encode(worker.toMap()),
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> deleteIroningWorker(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/ironing-workers/$id'),
        headers: headers,
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<List<IronRate>> getIronRates(String workerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ironing-workers/$workerId/rates'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => IronRate.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveIronRate(String workerId, IronRate rate) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ironing-workers/$workerId/rates'),
        headers: headers,
        body: json.encode(rate.toMap()),
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> updateIronRate(String workerId, IronRate rate) async {
    await saveIronRate(workerId, rate);
  }

  @override
  Future<List<IroningRecord>> getIroningRecords(String workerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ironing-records?workerId=$workerId'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => IroningRecord.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveIroningRecord(String workerId, IroningRecord record) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ironing-records'),
        headers: headers,
        body: json.encode(record.toMap()),
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> updateIroningRecord(String workerId, IroningRecord record) async {
    await saveIroningRecord(workerId, record);
  }

  @override
  Future<List<IroningPayment>> getIroningPayments(String workerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/ironing-payments?workerId=$workerId'),
        headers: headers,
      );
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => IroningPayment.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveIroningPayment(String workerId, IroningPayment payment) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ironing-payments'),
        headers: headers,
        body: json.encode(payment.toMap()),
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> updateIroningPayment(String workerId, IroningPayment payment) async {
    await saveIroningPayment(workerId, payment);
  }

  @override
  Future<void> clearAll() async {
    // No-op for remote database clearing
  }
}
