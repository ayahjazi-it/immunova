import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:immunova/model/get_all_patients.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immunova/const.dart';

class PatientService {
  Future<get_all_Patient_model?> getPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token =
          prefs.getString('access_token');

      if (token == null || token.isEmpty) {

        return null;
      }

      final Uri url = Uri.parse(
        'http://$localhost:8000/api/v1/patients',
      );


      print('URL: $url');
      print('TOKEN: $token');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(response.body);

        final get_all_Patient_model patients =
            get_all_Patient_model.fromJson(
          json,
        );

        print(
          'COUNT: ${patients.data?.length ?? 0}',
        );

        return patients;
      }

      if (response.statusCode == 401) {
        print('UNAUTHORIZED TOKEN');

        return null;
      }

      print('FAILED TO GET PATIENTS');
      print('STATUS CODE: ${response.statusCode}');
      print('BODY: ${response.body}');

      return null;
    } catch (e, stackTrace) {

      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');


      return null;
    }
  }

  // DELETE PATIENT


  Future<bool> deletePatient(int patientId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token =
          prefs.getString('access_token');

      if (token == null || token.isEmpty) {

        return false;
      }

      final Uri url = Uri.parse(
        'http://$localhost:8000/api/v1/patients/$patientId',
      );

      print('PATIENT ID: $patientId');
      print('URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');


      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        print('PATIENT ID: $patientId');

        return true;
      }

      print('STATUS CODE: ${response.statusCode}');
      print('BODY: ${response.body}');

      return false;
    } catch (e, stackTrace) {
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');

      return false;
    }
  }
}