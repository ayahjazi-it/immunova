import 'package:flutter/material.dart';
import 'package:immunova/services/diagnosis_service.dart';
import 'package:immunova/treatment_plan_screen.dart';
import 'package:immunova/diagnostic_support_screen.dart';

class PredictionResultWidget extends StatefulWidget {
  final String patientName;

  final Map<String, double> probabilities;

  final int analysisId;
  final int predictionId;
  final int diseaseId;

  final VoidCallback? onClose;

  const PredictionResultWidget({
    super.key,
    required this.patientName,
    required this.probabilities,
    required this.analysisId,
    required this.predictionId,
    required this.diseaseId,
    this.onClose,
  });

  @override
  State<PredictionResultWidget> createState() => _PredictionResultWidgetState();
}

class _PredictionResultWidgetState extends State<PredictionResultWidget> {
  final DiagnosisService _diagnosisService = DiagnosisService();

  bool isConfirming = false;

  // CONFIRM PREDICTION

  Future<void> _confirmPrediction() async {
    if (isConfirming) return;

    setState(() {
      isConfirming = true;
    });

    try {
      final response = await _diagnosisService.confirmDiagnosis(
        analysisId: widget.analysisId,
        predictionId: widget.predictionId,
        diseaseId: widget.diseaseId,
      );

      final dynamic data = response['data'];

      if (data is! Map || data['id'] == null) {
        throw Exception('Diagnosis ID not returned');
      }

      final int diagnosisId = int.parse(data['id'].toString());

      print('Diagnosis ID: $diagnosisId');

      if (!mounted) return;

      /*
       * بعد نجاح Confirm Diagnosis
       * افتح مباشرة واجهة KBS.
       */
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TreatmentPlanScreen(diagnosisId: diagnosisId),
        ),
      );
    } catch (e) {
      print('CONFIRM DIAGNOSIS ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isConfirming = false;
        });
      }
    }
  }

  // ADD CLINICAL SYMPTOMS

  Future<void> _openDiagnosticSupport() async {
    print('ADD CLINICAL SYMPTOMS');
    print('Analysis ID: ${widget.analysisId}');
    print('Prediction ID: ${widget.predictionId}');

    if (!mounted) return;

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DiagnosticSupportScreen(
            analysisId: widget.analysisId,
            predictionId: widget.predictionId,
          ),
        ),
      );

      print('Returned result: $result');
    } catch (e) {
      print('DIAGNOSTIC SUPPORT ERROR');
      print(e);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = widget.probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final highestDisease = sortedEntries.isNotEmpty
        ? sortedEntries.first.key
        : '';

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(top: 18),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(color: const Color(0xff12aaa0), width: 1.3),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Prediction results',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff071b44),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${widget.patientName} · probability by condition',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff71809d),
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: widget.onClose,

                child: Container(
                  width: 28,
                  height: 28,

                  decoration: const BoxDecoration(
                    color: Color(0xfff1f4f8),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xff7c8aa4),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ...sortedEntries.map((entry) {
            final bool isHighest = entry.key == highestDisease;

            return _predictionRow(
              disease: entry.key,
              probability: entry.value,
              isHighest: isHighest,
            );
          }),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton(
              onPressed: isConfirming ? null : _confirmPrediction,

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff159fa4),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              child: isConfirming
                  ? const SizedBox(
                      width: 22,
                      height: 22,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      '✓  Confirm Prediction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 48,

            child: OutlinedButton(
              onPressed: _openDiagnosticSupport,

              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xff159fa4),

                side: const BorderSide(color: Color(0xff159fa4), width: 1.3),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              child: const Text(
                'Add Clinical Symptoms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionRow({
    required String disease,
    required double probability,
    required bool isHighest,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  disease,

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: isHighest ? FontWeight.bold : FontWeight.w600,

                    color: isHighest
                        ? const Color(0xff078d80)
                        : const Color(0xff17345f),
                  ),
                ),
              ),

              Text(
                '${probability.toStringAsFixed(1)}%',

                style: TextStyle(
                  fontSize: 12,

                  fontWeight: FontWeight.bold,

                  color: isHighest
                      ? const Color(0xff078d80)
                      : const Color(0xff17345f),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),

            child: LinearProgressIndicator(
              value: (probability / 100).clamp(0.0, 1.0),

              minHeight: 6,

              backgroundColor: const Color(0xffedf0f5),

              valueColor: AlwaysStoppedAnimation<Color>(
                isHighest ? const Color(0xff159f9a) : const Color(0xff9da9bc),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Divider(color: Color(0xffeef1f5), height: 1),
        ],
      ),
    );
  }
}
