import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class AnalysisService {
  Future<String?> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'access_token',
    );
  }

  Future<Map<String, dynamic>>
      createAnalysis({
    required int patientId,
    required Map<String, dynamic> markers,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/analyses',
    );

    print('');
    print('==========================');
    print('CREATE ANALYSIS');
    print('URL: $url');
    print('PATIENT ID: $patientId');
    print('MARKERS: $markers');
    print('==========================');

    final response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json',
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode({
        'patient_id':
            patientId,
        'input_method':
            'manual',
        ...markers,
      }),
    );

    print(
      'CREATE ANALYSIS STATUS: ${response.statusCode}',
    );

    print(
      'CREATE ANALYSIS RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid create analysis response',
      );
    }

    throw Exception(
      'Create analysis failed (${response.statusCode}): ${response.body}',
    );
  }

  Future<Map<String, dynamic>>
      runPrediction({
    required int analysisId,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/analyses/$analysisId/predict',
    );

    print('');
    print('==========================');
    print('RUN PREDICTION');
    print('URL: $url');
    print('ANALYSIS ID: $analysisId');
    print('==========================');

    final response = await http.post(
      url,
      headers: {
        'Content-Type':
            'application/json',
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },

      // الـ API تبعك ما بيحتاج
      // قيم هون لأن القيم محفوظة
      // مسبقاً ضمن Analysis.
      body: jsonEncode({}),
    );

    print(
      'PREDICTION STATUS: ${response.statusCode}',
    );

    print(
      'PREDICTION RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final decoded =
          jsonDecode(
        response.body,
      );

      if (decoded
          is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid prediction response',
      );
    }

    throw Exception(
      'Prediction failed (${response.statusCode}): ${response.body}',
    );
  }
}