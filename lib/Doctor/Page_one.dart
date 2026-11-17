import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immunova/Doctor/Add_Patient.dart';
import 'package:immunova/Doctor/patient_details_screen.dart';
import 'package:immunova/model/get_all_patients.dart';
import 'package:immunova/services/get_all_patients_service.dart';
import 'package:immunova/services/report_service.dart';


class Page_One_Screen extends StatefulWidget {
  final VoidCallback onViewAllPatients;

  const Page_One_Screen({
    super.key,
    required this.onViewAllPatients,
  });

  @override
  State<Page_One_Screen> createState() =>
      _Page_One_ScreenState();
}

class _Page_One_ScreenState
    extends State<Page_One_Screen> {
  final PatientService _patientService =
      PatientService();

  final ReportService _reportService =
      ReportService();

  List<Data> patients = [];

  bool isLoadingPatients = true;
  bool isLoadingReports = true;

  int completedReportsCount = 0;

  String doctorName = '';

  @override
  void initState() {
    super.initState();

    _loadDoctorName();
    _loadPatients();
  }

  Future<void> _loadDoctorName() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final String? savedName =
        prefs.getString('name');

    print(
      'DOCTOR NAME FROM STORAGE: $savedName',
    );

    if (!mounted) return;

    setState(() {
      doctorName =
          savedName?.trim() ?? '';
    });
  }

  Future<void> _loadPatients() async {
    try {
      final result =
          await _patientService.getPatients();

      if (!mounted) return;

      if (result != null) {
        setState(() {
          patients = result.data ?? [];
          isLoadingPatients = false;
        });

        print(
          'HOME PATIENT COUNT: ${patients.length}',
        );

        await _loadReportsCount();
      } else {
        setState(() {
          patients = [];
          isLoadingPatients = false;
          completedReportsCount = 0;
          isLoadingReports = false;
        });

        print(
          'HOME FAILED TO LOAD PATIENTS',
        );
      }
    } catch (e, stackTrace) {
      print(
        'HOME PATIENT ERROR: $e',
      );

      print(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        patients = [];
        isLoadingPatients = false;
        completedReportsCount = 0;
        isLoadingReports = false;
      });
    }
  }

  Future<void> _loadReportsCount() async {
    if (!mounted) return;

    setState(() {
      isLoadingReports = true;
    });

    try {
      final Set<int> uniqueCompletedReportIds =
          <int>{};

      for (final patient in patients) {
        final int? patientId = patient.id;

        if (patientId == null) {
          continue;
        }

        try {
          final reports =
              await _reportService
                  .getPatientReports(
            patientId: patientId,
          );

          print(
            'PATIENT $patientId RAW REPORTS COUNT: '
            '${reports.length}',
          );

          for (final report in reports) {
            final int? reportId =
                int.tryParse(
              report['id']?.toString() ?? '',
            );

            final String status =
                report['status']
                        ?.toString()
                        .toLowerCase() ??
                    '';

            /*
             * العد الصحيح:
             * - فقط التقارير التي تم توليدها فعلياً
             * - فقط status = completed
             * - نفس report_id لا ينحسب مرتين أبداً
             */
            if (reportId != null &&
                status == 'completed') {
              uniqueCompletedReportIds.add(
                reportId,
              );
            }
          }
        } catch (e) {
          print(
            'REPORT LOAD ERROR FOR '
            'PATIENT $patientId: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        completedReportsCount =
            uniqueCompletedReportIds.length;

        isLoadingReports = false;
      });

      print(
        'UNIQUE COMPLETED REPORT IDS: '
        '$uniqueCompletedReportIds',
      );
      print(
        'HOME COMPLETED REPORTS COUNT: '
        '$completedReportsCount',
      );

    } catch (e, stackTrace) {
      print(
        'HOME REPORT COUNT ERROR: $e',
      );
      print(
        'STACK TRACE: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        completedReportsCount = 0;
        isLoadingReports = false;
      });
    }
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAddPatient(
    BuildContext context,
  ) async {
    final result =
        await Navigator.push<Map<String, dynamic>>(
      context,

      MaterialPageRoute(
        builder: (context) =>
            const Add_Patient_Screen(),
      ),
    );

    if (!context.mounted ||
        result == null) {
      return;
    }

    final String patientName =
        result['fullName']
                ?.toString() ??
            'Patient';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('$patientName was added'),

        backgroundColor:
            const Color(0xFF12A6A0),

        behavior:
            SnackBarBehavior.floating,
      ),
    );

    await _loadPatients();
  }

  void _openPatientDetails(
    BuildContext context, {
    required String name,
    required String status,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),

      builder: (bottomSheetContext) {
        return Padding(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            8,
            22,
            30,
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              const CircleAvatar(
                radius: 30,

                backgroundColor:
                    Color(0xFFEAF1FF),

                child: Icon(
                  Icons
                      .person_outline_rounded,
                  color:
                      Color(0xFF2868D7),
                  size: 30,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                name,

                style: const TextStyle(
                  color:
                      Color(0xFF101A38),

                  fontSize: 20,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Patient status: $status',

                style: const TextStyle(
                  color:
                      Color(0xFF7A879F),

                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,

                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      bottomSheetContext,
                    );
                  },

                  child:
                      const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _displayStatus(Data patient) {
    final String status =
        patient.status?.trim() ?? '';

    if (status.isEmpty) {
      return 'New';
    }

    return status[0].toUpperCase() +
        status.substring(1);
  }

  String _subtitle(Data patient) {
    if (patient.medicalNotes != null &&
        patient.medicalNotes!
            .trim()
            .isNotEmpty) {
      return patient.medicalNotes!;
    }

    if (patient.patientCode != null &&
        patient.patientCode!
            .trim()
            .isNotEmpty) {
      return patient.patientCode!;
    }

    return 'Patient record';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'flagged':
        return const Color(
          0xFFE64D4D,
        );

      case 'stable':
      case 'active':
        return const Color(
          0xFF118E88,
        );

      default:
        return const Color(
          0xFF2868D7,
        );
    }
  }

  Color _statusBackground(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'flagged':
        return const Color(
          0xFFFFE8E8,
        );

      case 'stable':
      case 'active':
        return const Color(
          0xFFE4F7F5,
        );

      default:
        return const Color(
          0xFFEAF1FF,
        );
    }
  }

  Color _iconColor(String status) {
    switch (status.toLowerCase()) {
      case 'flagged':
        return const Color(
          0xFFE85858,
        );

      case 'stable':
      case 'active':
        return const Color(
          0xFF12A6A0,
        );

      default:
        return const Color(
          0xFF2868D7,
        );
    }
  }

  Color _iconBackground(
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'flagged':
        return const Color(
          0xFFFFE9E9,
        );

      case 'stable':
      case 'active':
        return const Color(
          0xFFE5F8F6,
        );

      default:
        return const Color(
          0xFFEAF1FF,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Data> homePatients =
        patients.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        25,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // Row(
          //   children: [
          //     CircleAvatar(
          //       radius: 24,

          //       backgroundColor:
          //           Color(0xFF167BCB),

          //       child: Text(
          //         'D',

          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 17,
          //           fontWeight:
          //               FontWeight.w700,
          //         ),
          //       ),
          //     ),

          //     SizedBox(width: 12),

          //     Expanded(
          //       child: Column(
          //         crossAxisAlignment:
          //             CrossAxisAlignment.start,

          //         children: [
          //           Text(
          //             doctorName.isNotEmpty
          //                 ? 'Welcome back, $doctorName'
          //                 : 'Welcome back, Doctor',

          //             style: TextStyle(
          //               color:
          //                   Color(0xFF0B1739),

          //               fontSize: 16,

          //               fontWeight:
          //                   FontWeight.w800,
          //             ),
          //           ),

          //           SizedBox(height: 4),

          //         ],
          //       ),
          //     ),
          //   ],
          // ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  value:
                      '${patients.length}',

                  label:
                      'Total Patients',

                  icon: Icons
                      .people_outline_rounded,

                  iconColor:
                      const Color(
                    0xFF2868D7,
                  ),

                  iconBackground:
                      const Color(
                    0xFFEAF1FF,
                  ),

                  onTap:
                      widget
                          .onViewAllPatients,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: DashboardStatCard(
                  value: isLoadingReports
                      ? '...'
                      : '$completedReportsCount',

                  label:
                      'Completed\nReports',

                  icon: Icons
                      .description_outlined,

                  iconColor:
                      const Color(
                    0xFF12A6A0,
                  ),

                  iconBackground:
                      const Color(
                    0xFFE4F8F6,
                  ),

                  onTap: () =>
                      _showMessage(
                    context,
                    isLoadingReports
                        ? 'Loading reports...'
                        : '$completedReportsCount completed reports',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 54,

            child: DecoratedBox(
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius
                        .circular(14),

                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF316BD8),
                    Color(0xFF14A9A3),
                  ],
                ),

                boxShadow: const [
                  BoxShadow(
                    color:
                        Color(
                      0x22316BD8,
                    ),

                    blurRadius: 12,

                    offset:
                        Offset(0, 6),
                  ),
                ],
              ),

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  borderRadius:
                      BorderRadius
                          .circular(14),

                  onTap: () =>
                      _openAddPatient(
                    context,
                  ),

                  child:
                      const Center(
                    child: Row(
                      mainAxisSize:
                          MainAxisSize
                              .min,

                      children: [
                        Icon(
                          Icons
                              .add_rounded,

                          color:
                              Colors.white,

                          size: 21,
                        ),

                        SizedBox(
                            width: 7),

                        Text(
                          'Add New Patient',

                          style:
                              TextStyle(
                            color:
                                Colors
                                    .white,

                            fontSize:
                                15,

                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

            children: [
              const Text(
                'PATIENTS',

                style: TextStyle(
                  color:
                      Color(0xFF94A0B8),

                  fontSize: 11,

                  fontWeight:
                      FontWeight.w700,

                  letterSpacing:
                      0.5,
                ),
              ),

              TextButton(
                onPressed:
                    widget
                        .onViewAllPatients,

                style:
                    TextButton.styleFrom(
                  padding:
                      EdgeInsets.zero,

                  minimumSize:
                      const Size(
                    50,
                    30,
                  ),
                ),

                child: const Text(
                  'View all',

                  style: TextStyle(
                    color:
                        Color(
                      0xFF285CCA,
                    ),

                    fontSize: 12,

                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                18,
              ),

              border: Border.all(
                color:
                    const Color(
                  0xFFE1E7F0,
                ),
              ),
            ),

            child: isLoadingPatients
                ? const Padding(
                    padding:
                        EdgeInsets.all(
                      25,
                    ),

                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  )

                : homePatients.isEmpty
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          20,
                        ),

                        child: Center(
                          child: Text(
                            'No patients found',

                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFF8A96AD,
                              ),
                            ),
                          ),
                        ),
                      )

                    : Column(
                        children:
                            List.generate(
                          homePatients.length,

                          (index) {
                            final patient =
                                homePatients[
                                    index];

                            final status =
                                _displayStatus(
                              patient,
                            );

                            return Column(
                              children: [
                                PatientRow(
                                  name:
                                      patient.name ??
                                          'Unknown Patient',

                                  subtitle:
                                      _subtitle(
                                    patient,
                                  ),

                                  status:
                                      status,

                                  statusColor:
                                      _statusColor(
                                    status,
                                  ),

                                  statusBackground:
                                      _statusBackground(
                                    status,
                                  ),

                                  iconColor:
                                      _iconColor(
                                    status,
                                  ),

                                  iconBackground:
                                      _iconBackground(
                                    status,
                                  ),

onTap: () {
                                    print(
                                      'HOME PATIENT CLICKED',
                                    );
                                    print(
                                      'HOME PATIENT ID: ${patient.id}',
                                    );
                                    print(
                                      'HOME PATIENT NAME: ${patient.name}',
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            PatientDetailsScreen(
                                          patient: patient,
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                if (index !=
                                    homePatients
                                            .length -
                                        1)
                                  const Divider(
                                    height:
                                        1,

                                    indent:
                                        14,

                                    endIndent:
                                        14,

                                    color:
                                        Color(
                                      0xFFE4E9F2,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class DashboardStatCard
    extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  final Color iconColor;
  final Color iconBackground;

  final VoidCallback onTap;

  const DashboardStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(15),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(15),

        onTap: onTap,

        child: Container(
          height: 126,

          padding:
              const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 11,
          ),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              15,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFE0E6EF,
              ),
            ),
          ),

          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                    BoxDecoration(
                  color:
                      iconBackground,

                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 19,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                value,

                style: const TextStyle(
                  color:
                      Color(
                    0xFF071331,
                  ),

                  fontSize: 17,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const SizedBox(height: 2),

              Expanded(
                child: Center(
                  child: Text(
                    label,

                    maxLines: 2,

                    overflow:
                        TextOverflow
                            .ellipsis,

                    textAlign:
                        TextAlign
                            .center,

                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF53617D,
                      ),

                      fontSize: 9,
                      height: 1.05,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientRow
    extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;

  final Color statusColor;
  final Color statusBackground;

  final Color iconColor;
  final Color iconBackground;

  final VoidCallback onTap;

  const PatientRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius:
            BorderRadius.circular(17),

        onTap: onTap,

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration:
                    BoxDecoration(
                  color:
                      iconBackground,

                  borderRadius:
                      BorderRadius
                          .circular(
                    11,
                  ),
                ),

                child: Icon(
                  Icons
                      .person_outline_rounded,

                  color: iconColor,

                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      name,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF101A38,
                        ),

                        fontSize: 13,

                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                        height: 3),

                    Text(
                      subtitle,

                      maxLines: 1,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF8A96AD,
                        ),

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      statusBackground,

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color:
                        statusColor,

                    fontSize: 9,

                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}