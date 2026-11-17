import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class DiagnosisTreatmentPlanService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final token =
        prefs.getString('access_token') ??
        prefs.getString('token') ??
        prefs.getString('auth_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('Access token not found.');
    }

    return token;
  }

  Future<int?> getSavedDiagnosisId() async {
    final prefs = await SharedPreferences.getInstance();

    final intValue =
        prefs.getInt('latest_diagnosis_id');

    if (intValue != null) {
      return intValue;
    }

    return int.tryParse(
      prefs.getString('latest_diagnosis_id') ?? '',
    );
  }

  Future<Map<String, dynamic>?> getTreatmentPlanByDiagnosis({
    required int diagnosisId,
  }) async {
    final token = await _getToken();

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'diagnoses/$diagnosisId/treatment-plan',
    );

    print('');
    print('====================================');
    print('GET TREATMENT PLAN BY DIAGNOSIS');
    print('DIAGNOSIS ID: $diagnosisId');
    print('URL: $url');
    print('====================================');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print(
      'TREATMENT PLAN STATUS: ${response.statusCode}',
    );
    print(
      'TREATMENT PLAN RESPONSE: ${response.body}',
    );

    dynamic decoded;

    if (response.body.trim().isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode == 200) {
      if (decoded is Map) {
        final dynamic data = decoded['data'];

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }

        if (decoded['id'] != null ||
            decoded['items'] != null ||
            decoded['status'] != null) {
          return Map<String, dynamic>.from(decoded);
        }
      }

      return null;
    }

    if (response.statusCode == 404) {
      return null;
    }

    String message =
        'Failed to load treatment plan '
        '(${response.statusCode}).';

    if (decoded is Map &&
        decoded['message'] != null) {
      message = decoded['message'].toString();
    }

    throw Exception(message);
  }
}
