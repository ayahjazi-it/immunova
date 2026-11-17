import 'package:flutter/material.dart';
import 'package:immunova/Doctor/patient_details_screen.dart';
import 'package:immunova/model/get_all_patients.dart';
import 'package:immunova/services/get_all_patients_service.dart';

class Patients_Page_Screen extends StatefulWidget {
  const Patients_Page_Screen({super.key});

  @override
  State<Patients_Page_Screen> createState() =>
      _Patients_Page_ScreenState();
}

class _Patients_Page_ScreenState
    extends State<Patients_Page_Screen> {
  final PatientService _patientService =
      PatientService();

  List<Data> patients = [];

  bool isLoading = true;

  String? errorMessage;

  int? deletingPatientId;

  @override
  void initState() {
    super.initState();

    _loadPatients();
  }

  Future<void> _loadPatients() async {
    print('');
    print('====================================');
    print('LOAD PATIENTS STARTED');
    print('====================================');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
          await _patientService.getPatients();

      if (!mounted) return;

      if (result != null) {
        setState(() {
          patients = result.data ?? [];
          isLoading = false;
        });

        print('');
        print('====================================');
        print('PATIENTS LOADED IN UI');
        print('COUNT: ${patients.length}');
        print('====================================');
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to load patients.';
        });

        print(
          'FAILED TO LOAD PATIENTS IN UI',
        );
      }
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('LOAD PATIENTS UI ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            'Failed to load patients.';
      });
    }
  }

  // ===================================
  // DELETE PATIENT
  // ===================================

  Future<void> _deletePatient(
    Data patient,
  ) async {
    if (patient.id == null) {
      print('DELETE ERROR: PATIENT ID IS NULL');
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),

          title: const Text(
            'Delete Patient',
            style: TextStyle(
              color: Color(0xFF101A38),
              fontWeight: FontWeight.w800,
            ),
          ),

          content: Text(
            'Are you sure you want to delete ${patient.name ?? 'this patient'}?',
            style: const TextStyle(
              color: Color(0xFF7A879F),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      print('DELETE PATIENT CANCELLED');

      return;
    }

    print('');
    print('====================================');
    print('DELETE PATIENT FROM UI');
    print('ID: ${patient.id}');
    print('NAME: ${patient.name}');
    print('====================================');

    setState(() {
      deletingPatientId = patient.id;
    });

    final bool success =
        await _patientService.deletePatient(
      patient.id!,
    );

    if (!mounted) return;

    setState(() {
      deletingPatientId = null;
    });

    if (success) {
      print('');
      print('====================================');
      print('DELETE SUCCESS IN UI');
      print('====================================');

      setState(() {
        patients.removeWhere(
          (item) =>
              item.id == patient.id,
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${patient.name ?? 'Patient'} deleted successfully',
          ),
          backgroundColor:
              const Color(0xFF12A6A0),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } else {
      print('');
      print('====================================');
      print('DELETE FAILED IN UI');
      print('====================================');

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete patient',
          ),
          backgroundColor: Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPatientDetails(
    BuildContext context, {
    required String name,
    required String status,
    required String subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
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
                subtitle,
                textAlign:
                    TextAlign.center,

                style: const TextStyle(
                  color:
                      Color(0xFF7A879F),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Status: $status',

                style: const TextStyle(
                  color:
                      Color(0xFF354465),
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
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

  String _getSubtitle(Data patient) {
    final String? notes =
        patient.medicalNotes;

    if (notes != null &&
        notes.trim().isNotEmpty) {
      return notes;
    }

    final String status =
        patient.status?.toLowerCase() ?? '';

    if (status == 'new') {
      return 'New intake · awaiting review';
    }

    if (status == 'stable') {
      return 'Stable · patient record';
    }

    if (status == 'flagged') {
      return 'Flagged marker';
    }

    return patient.patientCode ??
        'Patient record';
  }

  String _displayStatus(Data patient) {
    final status =
        patient.status?.trim();

    if (status == null ||
        status.isEmpty) {
      return 'New';
    }

    return status[0].toUpperCase() +
        status.substring(1);
  }

  Color _statusTextColor(
    String status,
  ) {
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

      case 'new':
      default:
        return const Color(
          0xFF2868D7,
        );
    }
  }

  Color _statusBackgroundColor(
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

      case 'new':
      default:
        return const Color(
          0xFFEAF1FF,
        );
    }
  }

  Color _iconColor(
    String status,
  ) {
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

      case 'new':
      default:
        return const Color(
          0xFF2868D7,
        );
    }
  }

  Color _iconBackgroundColor(
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

      case 'new':
      default:
        return const Color(
          0xFFEAF1FF,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _loadPatients,
              child:
                  const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPatients,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),

        keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior
                .onDrag,

        padding:
            const EdgeInsets.fromLTRB(
          18,
          16,
          18,
          30,
        ),

        children: [
          Text(
            'ALL PATIENTS (${patients.length})',

            style: const TextStyle(
              color:
                  Color(0xFF94A0B8),

              fontSize: 11,

              fontWeight:
                  FontWeight.w700,

              letterSpacing: 0.45,
            ),
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,

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

            child: patients.isEmpty
                ? const Padding(
                    padding:
                        EdgeInsets.all(
                      25,
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

                          fontSize:
                              13,
                        ),
                      ),
                    ),
                  )

                : Column(
                    children:
                        List.generate(
                      patients.length,

                      (index) {
                        final patient =
                            patients[index];

                        final String
                            status =
                            _displayStatus(
                          patient,
                        );

                        return Column(
                          children: [
                            PatientListItem(
                              name:
                                  patient.name ??
                                      'Unknown patient',

                              subtitle:
                                  _getSubtitle(
                                patient,
                              ),

                              status:
                                  status,

                              statusTextColor:
                                  _statusTextColor(
                                status,
                              ),

                              statusBackgroundColor:
                                  _statusBackgroundColor(
                                status,
                              ),

                              iconColor:
                                  _iconColor(
                                status,
                              ),

                              iconBackgroundColor:
                                  _iconBackgroundColor(
                                status,
                              ),

                              isDeleting:
                                  deletingPatientId ==
                                      patient.id,

                              onDelete:
                                  () {
                                _deletePatient(
                                  patient,
                                );
                              },

                              onTap: () {
                                print('');
                                print(
                                  'PATIENT CLICKED',
                                );
                                print(
                                  'ID: ${patient.id}',
                                );
                                print(
                                  'NAME: ${patient.name}',
                                );
                                print(
                                  'CODE: ${patient.patientCode}',
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
                                patients.length -
                                    1)
                              const _PatientDivider(),
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

class PatientListItem
    extends StatelessWidget {
  final String name;
  final String subtitle;
  final String status;

  final Color statusTextColor;
  final Color statusBackgroundColor;

  final Color iconColor;
  final Color iconBackgroundColor;

  final VoidCallback onTap;

  // الجديد فقط
  final VoidCallback onDelete;
  final bool isDeleting;

  const PatientListItem({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.statusTextColor,
    required this.statusBackgroundColor,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
    required this.onDelete,
    required this.isDeleting,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(17),

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

                decoration: BoxDecoration(
                  color:
                      iconBackgroundColor,

                  borderRadius:
                      BorderRadius.circular(
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
                      statusBackgroundColor,

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    color:
                        statusTextColor,

                    fontSize: 9,

                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // =========================
              // DELETE ICON
              // =========================

              SizedBox(
                width: 32,
                height: 32,

                child: isDeleting
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          7,
                        ),

                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,

                          color:
                              Colors.red,
                        ),
                      )

                    : IconButton(
                        padding:
                            EdgeInsets.zero,

                        constraints:
                            const BoxConstraints(),

                        splashRadius:
                            18,

                        onPressed:
                            onDelete,

                        icon:
                            const Icon(
                          Icons
                              .delete_outline_rounded,

                          color:
                              Color(
                            0xFFE85858,
                          ),

                          size: 20,
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

class _PatientDivider
    extends StatelessWidget {
  const _PatientDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 14,
      endIndent: 14,
      color: Color(0xFFE4E9F2),
    );
  }
}