import 'package:flutter/material.dart';
import 'package:immunova/model/get_all_patients.dart';
import 'package:immunova/services/get_all_patients_service.dart';
import 'manual_entry_widget.dart';
import 'image_upload_widget.dart';
import 'prediction_result_widget.dart';

class NewAnalysisScreen extends StatefulWidget {
  final int? patientId;

  const NewAnalysisScreen({
    super.key,
    this.patientId,
  });

  @override
  State<NewAnalysisScreen> createState() =>
      _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  int selectedMethod = 0;

  int? selectedPatientId;

  Map<String, double>? predictionResults;

  int? predictionAnalysisId;

  int? predictionId;

  int? predictionDiseaseId;

  final PatientService _patientService = PatientService();

  final ScrollController _scrollController = ScrollController();

  List<Data> patients = [];

  bool isLoadingPatients = true;

  String? patientsError;

  @override
  void initState() {
    super.initState();

    selectedPatientId = widget.patientId;

    _loadPatients();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      isLoadingPatients = true;

      patientsError = null;
    });

    try {
      final response = await _patientService.getPatients();

      if (!mounted) {
        return;
      }

      if (response == null) {
        setState(() {
          isLoadingPatients = false;

          patientsError = 'Failed to load patients.';
        });

        return;
      }

      final loadedPatients = response.data ?? [];

      setState(() {
        patients = loadedPatients;

        isLoadingPatients = false;

        if (patients.isNotEmpty) {
          if (selectedPatientId == null ||
              !patients.any(
                (patient) =>
                    patient.id == selectedPatientId,
              )) {
            selectedPatientId = patients.first.id;
          }
        } else {
          selectedPatientId = null;
        }
      });

      print('PATIENTS LOADED');

      print('COUNT: ${patients.length}');

      for (final patient in patients) {
        print('ID: ${patient.id} - NAME: ${patient.name}');
      }
    } catch (e) {
      print('LOAD PATIENTS ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingPatients = false;

        patientsError = 'Failed to load patients.';
      });
    }
  }

  String get selectedPatientName {
    if (selectedPatientId == null) {
      return 'Patient';
    }

    try {
      final patient = patients.firstWhere(
        (patient) => patient.id == selectedPatientId,
      );

      return patient.name ?? 'Patient';
    } catch (_) {
      return 'Patient';
    }
  }

  void _clearPrediction() {
    setState(() {
      predictionResults = null;

      predictionAnalysisId = null;

      predictionId = null;

      predictionDiseaseId = null;
    });
  }

  void _scrollToPrediction() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildSelectedMethod() {
    /*
     * MANUAL ENTRY
     */
    if (selectedMethod == 0) {
      if (selectedPatientId == null) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Please select a patient first.',
              style: TextStyle(color: Color(0xff50658a)),
            ),
          ),
        );
      }

      return ManualEntryWidget(
        key: ValueKey(selectedPatientId),

        patientId: selectedPatientId!,

        /*
         * النتيجة القادمة من
         * ManualEntryWidget:
         *
         * probabilities
         * analysisId
         * predictionId
         * diseaseId
         */
        onPrediction: (
          results,
          analysisId,
          newPredictionId,
          diseaseId,
        ) {
          setState(() {
            predictionResults = results;

            predictionAnalysisId = analysisId;

            predictionId = newPredictionId;

            predictionDiseaseId = diseaseId;
          });

          print('SHOWING PREDICTION RESULT WIDGET');

          print('ANALYSIS ID: $analysisId');

          print('PREDICTION ID: $newPredictionId');

          print('DISEASE ID: $diseaseId');

          print('PROBABILITIES: $results');

          /*
           * انزل تلقائياً
           * إلى نتيجة التنبؤ
           */
          _scrollToPrediction();
        },
      );
    }

    /*
     * IMAGE
     */
    if (selectedPatientId == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Please select a patient first.',
            style: TextStyle(
              color: Color(0xff50658a),
            ),
          ),
        ),
      );
    }

    return ImageUploadWidget(
      patientId: selectedPatientId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        controller: _scrollController,

        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'START A NEW ANALYSIS',
              style: TextStyle(
                color: Color(0xff8a9abd),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            /*
             * PATIENT SELECTOR
             */
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xffdce4f0),
                ),
                borderRadius: BorderRadius.circular(22),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Patient',
                    style: TextStyle(
                      color: Color(0xff17345f),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (isLoadingPatients)
                    const SizedBox(
                      height: 50,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (patientsError != null)
                    Column(
                      children: [
                        Text(
                          patientsError!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: _loadPatients,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  else if (patients.isEmpty)
                    const Text(
                      'No patients found.',
                      style: TextStyle(
                        color: Color(0xff50658a),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedPatientId,

                      isExpanded: true,

                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),

                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                          borderSide:
                              const BorderSide(
                            color: Color(0xffdce4f0),
                          ),
                        ),
                      ),

                      items: patients.map((patient) {
                        return DropdownMenuItem<int>(
                          value: patient.id,
                          child: Text(
                            patient.name ??
                                'Unknown patient',
                          ),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedPatientId = value;

                          /*
                           * عند تغيير المريض
                           * امسح كل نتيجة قديمة
                           */
                          predictionResults = null;

                          predictionAnalysisId = null;

                          predictionId = null;

                          predictionDiseaseId = null;
                        });

                        print(
                          'SELECTED PATIENT ID: $value',
                        );

                        print(
                          'SELECTED PATIENT NAME: $selectedPatientName',
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'INPUT METHOD',
              style: TextStyle(
                color: Color(0xff8a9abd),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 10),

            /*
             * INPUT METHOD BUTTONS
             */
            Row(
              children: [
                Expanded(
                  child: _methodButton(
                    index: 0,
                    icon: Icons.edit_outlined,
                    title: 'Manual Entry',
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: _methodButton(
                    index: 1,
                    icon: Icons.image_outlined,
                    title: 'Upload Image',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /*
             * MANUAL / IMAGE CONTENT
             */
            _buildSelectedMethod(),

            /*
             * PREDICTION RESULT
             *
             * ما بتظهر إلا إذا
             * كل شيء موجود:
             *
             * probabilities
             * analysisId
             * predictionId
             * diseaseId
             */
            if (predictionResults != null &&
                predictionAnalysisId != null &&
                predictionId != null &&
                predictionDiseaseId != null)
              PredictionResultWidget(
                patientName: selectedPatientName,

                probabilities: predictionResults!,

                analysisId: predictionAnalysisId!,

                predictionId: predictionId!,

                diseaseId: predictionDiseaseId!,

                onClose: _clearPrediction,
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _methodButton({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool selected = selectedMethod == index;

    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        setState(() {
          selectedMethod = index;

          /*
           * عند تغيير
           * طريقة الإدخال
           * امسح النتيجة السابقة
           */
          predictionResults = null;

          predictionAnalysisId = null;

          predictionId = null;

          predictionDiseaseId = null;
        });
      },

      child: Container(
        height: 75,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(
            color: selected
                ? const Color(0xff2563eb)
                : const Color(0xffdce4f0),
            width: selected ? 1.5 : 1,
          ),
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 32,

              height: 32,

              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xff3168dc)
                    : const Color(0xffeaf2ff),

                borderRadius: BorderRadius.circular(9),
              ),

              child: Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : const Color(0xff3974dc),
              ),
            ),

            const SizedBox(height: 5),

            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: selected
                    ? const Color(0xff2856c7)
                    : const Color(0xff17345f),
              ),
            ),
          ],
        ),
      ),
    );
  }
}