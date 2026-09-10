import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appliance_model.dart';
import '../utils/session_manager.dart';
import 'appliance_repository.dart';

class ApiApplianceRepository implements ApplianceRepository {
  static const String _baseUrl = 'https://slateblue-guanaco-751834.hostingersite.com';

  Future<Uri> _buildUri(String path, [Map<String, String>? queryParams]) async {
    final userId = await SessionManager().getUserId();
    final params = <String, String>{};
    if (queryParams != null) {
      params.addAll(queryParams);
    }
    if (userId != null && userId.isNotEmpty) {
      params['userId'] = userId;
    }
    final uri = Uri.parse('$_baseUrl$path');
    if (params.isEmpty) return uri;
    return uri.replace(queryParameters: params);
  }

  Future<Map<String, String>> _getHeaders() async {
    final userId = await SessionManager().getUserId();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (userId != null && userId.isNotEmpty) {
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
      final userId = await SessionManager().getUserId();
      final url = await _buildUri('/api/upload');
      final request = http.MultipartRequest('POST', url);
      if (userId != null && userId.isNotEmpty) {
        request.headers['X-User-Id'] = userId;
        request.fields['userId'] = userId;
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
  Future<List<Appliance>> getAppliances() async {
    try {
      final userId = await SessionManager().getUserId();
      if (userId == null || userId.isEmpty) return [];

      final headers = await _getHeaders();
      final url = await _buildUri('/api/appliances');
      final response = await http.get(url, headers: headers);
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => Appliance.fromMap(item)).toList();
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveAppliance(Appliance appliance) async {
    try {
      final uploadedPath = await _uploadIfLocal(appliance.invoicePath);
      final updatedAppliance = Appliance(
        id: appliance.id,
        name: appliance.name,
        type: appliance.type,
        brand: appliance.brand,
        serialNumber: appliance.serialNumber,
        warrantyStart: appliance.warrantyStart,
        warrantyEnd: appliance.warrantyEnd,
        invoicePath: uploadedPath,
        createdAt: appliance.createdAt,
      );

      final currentList = await getAppliances();
      final exists = currentList.any((a) => a.id == appliance.id);
      final headers = await _getHeaders();

      final url = exists
          ? await _buildUri('/api/appliances/${appliance.id}')
          : await _buildUri('/api/appliances');

      final response = exists
          ? await http.put(
              url,
              headers: headers,
              body: json.encode(updatedAppliance.toMap()),
            )
          : await http.post(
              url,
              headers: headers,
              body: json.encode(updatedAppliance.toMap()),
            );

      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<void> deleteAppliance(String id) async {
    try {
      final headers = await _getHeaders();
      final url = await _buildUri('/api/appliances/$id');
      final response = await http.delete(url, headers: headers);
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  @override
  Future<List<ServiceRecord>> getServiceRecords(String applianceId) async {
    try {
      final userId = await SessionManager().getUserId();
      if (userId == null || userId.isEmpty) return [];

      final headers = await _getHeaders();
      final url = await _buildUri('/api/service-records', {'applianceId': applianceId});
      final response = await http.get(url, headers: headers);
      _checkResponse(response);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        final records = list.map((item) => ServiceRecord.fromMap(item)).toList();
        records.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
        return records;
      }
    } catch (e) {
      // Log error
    }
    return [];
  }

  @override
  Future<void> saveServiceRecord(ServiceRecord record) async {
    try {
      final uploadedPath = await _uploadIfLocal(record.billPath);
      final updatedRecord = ServiceRecord(
        id: record.id,
        applianceId: record.applianceId,
        serviceDate: record.serviceDate,
        price: record.price,
        remarks: record.remarks,
        billPath: uploadedPath,
        createdAt: record.createdAt,
      );

      final headers = await _getHeaders();
      final url = await _buildUri('/api/service-records');
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(updatedRecord.toMap()),
      );
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    await saveServiceRecord(record);
  }

  @override
  Future<void> deleteServiceRecord(String id) async {
    try {
      final headers = await _getHeaders();
      final url = await _buildUri('/api/service-records/$id');
      final response = await http.delete(url, headers: headers);
      _checkResponse(response);
    } catch (e) {
      // Log error
    }
  }

  Future<void> clearAll() async {
    // No-op for remote database clearing
  }
}
