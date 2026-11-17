import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class ReportService {
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

  Future<List<Map<String, dynamic>>>
      getPatientReports({
    required int patientId,
  }) async {
    final token = await _getToken();

    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'patients/$patientId/reports',
    );

    print('');
    print('====================================');
    print('GET PATIENT REPORTS');
    print('PATIENT ID: $patientId');
    print('URL: $url');
    print('====================================');

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    print(
      'PATIENT REPORTS STATUS: '
      '${response.statusCode}',
    );

    print(
      'PATIENT REPORTS RESPONSE: '
      '${response.body}',
    );

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load patient reports '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    return _extractReports(decoded);
  }

  List<Map<String, dynamic>> _extractReports(
    dynamic value,
  ) {
    final List<Map<String, dynamic>> result = [];

    if (value == null) {
      return result;
    }

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      return result;
    }

    if (value is! Map) {
      return result;
    }

    final dynamic data = value['data'];

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      return result;
    }

    if (data is Map) {
      final dynamic nestedData =
          data['data'];

      if (nestedData is List) {
        for (final item in nestedData) {
          if (item is Map) {
            result.add(
              Map<String, dynamic>.from(item),
            );
          }
        }

        return result;
      }

      final dynamic reports =
          data['reports'];

      if (reports is List) {
        for (final item in reports) {
          if (item is Map) {
            result.add(
              Map<String, dynamic>.from(item),
            );
          }
        }

        return result;
      }

      if (data['id'] != null) {
        result.add(
          Map<String, dynamic>.from(data),
        );
      }

      return result;
    }

    final dynamic reports =
        value['reports'];

    if (reports is List) {
      for (final item in reports) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    return result;
  }
}
