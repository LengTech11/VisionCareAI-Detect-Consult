import 'package:disease_detector_app/api_service/api/clinic_api.dart';
import 'package:disease_detector_app/model/clinic/clinic_model.dart';
import 'package:disease_detector_app/model/clinic/list_clinic_model.dart';
import 'package:flutter/foundation.dart';

class ClinicProvider extends ChangeNotifier {
  ListClinicModel? listClinic;
  ClinicModel? clinic;

  Future<void> fetchListClinics() async {
    final response = await ClinicApiService().getClinicList();
    listClinic = response;
    notifyListeners();
  }

  Future<void> fetchClinicById(int id) async {
    final response = await ClinicApiService().getClinicById(id);
    clinic = response;
    notifyListeners();
  }
}
