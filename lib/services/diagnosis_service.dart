import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class DiagnosisService {
  Future<String?> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>> confirmDiagnosis({
    required int analysisId,
    required int predictionId,
    required int diseaseId,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Access token not found');
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/analyses/'
      '$analysisId/diagnosis/confirm',
    );

    print('');
    print('========================');
    print('CONFIRM DIAGNOSIS');
    print('URL: $url');
    print('ANALYSIS ID: $analysisId');
    print('PREDICTION ID: $predictionId');
    print('DISEASE ID: $diseaseId');
    print('========================');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prediction_id': predictionId,
        'disease_id': diseaseId,
        'status': 'confirmed',
        'doctor_notes': 'Confirmed from Flutter',
      }),
    );

    print(
      'CONFIRM DIAGNOSIS STATUS: ${response.statusCode}',
    );

    print(
      'CONFIRM DIAGNOSIS RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Confirm diagnosis failed '
      '(${response.statusCode}): ${response.body}',
    );
  }
}