import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class TreatmentPlanService {
  Future<String?> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      'access_token',
    );
  }

  Future<Map<String, dynamic>>
      startTreatmentPlan({
    required int diagnosisId,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/diagnoses/'
      '$diagnosisId/treatment-plan/start',
    );

    print('');
    print('========================');
    print('START TREATMENT PLAN');
    print('DIAGNOSIS ID: $diagnosisId');
    print('URL: $url');
    print('========================');

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
      body: jsonEncode({}),
    );

    print(
      'START TREATMENT STATUS: ${response.statusCode}',
    );

    print(
      'START TREATMENT RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Start treatment plan failed '
      '(${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>>
      answerQuestion({
    required int diagnosisId,
    required String questionId,
    required String answer,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/diagnoses/'
      '$diagnosisId/treatment-plan/answer',
    );

    print('');
    print('========================');
    print('ANSWER KBS QUESTION');
    print('QUESTION ID: $questionId');
    print('ANSWER: $answer');
    print('========================');

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
        'question_id': questionId,
        'answer': answer,
      }),
    );

    print(
      'ANSWER STATUS: ${response.statusCode}',
    );

    print(
      'ANSWER RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Answer question failed '
      '(${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>>
      reviewTreatmentPlan({
    required int treatmentPlanId,
    required String status,
    String? doctorNotes,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    if (status != 'approved' &&
        status != 'rejected') {
      throw Exception(
        'Status must be approved or rejected',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'treatment-plans/$treatmentPlanId/review',
    );

    print('');
    print('========================');
    print('REVIEW TREATMENT PLAN');
    print(
      'TREATMENT PLAN ID: $treatmentPlanId',
    );
    print('STATUS: $status');
    print('URL: $url');
    print('========================');

    final response = await http.patch(
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
        'status': status,
        'doctor_notes':
            doctorNotes ??
                (status == 'approved'
                    ? 'Approved by doctor.'
                    : 'Rejected by doctor.'),
      }),
    );

    print(
      'REVIEW STATUS CODE: ${response.statusCode}',
    );

    print(
      'REVIEW RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Treatment plan review failed '
      '(${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>>
      editTreatmentPlanItems({
    required int treatmentPlanId,
    required List<Map<String, dynamic>> items,
    String? doctorNotes,
  }) async {
    final token = await _getToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    if (items.isEmpty) {
      throw Exception(
        'Treatment plan must contain at least one item.',
      );
    }

    final url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'treatment-plans/$treatmentPlanId',
    );

    final body = {
      'items': items
          .map(
            (item) => {
              'item_type':
                  item['item_type']?.toString() ??
                      'lifestyle',
              'content':
                  item['content']?.toString() ??
                      '',
            },
          )
          .toList(),
      'doctor_notes':
          doctorNotes ?? 'Edited by doctor.',
    };

    print('');
    print('========================');
    print('EDIT TREATMENT PLAN');
    print(
      'TREATMENT PLAN ID: $treatmentPlanId',
    );
    print('URL: $url');
    print('BODY: $body');
    print('========================');

    final response = await http.put(
      url,
      headers: {
        'Content-Type':
            'application/json',
        'Accept':
            'application/json',
        'Authorization':
            'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print(
      'EDIT TREATMENT PLAN STATUS: '
      '${response.statusCode}',
    );

    print(
      'EDIT TREATMENT PLAN RESPONSE: '
      '${response.body}',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    }

    String message = response.body;

    try {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map &&
          decoded['message'] != null) {
        message =
            decoded['message'].toString();
      }
    } catch (_) {}

    throw Exception(
      'Edit treatment plan failed '
      '(${response.statusCode}): $message',
    );
  }

}
