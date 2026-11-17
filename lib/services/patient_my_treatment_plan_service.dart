import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class PatientMyTreatmentPlanService {
  // =========================================================
  // READ THE TOKEN SAVED BY LOGIN
  // =========================================================

  Future<String> _getToken() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? token =
        prefs.getString('access_token');

    if (token == null || token.trim().isEmpty) {
      throw Exception('Access token not found.');
    }

    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // =========================================================
  // RESOLVE THE LOGGED-IN PATIENT PROFILE ID
  // GET /api/v1/me
  //
  // Important:
  // We do NOT use user.id.
  // We use:
  // data.user.patient_profile.id
  // =========================================================

  Future<int> _getCurrentPatientProfileId(
    String token,
  ) async {
    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/me',
    );

    print('');
    print('====================================');
    print('GET CURRENT LOGGED-IN PATIENT');
    print('URL: $url');
    print('====================================');

    final http.Response response = await http.get(
      url,
      headers: _headers(token),
    );

    print('ME STATUS: ${response.statusCode}');
    print('ME RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load current patient '
        '(${response.statusCode}).',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid /me response.');
    }

    final Map<String, dynamic> root =
        Map<String, dynamic>.from(decoded);

    final dynamic rawData = root['data'];

    if (rawData is! Map) {
      throw Exception(
        'Current user data was not returned.',
      );
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(rawData);

    final dynamic rawUser = data['user'];

    if (rawUser is! Map) {
      throw Exception(
        'Current user was not returned.',
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(rawUser);

    final String role =
        user['role']?.toString().toLowerCase() ?? '';

    if (role != 'patient') {
      throw Exception(
        'The logged-in account is not a patient.',
      );
    }

    final dynamic rawPatientProfile =
        user['patient_profile'];

    if (rawPatientProfile is! Map) {
      throw Exception(
        'Patient profile was not returned from /me.',
      );
    }

    final Map<String, dynamic> patientProfile =
        Map<String, dynamic>.from(rawPatientProfile);

    final int? patientProfileId =
        int.tryParse(
      patientProfile['id']?.toString() ?? '',
    );

    if (patientProfileId == null) {
      throw Exception(
        'Patient profile ID was not returned from /me.',
      );
    }

    print('');
    print('====================================');
    print('CURRENT PATIENT RESOLVED');
    print('USER ID: ${user['id']}');
    print(
      'PATIENT PROFILE ID: $patientProfileId',
    );
    print('====================================');

    return patientProfileId;
  }

  // =========================================================
  // GET LOGGED-IN PATIENT APPROVED TREATMENT PLAN
  //
  // 1) Read access_token.
  // 2) GET /me.
  // 3) Read patient_profile.id.
  // 4) GET /patients/{patientProfileId}/treatment-plan.
  //
  // A 404 means there is currently no approved plan.
  // =========================================================

  Future<Map<String, dynamic>?>
      getMyApprovedTreatmentPlan() async {
    final String token = await _getToken();

    final int patientProfileId =
        await _getCurrentPatientProfileId(
      token,
    );

    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'patients/$patientProfileId/treatment-plan',
    );

    print('');
    print('====================================');
    print('GET MY APPROVED TREATMENT PLAN');
    print(
      'PATIENT PROFILE ID: $patientProfileId',
    );
    print('URL: $url');
    print('====================================');

    final http.Response response = await http.get(
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
      // The screen will show:
      // "No approved treatment plan"
      return null;
    }

    if (response.statusCode != 200) {
      String message =
          'Failed to load treatment plan '
          '(${response.statusCode}).';

      try {
        final dynamic errorDecoded =
            jsonDecode(response.body);

        if (errorDecoded is Map &&
            errorDecoded['message'] != null) {
          message =
              errorDecoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid treatment plan response.',
      );
    }

    final Map<String, dynamic> root =
        Map<String, dynamic>.from(decoded);

    // Common Laravel response:
    // {
    //   "success": true,
    //   "data": {
    //     "id": ...,
    //     "status": "approved",
    //     "items": [...]
    //   }
    // }
    final dynamic rawData = root['data'];

    if (rawData is Map) {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(rawData);

      // Some endpoints may wrap it one level deeper:
      // data: { treatment_plan: {...} }
      final dynamic nestedPlan =
          data['treatment_plan'];

      if (nestedPlan is Map) {
        return Map<String, dynamic>.from(
          nestedPlan,
        );
      }

      if (data['id'] != null ||
          data['items'] is List ||
          data['status'] != null) {
        return data;
      }
    }

    // Fallback:
    // {
    //   "treatment_plan": {...}
    // }
    final dynamic rootPlan =
        root['treatment_plan'];

    if (rootPlan is Map) {
      return Map<String, dynamic>.from(
        rootPlan,
      );
    }

    // Fallback:
    // direct treatment-plan object.
    if (root['id'] != null ||
        root['items'] is List ||
        root['status'] != null) {
      return root;
    }

    return null;
  }
}
