import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const.dart';

class LogSymptomScreen extends StatefulWidget {
  static const String routeName = '/log_symptom';

  final int? patientId;

  const LogSymptomScreen({
    super.key,
    this.patientId,
  });

  @override
  State<LogSymptomScreen> createState() => _LogSymptomScreenState();
}

class _LogSymptomScreenState extends State<LogSymptomScreen> {
  final TextEditingController _symptomController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedSeverity = 'Moderate';

  bool _isSaving = false;

  final List<String> _severityOptions = [
    'Mild',
    'Moderate',
    'Severe',
  ];

  @override
  void dispose() {
    _symptomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSymptom() async {
    if (_isSaving) return;

    final String symptom =
        _symptomController.text.trim();

    final String notes =
        _notesController.text.trim();

    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a symptom name',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs =
          await SharedPreferences.getInstance();

      final String? token =
          prefs.getString('access_token');

      /*
       * نستخدم patientId الممرر للواجهة إن وجد.
       * وإذا الواجهة انفتحت بدون تمريره، نأخذه من
       * SharedPreferences لأنه محفوظ مسبقاً كـ
       * patient_profile.id.
       */
      final int? patientId =
          widget.patientId ??
          prefs.getInt('patient_id');

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Access token not found',
        );
      }

      if (patientId == null) {
        throw Exception(
          'Patient ID not found',
        );
      }

      final Uri url = Uri.parse(
        'http://$localhost:8000/api/v1/'
        'patients/$patientId/symptoms',
      );

      final Map<String, dynamic>
          requestBody = {
        'symptoms': [
          {
            'name': symptom,
            'severity':
                _selectedSeverity.toLowerCase(),
            'notes':
                notes.isEmpty ? null : notes,
            'started_at': null,
          }
        ],
      };

      final response =
          await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $token',
        },
        body: jsonEncode(
          requestBody,
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        print('');
        print('====================================');
        print('SYMPTOM SAVED SUCCESSFULLY');
        print('PATIENT ID: $patientId');
        print('SYMPTOM: $symptom');
        print(
          'SEVERITY: '
          '${_selectedSeverity.toLowerCase()}',
        );
        print('====================================');

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Symptom saved successfully',
            ),
            backgroundColor:
                Color(0xFF0DA89D),
          ),
        );

        Navigator.pop(
          context,
          true,
        );

        return;
      }

      throw Exception(
        'Failed to save symptom '
        '(${response.statusCode}): '
        '${response.body}',
      );
    } catch (e) {
      print('');
      print('====================================');
      print('SAVE SYMPTOM ERROR');
      print(e);
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save symptom: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 74,
        titleSpacing: 12,

        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home',
                    style: TextStyle(
                      color: Color(0xFF9AA6BE),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Log a symptom',
                    style: TextStyle(
                      color: Color(0xFF101A38),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HOW ARE YOU FEELING?',
                style: TextStyle(
                  color: Color(0xFF97A3BC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDE4EF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symptom',
                      style: TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _symptomController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Joint pain, fatigue, rash...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8D99B1),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDE4EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2868D7),
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Enter a symptom name',
                      style: TextStyle(
                        color: Color(0xFFE35B5B),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Severity',
                      style: TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDDE4EF),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSeverity,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF101A38),
                          ),
                          style: const TextStyle(
                            color: Color(0xFF101A38),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _severityOptions.map((severity) {
                            return DropdownMenuItem<String>(
                              value: severity,
                              child: Text(severity),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeverity = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'NOTES (OPTIONAL)',
                style: TextStyle(
                  color: Color(0xFF97A3BC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFDDE4EF),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Anything your care team should know?',
                      style: TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Onset, duration, possible triggers...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8D99B1),
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFD),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDE4EF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF2868D7),
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2D6CDE),
                        Color(0xFF11AAA6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2868D7)
                            .withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _saveSymptom,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Save symptom',
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
            ],
          ),
        ),
      ),
    );
  }
}