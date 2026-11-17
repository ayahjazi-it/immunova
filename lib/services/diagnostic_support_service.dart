import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DiagnosticSupportService {
  static const String baseUrl =
      'http://192.168.43.155:8000/api/v1';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token') ??
        prefs.getString('auth_token') ??
        prefs.getString('access_token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // START DIAGNOSTIC SUPPORT
  // POST
  // /analyses/{analysisId}/predictions/{predictionId}
  // /diagnostic-support/start
  // =========================================================
  Future<Map<String, dynamic>> startDiagnosticSupport({
    required int analysisId,
    required int predictionId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/analyses/$analysisId/'
      'predictions/$predictionId/'
      'diagnostic-support/start',
    );

    print('');
    print('======================================');
    print('START DIAGNOSTIC SUPPORT');
    print('URL: $url');
    print('Analysis ID: $analysisId');
    print('Prediction ID: $predictionId');
    print('======================================');

    final response = await http.post(
      url,
      headers: await _headers(),
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Failed to start diagnostic support '
                '(${response.statusCode})',
      );
    }

    return body;
  }

  // =========================================================
  // ANSWER QUESTION
  // POST
  // /analyses/{analysisId}/predictions/{predictionId}
  // /diagnostic-support/answer
  // =========================================================
  Future<Map<String, dynamic>> answerQuestion({
    required int analysisId,
    required int predictionId,
    required String questionId,
    required String answer,
  }) async {
    final url = Uri.parse(
      '$baseUrl/analyses/$analysisId/'
      'predictions/$predictionId/'
      'diagnostic-support/answer',
    );

    final requestBody = {
      'question_id': questionId,
      'answer': answer,
    };

    print('');
    print('======================================');
    print('ANSWER DIAGNOSTIC QUESTION');
    print('URL: $url');
    print('Analysis ID: $analysisId');
    print('Prediction ID: $predictionId');
    print('BODY: $requestBody');
    print('======================================');

    final response = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(requestBody),
    );

    print('STATUS: ${response.statusCode}');
    print('BODY: ${response.body}');

    Map<String, dynamic> body = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body['message'] ??
            'Failed to answer diagnostic question '
                '(${response.statusCode})',
      );
    }

    return body;
  }
}