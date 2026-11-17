import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class PatientDetailsService {
  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Access token not found');
    }

    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getPatientClinicalData({
    required int patientId,
  }) async {
    final token = await _getToken();

    final List<Map<String, dynamic>> patientAnalyses = [];

    int page = 1;
    int lastPage = 1;

    do {
      final url = Uri.parse(
        'http://$localhost:8000/api/v1/analyses?page=$page',
      );

      print('');
      print('====================================');
      print('GET ANALYSES');
      print('PATIENT ID: $patientId');
      print('PAGE: $page');
      print('URL: $url');
      print('====================================');

      final response = await http.get(
        url,
        headers: _headers(token),
      );

      print('ANALYSES STATUS: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load analyses '
          '(${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('Invalid analyses response');
      }

      final data = decoded['data'];

      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;

          final analysis =
              Map<String, dynamic>.from(item);

          final rawPatient = analysis['patient'];

          if (rawPatient is Map) {
            final analysisPatientId =
                rawPatient['id'];

            if (analysisPatientId != null &&
                analysisPatientId.toString() ==
                    patientId.toString()) {
              patientAnalyses.add(analysis);
            }
          }
        }
      }

      final meta = decoded['meta'];

      if (meta is Map) {
        lastPage =
            int.tryParse(
              meta['last_page']?.toString() ?? '1',
            ) ??
            1;
      } else {
        final links = decoded['links'];

        if (links is Map) {
          final next = links['next'];

          lastPage =
              next == null ? page : page + 1;
        } else {
          lastPage = page;
        }
      }

      page++;
    } while (page <= lastPage);

    patientAnalyses.sort((a, b) {
      final aId =
          int.tryParse(a['id']?.toString() ?? '') ?? 0;

      final bId =
          int.tryParse(b['id']?.toString() ?? '') ?? 0;

      return bId.compareTo(aId);
    });

    final int? latestAnalysisId =
        patientAnalyses.isEmpty
            ? null
            : int.tryParse(
                patientAnalyses.first['id']
                        ?.toString() ??
                    '',
              );

    Map<String, dynamic>? latestPlan;
    Map<String, dynamic>? diagnosis;
    int? planAnalysisId;

    for (final analysis in patientAnalyses) {
      final analysisId =
          int.tryParse(
        analysis['id']?.toString() ?? '',
      );

      if (analysisId == null) {
        continue;
      }

      final diagnosisUrl = Uri.parse(
        'http://$localhost:8000/api/v1/analyses/'
        '$analysisId/diagnosis',
      );

      print('');
      print('CHECK ANALYSIS ID: $analysisId');
      print('GET DIAGNOSIS: $diagnosisUrl');

      final diagnosisResponse = await http.get(
        diagnosisUrl,
        headers: _headers(token),
      );

      print(
        'DIAGNOSIS STATUS CODE: '
        '${diagnosisResponse.statusCode}',
      );

      if (diagnosisResponse.statusCode == 404 ||
          diagnosisResponse.statusCode == 204) {
        continue;
      }

      if (diagnosisResponse.statusCode != 200) {
        continue;
      }

      final diagnosisDecoded =
          jsonDecode(diagnosisResponse.body);

      if (diagnosisDecoded is! Map) {
        continue;
      }

      final rawDiagnosis =
          diagnosisDecoded['data'];

      if (rawDiagnosis is! Map) {
        continue;
      }

      final currentDiagnosis =
          Map<String, dynamic>.from(
        rawDiagnosis,
      );

      final diagnosisStatus =
          currentDiagnosis['status']
                  ?.toString()
                  .toLowerCase() ??
              '';

      final diagnosisId =
          int.tryParse(
        currentDiagnosis['id']
                ?.toString() ??
            '',
      );

      if (diagnosisId == null ||
          diagnosisStatus == 'rejected') {
        continue;
      }

      final planUrl = Uri.parse(
        'http://$localhost:8000/api/v1/diagnoses/'
        '$diagnosisId/treatment-plan',
      );

      print('GET TREATMENT PLAN: $planUrl');

      final planResponse = await http.get(
        planUrl,
        headers: _headers(token),
      );

      print(
        'TREATMENT PLAN STATUS CODE: '
        '${planResponse.statusCode}',
      );

      if (planResponse.statusCode == 404 ||
          planResponse.statusCode == 204) {
        continue;
      }

      if (planResponse.statusCode != 200) {
        continue;
      }

      final planDecoded =
          jsonDecode(planResponse.body);

      if (planDecoded is! Map) {
        continue;
      }

      final rawPlan = planDecoded['data'];

      if (rawPlan is! Map) {
        continue;
      }

      final currentPlan =
          Map<String, dynamic>.from(
        rawPlan,
      );

      final planStatus =
          currentPlan['status']
                  ?.toString()
                  .toLowerCase() ??
              '';

      latestPlan = currentPlan;
      diagnosis = currentDiagnosis;
      planAnalysisId = analysisId;
      break;
    }

    print('');
    print('====================================');
    print('PATIENT CLINICAL DATA READY');
    print('PATIENT ID: $patientId');
    print('LATEST ANALYSIS ID: $latestAnalysisId');
    print('PLAN ANALYSIS ID: $planAnalysisId');
    print(
      'HAS TREATMENT PLAN: ${latestPlan != null}',
    );
    print('====================================');

    return {
      'latest_analysis_id': latestAnalysisId,
      'plan_analysis_id': planAnalysisId,
      'diagnosis': diagnosis,
      'treatment_plan': latestPlan,
    };
  }

  Future<Map<String, dynamic>> generateReport({
    required int analysisId,
  }) async {
    final token = await _getToken();

    final postUrl = Uri.parse(
      'http://$localhost:8000/api/v1/analyses/'
      '$analysisId/report',
    );

    print('');
    print('====================================');
    print('GENERATE REPORT');
    print('ANALYSIS ID: $analysisId');
    print('URL: $postUrl');
    print('====================================');

    final postResponse = await http.post(
      postUrl,
      headers: _headers(token),
      body: jsonEncode({}),
    );

    print(
      'GENERATE REPORT STATUS: '
      '${postResponse.statusCode}',
    );
    print(
      'GENERATE REPORT RESPONSE: '
      '${postResponse.body}',
    );

    if (postResponse.statusCode != 200 &&
        postResponse.statusCode != 201) {
      String message = postResponse.body;

      try {
        final decoded =
            jsonDecode(postResponse.body);

        if (decoded is Map &&
            decoded['message'] != null) {
          message =
              decoded['message'].toString();
        }
      } catch (_) {}

      throw Exception(
        'Generate report failed '
        '(${postResponse.statusCode}): $message',
      );
    }

    final postDecoded =
        jsonDecode(postResponse.body);

    if (postDecoded is! Map) {
      throw Exception('Invalid report response');
    }

    final rawPostData =
        postDecoded['data'];

    if (rawPostData is! Map) {
      throw Exception(
        'Report data was not returned',
      );
    }

    final postData =
        Map<String, dynamic>.from(
      rawPostData,
    );

    final reportId =
        int.tryParse(
      postData['id']?.toString() ?? '',
    );

    if (reportId == null) {
      return {
        'data': postData,
      };
    }

    final getUrl = Uri.parse(
      'http://$localhost:8000/api/v1/reports/'
      '$reportId',
    );

    final getResponse = await http.get(
      getUrl,
      headers: _headers(token),
    );

    print(
      'GET REPORT STATUS: '
      '${getResponse.statusCode}',
    );

    if (getResponse.statusCode == 200) {
      final getDecoded =
          jsonDecode(getResponse.body);

      if (getDecoded is Map &&
          getDecoded['data'] is Map) {
        final result =
            Map<String, dynamic>.from(
          getDecoded,
        );

        final dynamic rawReport =
            result['data'];

        if (rawReport is Map) {
          await _saveReportLocally(
            analysisId: analysisId,
            report:
                Map<String, dynamic>.from(
              rawReport,
            ),
          );
        }

        return result;
      }
    }

    await _saveReportLocally(
      analysisId: analysisId,
      report: postData,
    );

    return {
      'data': postData,
    };
  }

  Future<Map<String, dynamic>?> getApprovedTreatmentPlanForPatient({
    required int patientId,
  }) async {
    final result = await getPatientClinicalData(
      patientId: patientId,
    );

    final rawPlan = result['treatment_plan'];

    if (rawPlan is! Map) {
      return null;
    }

    return result;
  }


  Future<void> _saveReportLocally({
    required int analysisId,
    required Map<String, dynamic> report,
  }) async {
    final prefs =
        await SharedPreferences.getInstance();

    final int? reportId = int.tryParse(
      report['id']?.toString() ?? '',
    );

    if (reportId != null) {
      await prefs.setInt(
        'analysis_report_id_$analysisId',
        reportId,
      );
    }

    await prefs.setString(
      'analysis_report_json_$analysisId',
      jsonEncode(report),
    );

    print('');
    print('====================================');
    print('REPORT REFERENCE SAVED LOCALLY');
    print('ANALYSIS ID: $analysisId');
    print('REPORT ID: $reportId');
    print('====================================');
  }

  Future<Map<String, dynamic>?> getLatestReportForAnalysis({
    required int analysisId,
  }) async {
    final token = await _getToken();
    final prefs =
        await SharedPreferences.getInstance();

    final int? savedReportId = prefs.getInt(
      'analysis_report_id_$analysisId',
    );

    final String? cachedReportJson =
        prefs.getString(
      'analysis_report_json_$analysisId',
    );

    Map<String, dynamic>? cachedReport;

    if (cachedReportJson != null &&
        cachedReportJson.isNotEmpty) {
      try {
        final decoded =
            jsonDecode(cachedReportJson);

        if (decoded is Map) {
          cachedReport =
              Map<String, dynamic>.from(
            decoded,
          );
        }
      } catch (_) {}
    }

    /*
     * مهم:
     * /analyses/{analysisId}/report يدعم POST فقط،
     * لذلك لا نرسل GET عليه.
     *
     * إذا سبق أن أنشأنا التقرير من التطبيق،
     * نكون حفظنا report_id ونستخدم:
     * GET /reports/{reportId}
     */
    if (savedReportId == null) {
      print('');
      print('====================================');
      print('NO SAVED REPORT ID FOR ANALYSIS');
      print('ANALYSIS ID: $analysisId');
      print('====================================');

      return cachedReport;
    }

    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/reports/$savedReportId',
    );

    print('');
    print('====================================');
    print('GET SAVED REPORT');
    print('ANALYSIS ID: $analysisId');
    print('REPORT ID: $savedReportId');
    print('URL: $url');
    print('====================================');

    final response = await http.get(
      url,
      headers: _headers(token),
    );

    print(
      'GET SAVED REPORT STATUS: ${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map &&
          decoded['data'] is Map) {
        final report =
            Map<String, dynamic>.from(
          decoded['data'],
        );

        await _saveReportLocally(
          analysisId: analysisId,
          report: report,
        );

        return report;
      }
    }

    /*
     * إذا صار عطل مؤقت بالشبكة أو فشل GET،
     * نعرض آخر نسخة محفوظة محلياً بدل ما يختفي التقرير.
     */
    return cachedReport;
  }

}
