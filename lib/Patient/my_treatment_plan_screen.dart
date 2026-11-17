import 'package:flutter/material.dart';
import 'package:immunova/services/patient_my_treatment_plan_service.dart';

class MyTreatmentPlanScreen extends StatefulWidget {
  static const String routeName = '/my_treatment_plan';

  const MyTreatmentPlanScreen({
    super.key,
  });

  @override
  State<MyTreatmentPlanScreen> createState() =>
      _MyTreatmentPlanScreenState();
}

class _MyTreatmentPlanScreenState
    extends State<MyTreatmentPlanScreen> {
  final PatientMyTreatmentPlanService _service =
      PatientMyTreatmentPlanService();

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? treatmentPlan;

  @override
  void initState() {
    super.initState();
    _loadTreatmentPlan();
  }

  // =========================================================
  // LOAD APPROVED TREATMENT PLAN
  // =========================================================

  Future<void> _loadTreatmentPlan() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      treatmentPlan = null;
    });

    try {
      print('');
      print('====================================');
      print('GET MY APPROVED TREATMENT PLAN');
      print('PATIENT ID WILL BE RESOLVED FROM /me');
      print('====================================');

      final Map<String, dynamic>? plan =
          await _service.getMyApprovedTreatmentPlan();

      if (!mounted) return;

      setState(() {
        treatmentPlan = plan;
        isLoading = false;
        errorMessage = null;
      });

      print('');
      print('====================================');
      print('PATIENT TREATMENT PLAN LOADED');
      print('PLAN: $treatmentPlan');
      print('====================================');
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('LOAD TREATMENT PLAN ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        treatmentPlan = null;
        errorMessage = e.toString();
      });
    }
  }
  // =========================================================
  // PLAN ITEMS
  // =========================================================

  List<Map<String, dynamic>> _planItems() {
    final dynamic rawItems =
        treatmentPlan?['items'];

    final List<Map<String, dynamic>> result =
        [];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }
    }

    result.sort((a, b) {
      final int aOrder =
          int.tryParse(
                a['sort_order']?.toString() ??
                    '',
              ) ??
              0;

      final int bOrder =
          int.tryParse(
                b['sort_order']?.toString() ??
                    '',
              ) ??
              0;

      return aOrder.compareTo(bOrder);
    });

    return result;
  }

  String _value(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final String text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String get _status {
    return _value(
      treatmentPlan?['status'],
      fallback: 'approved',
    ).toLowerCase();
  }

  String get _approvedBy {
    final dynamic reviewedBy =
        treatmentPlan?['reviewed_by'];

    final dynamic reviewer =
        treatmentPlan?['reviewer'];

    final dynamic doctor =
        treatmentPlan?['doctor'];

    if (reviewer is Map) {
      final value =
          reviewer['name'] ??
          reviewer['full_name'];

      if (_value(value).isNotEmpty) {
        return _value(value);
      }
    }

    if (doctor is Map) {
      final value =
          doctor['name'] ??
          doctor['full_name'];

      if (_value(value).isNotEmpty) {
        return _value(value);
      }
    }

    final String reviewedByName =
        _value(
      treatmentPlan?['reviewed_by_name'] ??
          treatmentPlan?['doctor_name'] ??
          treatmentPlan?['approved_by_name'],
    );

    if (reviewedByName.isNotEmpty) {
      return reviewedByName;
    }

    /*
     * reviewed_by قد يكون ID فقط.
     * ما منعرض الرقم على أنه اسم طبيب.
     */
    if (reviewedBy is Map) {
      final name =
          reviewedBy['name'] ??
          reviewedBy['full_name'];

      if (_value(name).isNotEmpty) {
        return _value(name);
      }
    }

    return 'Your care team';
  }

  String get _approvedAt {
    return _value(
      treatmentPlan?['reviewed_at'] ??
          treatmentPlan?['approved_at'] ??
          treatmentPlan?['updated_at'],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 74,
        titleSpacing: 12,

        title: Row(
          children: [
            InkWell(
              borderRadius:
                  BorderRadius.circular(30),
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                  size: 17,
                  color: Color(0xFF2868D7),
                ),
              ),
            ),

            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'My care',
                    style: TextStyle(
                      color:
                          Color(0xFF9AA6BE),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'My treatment plan',
                    style: TextStyle(
                      color:
                          Color(0xFF101A38),
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed:
                  isLoading
                      ? null
                      : _loadTreatmentPlan,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF2868D7),
              ),
            ),
          ],
        ),

        bottom: const PreferredSize(
          preferredSize:
              Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE4E9F2),
          ),
        ),
      ),

      body: SafeArea(
        top: false,
        child: isLoading
            ? _buildLoading()
            : errorMessage != null
                ? _buildError()
                : treatmentPlan == null
                    ? _buildEmpty()
                    : _buildPlan(),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0DA89D),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load treatment plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101A38),
                fontSize: 17,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF53617B),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadTreatmentPlan,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label:
                  const Text('Try Again'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF0DA89D,
                ),
                foregroundColor:
                    Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO APPROVED PLAN
  // =========================================================

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration:
                  const BoxDecoration(
                color: Color(0xFFE2F7F4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .check_box_outlined,
                color: Color(0xFF0DA89D),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No approved treatment plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF101A38),
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your doctor has not approved a treatment plan yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF53617B),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _loadTreatmentPlan,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label:
                  const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PLAN CONTENT
  // =========================================================

  Widget _buildPlan() {
    final List<Map<String, dynamic>>
        items = _planItems();

    final bool approved =
        _status == 'approved';

    return RefreshIndicator(
      onRefresh: _loadTreatmentPlan,
      color: const Color(0xFF0DA89D),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          28,
        ),
        children: [
          // ===============================================
          // CURRENT PLAN + STATUS
          // ===============================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current plan from your care team',
                  style: TextStyle(
                    color:
                        Color(0xFF53617B),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w400,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                    BoxDecoration(
                  color: approved
                      ? const Color(
                          0xFFE0F7F3,
                        )
                      : const Color(
                          0xFFFFF0DF,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
                child: Text(
                  approved
                      ? 'Approved'
                      : _status,
                  style: TextStyle(
                    color: approved
                        ? const Color(
                            0xFF04958C,
                          )
                        : const Color(
                            0xFFA65D08,
                          ),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ===============================================
          // STEPS
          // ===============================================

          const Text(
            'STEPS',
            style: TextStyle(
              color: Color(0xFF97A3BC),
              fontSize: 11,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color:
                    const Color(
                  0xFFDDE4EF,
                ),
              ),
            ),
            child: items.isEmpty
                ? const Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    child: Text(
                      'No treatment steps were returned.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(
                          0xFF8996AF,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0;
                          i < items.length;
                          i++) ...[
                        _TreatmentStep(
                          text: _value(
                            items[i]['content'],
                            fallback:
                                'Treatment step',
                          ),
                        ),
                        if (i !=
                            items.length - 1)
                          const Divider(
                            height: 1,
                            color:
                                Color(
                              0xFFE4E9F2,
                            ),
                          ),
                      ],
                    ],
                  ),
          ),

          const SizedBox(height: 20),

          // ===============================================
          // APPROVED BY
          // ===============================================

          if (approved) ...[
            const Text(
              'APPROVED BY',
              style: TextStyle(
                color:
                    Color(0xFF97A3BC),
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color:
                      const Color(
                    0xFFDDE4EF,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment:
                        Alignment.center,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFE2F7F4,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .verified_user_outlined,
                      color:
                          Color(
                        0xFF0DA89D,
                      ),
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          _approvedBy,
                          style:
                              const TextStyle(
                            color:
                                Color(
                              0xFF53617B,
                            ),
                            fontSize: 11.5,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        if (_approvedAt
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            _approvedAt,
                            style:
                                const TextStyle(
                              color:
                                  Color(
                                0xFF9AA6BE,
                              ),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================
// TREATMENT STEP
// ===========================================================

class _TreatmentStep
    extends StatelessWidget {
  final String text;

  const _TreatmentStep({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFE2F7F4,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: const Icon(
              Icons
                  .check_circle_outline_rounded,
              color:
                  Color(
                0xFF0DA89D,
              ),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              text,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xFF101A38,
                ),
                fontSize: 13,
                height: 1.4,
                fontWeight:
                    FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
