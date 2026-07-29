import '../models/appliance_model.dart';

abstract class ApplianceRepository {
  Future<List<Appliance>> getAppliances();
  Future<void> saveAppliance(Appliance appliance);
  Future<void> deleteAppliance(String id);

  Future<List<ServiceRecord>> getServiceRecords(String applianceId);
  Future<void> saveServiceRecord(ServiceRecord record);
  Future<void> deleteServiceRecord(String recordId);
}
