import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class PatientTreatmentPlanService {
  Future<String> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? token =
        prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    return token;
  }

  Map<String, String> _headers(
    String token,
  ) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>?>
      getApprovedTreatmentPlan({
    required int patientId,
  }) async {
    final token = await _getToken();

    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'patients/$patientId/treatment-plan',
    );

    print('');
    print('====================================');
    print('GET APPROVED PATIENT TREATMENT PLAN');
    print('PATIENT ID: $patientId');
    print('URL: $url');
    print('====================================');

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    print(
      'TREATMENT PLAN STATUS: '
      '${response.statusCode}',
    );

    print(
      'TREATMENT PLAN RESPONSE: '
      '${response.body}',
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load treatment plan '
        '(${response.statusCode})',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid treatment plan response.',
      );
    }

    final Map<String, dynamic> root =
        Map<String, dynamic>.from(
      decoded,
    );

    final dynamic data = root['data'];

    if (data is Map) {
      final dataMap =
          Map<String, dynamic>.from(data);

      if (dataMap['treatment_plan'] is Map) {
        return Map<String, dynamic>.from(
          dataMap['treatment_plan'],
        );
      }

      if (dataMap['id'] != null) {
        return dataMap;
      }
    }

    if (root['treatment_plan'] is Map) {
      return Map<String, dynamic>.from(
        root['treatment_plan'],
      );
    }

    if (root['id'] != null) {
      return root;
    }

    return null;
  }
}
