import 'package:flutter/material.dart';
import 'package:immunova/services/report_service.dart';

class MyReportScreen extends StatefulWidget {
  static const String routeName = '/my_report';

  final int patientId;

  const MyReportScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<MyReportScreen> createState() =>
      _MyReportScreenState();
}

class _MyReportScreenState extends State<MyReportScreen> {
  final ReportService _reportService = ReportService();

  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> reports = [];
  Map<String, dynamic>? latestReport;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // =========================================================
  // LOAD REPORTS
  // =========================================================

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('');
      print('====================================');
      print('GET PATIENT REPORTS FROM MY REPORT');
      print('PATIENT ID: ${widget.patientId}');
      print('====================================');

      final result =
          await _reportService.getPatientReports(
        patientId: widget.patientId,
      );

      // الأحدث أولاً حسب id إذا كان موجوداً.
      result.sort((a, b) {
        final int aId =
            int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final int bId =
            int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return bId.compareTo(aId);
      });

      if (!mounted) return;

      setState(() {
        reports = result;
        latestReport =
            result.isNotEmpty ? result.first : null;
        isLoading = false;
      });

      print('');
      print('====================================');
      print('PATIENT REPORTS LOADED');
      print('COUNT: ${result.length}');
      print('LATEST REPORT ID: ${latestReport?['id']}');
      print('====================================');
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('MY REPORT ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;

        /*
         * مهم:
         * لا نعرض response Laravel الكامل داخل الواجهة،
         * لأنه قد يحتوي trace طويل جداً ويسبب Overflow.
         */
        errorMessage =
            'Unable to load the report. Please try again.';
      });
    }
  }

  // =========================================================
  // SAFE VALUES
  // =========================================================

  String _value(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String get _reportNumber {
    return _value(
      latestReport?['report_number'],
      fallback: 'Clinical Report',
    );
  }

  String get _status {
    return _value(
      latestReport?['status'],
    );
  }

  String get _summary {
    return _value(
      latestReport?['summary'],
      fallback:
          'Your clinical report is available. '
          'Please contact your care team if anything is unclear.',
    );
  }

  String get _generatedAt {
    return _value(
      latestReport?['generated_at'] ??
          latestReport?['created_at'],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xfff8faff),

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
                  Icons.arrow_back_ios_new_rounded,
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
                      color: Color(0xFF9AA6BE),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'My report',
                    style: TextStyle(
                      color: Color(0xFF101A38),
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
                  isLoading ? null : _loadReports,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF2868D7),
              ),
            ),
          ],
        ),

        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
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
            ? _loading()
            : errorMessage != null
                ? _error()
                : latestReport == null
                    ? _empty()
                    : _reportBody(),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xff159fa4),
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _error() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration:
                  const BoxDecoration(
                color: Color(0xffffeeee),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 32,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load report',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff102344),
                fontSize: 18,
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
                color: Color(0xff8a96ad),
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label:
                  const Text('Try Again'),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xff159fa4),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO REPORT
  // =========================================================

  Widget _empty() {
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
                color: Color(0xffeaf2ff),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xff3974dc),
                size: 34,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No report available',
              style: TextStyle(
                color: Color(0xff102344),
                fontSize: 18,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your doctor has not generated a report yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xff8a96ad),
                fontSize: 12,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _loadReports,
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
  // REPORT BODY
  // نفس شكل التقرير في PatientDetailsScreen
  // =========================================================

  Widget _reportBody() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xff159fa4),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding:
            const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          30,
        ),
        children: [
          const Text(
            'REPORT',
            style: TextStyle(
              color: Color(0xff94a0b8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),

          const SizedBox(height: 10),

          _reportCard(),

          if (reports.length > 1) ...[
            const SizedBox(height: 22),

            const Text(
              'PREVIOUS REPORTS',
              style: TextStyle(
                color: Color(0xff94a0b8),
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
                letterSpacing: 0.35,
              ),
            ),

            const SizedBox(height: 10),

            ...reports
                .skip(1)
                .map(_previousReportCard),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // LATEST REPORT CARD
  // =========================================================

  Widget _reportCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
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
                color: Color(0xff12a6a0),
                size: 21,
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

              if (_status.isNotEmpty)
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
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _status,
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
            _reportNumber,
            style: const TextStyle(
              color: Color(0xff102344),
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          if (_generatedAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Generated: $_generatedAt',
              style: const TextStyle(
                color: Color(0xff8a96ad),
                fontSize: 10,
              ),
            ),
          ],

          const SizedBox(height: 14),

          const Divider(
            height: 1,
            color: Color(0xffedf0f5),
          ),

          const SizedBox(height: 12),

          Text(
            _summary,
            style: const TextStyle(
              color: Color(0xff53627d),
              fontSize: 11.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PREVIOUS REPORT
  // =========================================================

  Widget _previousReportCard(
    Map<String, dynamic> report,
  ) {
    final String reportNumber =
        _value(
      report['report_number'],
      fallback: 'Clinical Report',
    );

    final String status =
        _value(report['status']);

    final String generatedAt =
        _value(
      report['generated_at'] ??
          report['created_at'],
    );

    final String summary =
        _value(
      report['summary'],
      fallback: 'Clinical report',
    );

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
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
                color: Color(0xff12a6a0),
                size: 18,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  reportNumber,
                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xff102344,
                    ),
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),

              if (status.isNotEmpty)
                Text(
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
            ],
          ),

          if (generatedAt.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              generatedAt,
              style:
                  const TextStyle(
                color:
                    Color(
                  0xff8a96ad,
                ),
                fontSize: 9,
              ),
            ),
          ],

          const SizedBox(height: 9),

          Text(
            summary,
            maxLines: 4,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff53627d),
              fontSize: 10.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
