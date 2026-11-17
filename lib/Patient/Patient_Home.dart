import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immunova/Patient/paint_home_conent.dart';
import 'package:immunova/Patient/patient_profile_content.dart';
import 'package:immunova/const.dart';

class PatientHomeScreen extends StatefulWidget {
  static const String routeName = '/patient_home';

  /*
   * اختياري:
   * إذا فتحت الصفحة ومعك patient profile id الحقيقي
   * فيك تمرره مباشرة.
   */
  final int? patientId;

  const PatientHomeScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientHomeScreen> createState() =>
      _PatientHomeScreenState();
}

class _PatientHomeScreenState
    extends State<PatientHomeScreen> {
  int _selectedIndex = 0;

  int? _patientId;

  bool _isLoadingPatientId = true;

  String? _patientIdError;

  final List<String> _titles = [
    'Home',
    'Insights',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();

    _resolvePatientId();
  }

  // =========================================================
  // RESOLVE REAL PATIENT PROFILE ID
  // =========================================================
  //
  // مهم جداً:
  // user_id != patient_profile.id
  //
  // endpoint:
  // /patients/{patientId}/reports
  //
  // يحتاج Patient Profile ID وليس User ID.
  // =========================================================

  Future<void> _resolvePatientId() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPatientId = true;
      _patientIdError = null;
    });

    try {
      // -------------------------------------------------------
      // 1) إذا تم تمرير patientId الحقيقي للصفحة استخدمه
      // -------------------------------------------------------

      if (widget.patientId != null &&
          widget.patientId! > 0) {
        _patientId = widget.patientId;

        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setInt(
          'patient_id',
          widget.patientId!,
        );

        print('');
        print('====================================');
        print('PATIENT HOME');
        print(
          'PATIENT PROFILE ID FROM CONSTRUCTOR: '
          '${widget.patientId}',
        );
        print('====================================');

        if (!mounted) return;

        setState(() {
          _isLoadingPatientId = false;
        });

        return;
      }

      final prefs =
          await SharedPreferences.getInstance();

      final String? token =
          prefs.getString('access_token');

      if (token == null ||
          token.trim().isEmpty) {
        throw Exception(
          'Access token not found. Please login again.',
        );
      }

      // -------------------------------------------------------
      // 2) جيب المستخدم الحالي من Laravel
      // -------------------------------------------------------

      final Uri url = Uri.parse(
        'http://$localhost:8000/api/v1/me',
      );

      print('');
      print('====================================');
      print('GET CURRENT PATIENT');
      print('URL: $url');
      print('====================================');

      final response =
          await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization':
              'Bearer $token',
        },
      );

      print(
        'ME STATUS: ${response.statusCode}',
      );

      print(
        'ME RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load current patient '
          '(${response.statusCode})',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception(
          'Invalid current-user response.',
        );
      }

      final Map<String, dynamic> root =
          Map<String, dynamic>.from(
        decoded,
      );

      // -------------------------------------------------------
      // Laravel غالباً يرجع:
      //
      // {
      //   "success": true,
      //   "data": {
      //     "user": {
      //       "id": 2,                 <-- USER ID
      //       "role": "patient",
      //       "patient_profile": {
      //         "id": 5               <-- المطلوب
      //       }
      //     }
      //   }
      // }
      //
      // ندعم أكثر من شكل response حتى ما تنكسر الصفحة.
      // -------------------------------------------------------

      dynamic data = root['data'];

      Map<String, dynamic>? dataMap;

      if (data is Map) {
        dataMap =
            Map<String, dynamic>.from(
          data,
        );
      }

      dynamic rawUser;

      if (dataMap != null &&
          dataMap['user'] is Map) {
        rawUser = dataMap['user'];
      } else if (root['user'] is Map) {
        rawUser = root['user'];
      } else if (dataMap != null) {
        // بعض APIs ترجع user مباشرة داخل data
        rawUser = dataMap;
      }

      Map<String, dynamic>? user;

      if (rawUser is Map) {
        user =
            Map<String, dynamic>.from(
          rawUser,
        );
      }

      final String role =
          (user?['role'] ??
                  dataMap?['role'] ??
                  root['role'])
              ?.toString()
              .toLowerCase() ??
          '';

      if (role.isNotEmpty &&
          role != 'patient') {
        throw Exception(
          'The logged-in account is not a patient.',
        );
      }

      dynamic rawPatientProfile;

      if (user?['patient_profile']
          is Map) {
        rawPatientProfile =
            user!['patient_profile'];
      } else if (dataMap?[
              'patient_profile']
          is Map) {
        rawPatientProfile =
            dataMap!['patient_profile'];
      } else if (root[
              'patient_profile']
          is Map) {
        rawPatientProfile =
            root['patient_profile'];
      } else if (user?[
              'patientProfile']
          is Map) {
        rawPatientProfile =
            user!['patientProfile'];
      }

      int? patientProfileId;

      if (rawPatientProfile is Map) {
        final Map<String, dynamic>
            patientProfile =
            Map<String, dynamic>.from(
          rawPatientProfile,
        );

        patientProfileId =
            int.tryParse(
          patientProfile['id']
                  ?.toString() ??
              '',
        );
      }

      // -------------------------------------------------------
      // 3) إذا /me ما رجع patient_profile نجرب patient_id
      // -------------------------------------------------------

      patientProfileId ??=
          int.tryParse(
        (user?['patient_id'] ??
                    dataMap?[
                        'patient_id'] ??
                    root['patient_id'])
                ?.toString() ??
            '',
      );

      // -------------------------------------------------------
      // 4) Fallback فقط على patient_id المخزن سابقاً
      //
      // ملاحظة:
      // لا نستخدم user_id هنا لأنه شيء مختلف.
      // -------------------------------------------------------

      patientProfileId ??=
          prefs.getInt('patient_id');

      if (patientProfileId == null ||
          patientProfileId <= 0) {
        throw Exception(
          'Patient profile ID was not returned by the server.',
        );
      }

      // خزّن الـ patient profile ID الحقيقي للاستخدام لاحقاً
      await prefs.setInt(
        'patient_id',
        patientProfileId,
      );

      _patientId =
          patientProfileId;

      print('');
      print('====================================');
      print('PATIENT PROFILE ID RESOLVED');
      print(
        'PATIENT ID: $patientProfileId',
      );
      print(
        'USER ID (for comparison only): '
        '${user?['id']}',
      );
      print('====================================');

      if (!mounted) return;

      setState(() {
        _isLoadingPatientId = false;
        _patientIdError = null;
      });
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('PATIENT ID ERROR');
      print('ERROR: $e');
      print(
        'STACK TRACE: $stackTrace',
      );
      print('====================================');

      if (!mounted) return;

      setState(() {
        _isLoadingPatientId = false;
        _patientIdError =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // =========================================================
  // CHANGE PAGE
  // =========================================================

  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // =========================================================
  // SELECTED PAGE
  // =========================================================

  Widget _getSelectedPage() {
    if (_isLoadingPatientId) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(
            0xFF15A6A6,
          ),
        ),
      );
    }

    if (_patientIdError != null ||
        _patientId == null) {
      return Center(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(
                    0xFFFFEEEE,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 34,
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text(
                'Unable to load patient profile',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF101A38,
                  ),
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                _patientIdError ??
                    'Patient ID not found.',
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF53617B,
                  ),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              ElevatedButton.icon(
                onPressed:
                    _resolvePatientId,
                icon:
                    const Icon(
                  Icons.refresh,
                ),
                label:
                    const Text(
                  'Try Again',
                ),
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF15A6A6,
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

    final int patientId =
        _patientId!;

    switch (_selectedIndex) {
      // ==========================================
      // HOME
      // ==========================================
      case 0:
        return PatientHomeContent(
          patientId: patientId,
        );

      // ==========================================
      // INSIGHTS
      // ==========================================
      case 1:
        return const Center(
          child: Text(
            'Insights',
            style: TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(
                0xFF101A38,
              ),
            ),
          ),
        );

      // ==========================================
      // PROFILE
      // ==========================================
      case 2:
        return const PatientProfileContent();

      default:
        return PatientHomeContent(
          patientId: patientId,
        );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      // ==========================================
      // APP BAR
      // ==========================================

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            Colors.white,
        surfaceTintColor:
            Colors.white,
        elevation: 0,
        toolbarHeight: 74,
        titleSpacing: 12,

        title: Row(
          children: [
            // ======================================
            // BACK BUTTON
            // ======================================

            InkWell(
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
              onTap: () {
                if (_selectedIndex !=
                    0) {
                  _changePage(0);
                } else if (Navigator
                    .canPop(context)) {
                  Navigator.pop(
                    context,
                  );
                }
              },
              child: Container(
                width: 42,
                height: 42,
                alignment:
                    Alignment.center,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(
                    0xFFF0F5FF,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .arrow_back_ios_new_rounded,
                  size: 17,
                  color:
                      Color(
                    0xFF2868D7,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            // ======================================
            // TITLE
            // ======================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'Immunova',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFF9AA6BE,
                      ),
                      fontSize: 10,
                      fontWeight:
                          FontWeight
                              .w500,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    _titles[
                        _selectedIndex],
                    style:
                        const TextStyle(
                      color:
                          Color(
                        0xFF101A38,
                      ),
                      fontSize: 18,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================
            // PATIENT AVATAR
            // ======================================

            InkWell(
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
              onTap: () {
                _changePage(2);
              },
              child: Container(
                width: 38,
                height: 38,
                alignment:
                    Alignment.center,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(
                    0xFF0B98B5,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Text(
                  'M',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ),
          ],
        ),

        bottom:
            const PreferredSize(
          preferredSize:
              Size.fromHeight(
            1,
          ),
          child: Divider(
            height: 1,
            thickness: 1,
            color:
                Color(
              0xFFE4E9F2,
            ),
          ),
        ),
      ),

      // ==========================================
      // BODY
      // ==========================================

      body: _getSelectedPage(),

      // ==========================================
      // BOTTOM NAVIGATION
      // ==========================================

      bottomNavigationBar:
          Container(
        height: 78,
        decoration:
            const BoxDecoration(
          color: Colors.white,
          border: Border(
            top:
                BorderSide(
              color:
                  Color(
                0xFFE4E9F2,
              ),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceAround,
            children: [
              _buildNavigationItem(
                index: 0,
                icon:
                    Icons.home_outlined,
                selectedIcon:
                    Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavigationItem(
                index: 1,
                icon:
                    Icons.bar_chart_outlined,
                selectedIcon:
                    Icons.bar_chart_rounded,
                label: 'Insights',
              ),
              _buildNavigationItem(
                index: 2,
                icon:
                    Icons.person_outline_rounded,
                selectedIcon:
                    Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // NAVIGATION ITEM
  // =========================================================

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool isSelected =
        _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _changePage(index);
        },
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              Icon(
                isSelected
                    ? selectedIcon
                    : icon,
                size: 23,
                color: isSelected
                    ? const Color(
                        0xFF2868D7,
                      )
                    : const Color(
                        0xFF8E9BB5,
                      ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(
                          0xFF2868D7,
                        )
                      : const Color(
                          0xFF8E9BB5,
                        ),
                  fontSize: 10,
                  fontWeight:
                      isSelected
                          ? FontWeight
                              .w700
                          : FontWeight
                              .w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
