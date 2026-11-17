import 'package:flutter/material.dart';
import 'package:immunova/Doctor/Analysis/new_analysis_screen.dart';
import 'package:immunova/Doctor/edot_treatment_plan_screen.dart';

import 'package:immunova/model/get_all_patients.dart';
import 'package:immunova/services/patient_details_service.dart';


class PatientDetailsScreen extends StatefulWidget {
  final Data patient;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
  });

  @override
  State<PatientDetailsScreen> createState() =>
      _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  final PatientDetailsService _service = PatientDetailsService();

  bool isLoading = true;
  bool isGeneratingReport = false;

  String? errorMessage;

  Map<String, dynamic>? treatmentPlan;
  Map<String, dynamic>? reportData;

  int? latestAnalysisId;
  int? planAnalysisId;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final int? patientId = widget.patient.id;

    if (patientId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Patient ID not found.';
        treatmentPlan = null;
        latestAnalysisId = null;
        planAnalysisId = null;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      treatmentPlan = null;
      latestAnalysisId = null;
      planAnalysisId = null;
    });

    try {
      final result =
          await _service.getPatientClinicalData(
        patientId: patientId,
      );

      if (!mounted) return;

      final dynamic rawPlan =
          result['treatment_plan'];

      setState(() {
        treatmentPlan = rawPlan is Map
            ? Map<String, dynamic>.from(rawPlan)
            : null;

        latestAnalysisId = int.tryParse(
          result['latest_analysis_id']
                  ?.toString() ??
              '',
        );

        planAnalysisId = int.tryParse(
          result['plan_analysis_id']
                  ?.toString() ??
              '',
        );

        isLoading = false;
      });

      await _loadExistingReport();

      print('');
      print('====================================');
      print('PATIENT DETAILS LOADED');
      print('PATIENT ID: $patientId');
      print(
        'LATEST ANALYSIS ID: $latestAnalysisId',
      );
      print(
        'PLAN ANALYSIS ID: $planAnalysisId',
      );
      print('====================================');
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('PATIENT DETAILS ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        treatmentPlan = null;
        latestAnalysisId = null;
        planAnalysisId = null;
      });
    }
  }

  List<Map<String, dynamic>> _planItems() {
    final rawItems = treatmentPlan?['items'];
    final result = <Map<String, dynamic>>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
    }

    result.sort(
      (a, b) => (a['sort_order'] ?? 0)
          .toString()
          .compareTo((b['sort_order'] ?? 0).toString()),
    );

    return result;
  }

  String _value(String? value, {String fallback = 'Not available'}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value;
  }

  Future<void> _openNewAnalysis() async {
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  NewAnalysisScreen(
           patientId: widget.patient.id!,
        ),
      ),
    );

    if (!mounted) return;

    /*
     * بعد الرجوع من شاشة إنشاء التحليل نعيد تحميل بيانات المريض
     * حتى يظهر أي تحليل/خطة/تقرير جديد مباشرة.
     */
    if (result != null) {
      await _loadPatientData();
    }
  }

  void _addSymptomsLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Add Symptoms will be connected later.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadExistingReport() async {
    final int? analysisId =
        planAnalysisId ?? latestAnalysisId;

    if (analysisId == null) {
      return;
    }

    try {
      final existingReport =
          await _service.getLatestReportForAnalysis(
        analysisId: analysisId,
      );

      if (!mounted || existingReport == null) {
        return;
      }

      setState(() {
        reportData = existingReport;
      });

      print('');
      print('====================================');
      print('EXISTING REPORT LOADED');
      print(
        'REPORT ID: ${existingReport['id']}',
      );
      print('====================================');
    } catch (e) {
      print(
        'LOAD EXISTING REPORT ERROR: $e',
      );
    }
  }

  Future<void> _generateReport() async {
    if (isGeneratingReport) {
      return;
    }

    /*
     * إذا في Treatment Plan نستخدم نفس Analysis
     * المرتبط بالخطة حتى يكون التقرير لنفس الحالة.
     * وإذا ما في خطة نستخدم أحدث Analysis للمريض.
     */
    final int? analysisId =
        planAnalysisId ?? latestAnalysisId;

    if (analysisId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No analysis was found for this patient.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isGeneratingReport = true;
    });

    try {
      print('');
      print('====================================');
      print('GENERATE REPORT FROM PATIENT DETAILS');
      print('ANALYSIS ID: $analysisId');
      print('====================================');

      /*
       * Service يعمل:
       * POST /analyses/{analysisId}/report
       * ثم يأخذ report_id
       * ثم GET /reports/{reportId}
       */
      final response =
          await _service.generateReport(
        analysisId: analysisId,
      );

      final dynamic rawData =
          response['data'];

      if (rawData is! Map) {
        throw Exception(
          'Report data was not returned.',
        );
      }

      if (!mounted) return;

      setState(() {
        reportData =
            Map<String, dynamic>.from(
          rawData,
        );
      });

      /*
       * التقرير انحفظ في الباك من POST.
       * نرجع نقرأه حتى تبقى النسخة المحفوظة ظاهرة
       * حتى بعد الخروج والرجوع للواجهة.
       */
      await _loadExistingReport();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Report generated successfully.',
          ),
          backgroundColor:
              Color(0xff159fa4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('GENERATE REPORT ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Generate report failed: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingReport = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;

    return Scaffold(
      backgroundColor: const Color(0xfff8faff),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xff102344),
        title: const Text(
          'Patient Details',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPatientData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            _patientHeader(patient),
            const SizedBox(height: 20),
            const _SectionTitle(title: 'PERSONAL INFORMATION'),
            const SizedBox(height: 10),
            _personalInformationCard(patient),
            const SizedBox(height: 22),
            const _SectionTitle(title: 'TREATMENT PLAN'),
            const SizedBox(height: 10),
            if (isLoading)
              _loadingCard()
            else if (errorMessage != null)
              _errorCard()
            else
              _treatmentPlanCard(),
            const SizedBox(height: 22),
            const _SectionTitle(title: 'REPORT'),
            const SizedBox(height: 10),
            _reportCard(),

            const SizedBox(height: 18),

            _bottomActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _patientHeader(Data patient) {
    final name = _value(patient.name, fallback: 'Patient');
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    final status = _value(patient.status, fallback: 'Patient');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe1e7f0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xff3974dc),
                  Color(0xff11a8a2),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xff102344),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffe2f7f3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Color(0xff118e88),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInformationCard(Data patient) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe1e7f0)),
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.badge_outlined,
            title: 'Patient ID',
            value: _value(
              patient.patientCode ?? patient.id?.toString(),
            ),
            blue: true,
          ),
          const _SoftDivider(),
          _infoRow(
            icon: Icons.calendar_month_outlined,
            title: 'Date of birth',
            value: _value(patient.dateOfBirth),
          ),
          const _SoftDivider(),
          _infoRow(
            icon: Icons.person_outline,
            title: 'Gender',
            value: _value(patient.gender),
            blue: true,
          ),
          const _SoftDivider(),
          _infoRow(
            icon: Icons.phone_outlined,
            title: 'Phone',
            value: _value(patient.phone),
          ),
          const _SoftDivider(),
          _infoRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: _value(patient.email),
            blue: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    bool blue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: blue
                  ? const Color(0xffeaf2ff)
                  : const Color(0xffe6f8f5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: blue
                  ? const Color(0xff3974dc)
                  : const Color(0xff119c96),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff102344),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xff8a96ad),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe1e7f0)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffffd1d1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _loadPatientData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditTreatmentPlan() async {
    final plan = treatmentPlan;

    if (plan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Treatment plan not found.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int? treatmentPlanId = int.tryParse(
      plan['id']?.toString() ?? '',
    );

    if (treatmentPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Treatment plan ID not found.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> initialItems = [];

    final dynamic rawItems = plan['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          initialItems.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    final Map<String, dynamic>? updatedPlan =
        await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTreatmentPlanScreen(
          treatmentPlanId: treatmentPlanId,
          initialItems: initialItems,
        ),
      ),
    );

    if (!mounted || updatedPlan == null) {
      return;
    }

    setState(() {
      /*
       * نخلي الخطة المعدلة ظاهرة فوراً بعد Save.
       * التعديل من الباك ممكن يرجع status = pending،
       * لذلك ما منعمل Reload مباشر يخفيها.
       */
      treatmentPlan = updatedPlan;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Treatment plan updated successfully.',
        ),
        backgroundColor: Color(0xff159fa4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _treatmentPlanCard() {
    if (treatmentPlan == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xffe1e7f0)),
        ),
        child: const Text(
          'No treatment plan available for this patient.',
          style: TextStyle(color: Color(0xff8a96ad)),
        ),
      );
    }

    final status = treatmentPlan?['status']?.toString() ?? 'pending';
    final items = _planItems();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe1e7f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: Color(0xff12a6a0),
                size: 19,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Treatment Plan',
                  style: TextStyle(
                    color: Color(0xff102344),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? const Color(0xffe2f7f3)
                      : const Color(0xfffff0df),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status == 'approved' ? 'Approved' : status,
                  style: TextStyle(
                    color: status == 'approved'
                        ? const Color(0xff118e88)
                        : const Color(0xffa65d08),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'No treatment plan items were returned.',
              style: TextStyle(color: Color(0xff8a96ad)),
            )
          else
            ...List.generate(
              items.length,
              (index) => Column(
                children: [
                  _planRow(
                    items[index]['content']?.toString() ?? '',
                  ),
                  if (index != items.length - 1)
                    const _SoftDivider(),
                ],
              ),
            ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _openEditTreatmentPlan,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text(
                'Edit Plan',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(0xff2856c7),
                side: const BorderSide(
                  color: Color(0xffdfe6f1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planRow(String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xffe2f7f3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.check,
              color: Color(0xff118e88),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: Color(0xff102344),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(15),
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xff316bd8),
                  Color(0xff14a9a3),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openNewAnalysis,
                borderRadius:
                    BorderRadius.circular(15),
                child: const Center(
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 19,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'New Analysis',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed:
                isGeneratingReport
                    ? null
                    : _generateReport,
            style:
                OutlinedButton.styleFrom(
              foregroundColor:
                  const Color(0xff53627d),
              side: const BorderSide(
                color: Color(0xffdfe5ef),
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            child:
                isGeneratingReport
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Generate Report',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _reportCard() {
    if (reportData == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color:
                const Color(0xffe1e7f0),
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.description_outlined,
              color: Color(0xff12a6a0),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical report',
                    style: TextStyle(
                      color:
                          Color(0xff102344),
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap Generate Report to create and display the report.',
                    style: TextStyle(
                      color:
                          Color(0xff8a96ad),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String reportNumber =
        reportData?['report_number']
                ?.toString() ??
            'Clinical Report';

    final String status =
        reportData?['status']
                ?.toString() ??
            '';

    final String summary =
        reportData?['summary']
                ?.toString() ??
            '';

    final String generatedAt =
        reportData?['generated_at']
                ?.toString() ??
            '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xffe1e7f0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color:
                    Color(0xff12a6a0),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Clinical report',
                  style: TextStyle(
                    color:
                        Color(0xff102344),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xffe2f7f3,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(20),
                  ),
                  child: Text(
                    status,
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xff118e88,
                      ),
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            reportNumber,
            style: const TextStyle(
              color: Color(0xff102344),
              fontSize: 12,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
          if (generatedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Generated: $generatedAt',
              style: const TextStyle(
                color:
                    Color(0xff8a96ad),
                fontSize: 10,
              ),
            ),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              color:
                  Color(0xffedf0f5),
            ),
            const SizedBox(height: 12),
            Text(
              summary,
              style: const TextStyle(
                color:
                    Color(0xff53627d),
                fontSize: 11,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xff94a0b8),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.35,
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xffedf0f5),
    );
  }
}
