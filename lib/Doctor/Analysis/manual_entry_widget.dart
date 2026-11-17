import 'package:flutter/material.dart';
import 'package:immunova/services/analysis_service.dart';

class ManualEntryWidget extends StatefulWidget {
  final int patientId;

  final void Function(
    Map<String, double> probabilities,
    int analysisId,
    int predictionId,
    int diseaseId,
  )
  onPrediction;

  const ManualEntryWidget({
    super.key,
    required this.patientId,
    required this.onPrediction,
  });

  @override
  State<ManualEntryWidget> createState() => _ManualEntryWidgetState();
}

class _ManualEntryWidgetState extends State<ManualEntryWidget> {
  final AnalysisService _analysisService = AnalysisService();

  String gender = 'Male';
  String hlaB27 = 'Negative';
  String ana = 'Negative';
  String antiRo = 'Negative';
  String antiLa = 'Negative';
  String antiDsDNA = 'Negative';
  String antiSm = 'Negative';

  bool isLoading = false;

  final esrController = TextEditingController();

  final crpController = TextEditingController();

  final rfController = TextEditingController();

  final antiCcpController = TextEditingController();

  final c3Controller = TextEditingController();

  final c4Controller = TextEditingController();

  @override
  void dispose() {
    esrController.dispose();
    crpController.dispose();
    rfController.dispose();
    antiCcpController.dispose();
    c3Controller.dispose();
    c4Controller.dispose();

    super.dispose();
  }

  double? _parseNumber(TextEditingController controller) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return double.tryParse(value);
  }

  bool _isPositive(String value) {
    return value == 'Positive';
  }

  double _toPercentage(dynamic value) {
    final parsed = double.tryParse(value.toString());

    if (parsed == null) {
      return 0;
    }

    if (parsed >= 0 && parsed <= 1) {
      return parsed * 100;
    }

    return parsed;
  }

  Map<String, double> _parseProbabilities(dynamic rawProbabilities) {
    final Map<String, double> result = {};

    if (rawProbabilities is Map) {
      rawProbabilities.forEach((key, value) {
        result[key.toString()] = _toPercentage(value);
      });

      return result;
    }

    if (rawProbabilities is List) {
      for (final item in rawProbabilities) {
        if (item is! Map) {
          continue;
        }

        String? diseaseName;

        final dynamic disease = item['disease'];

        if (disease is Map) {
          diseaseName = disease['name']?.toString();
        }

        diseaseName ??= item['disease_name']?.toString();

        diseaseName ??= item['name']?.toString();

        final dynamic probability =
            item['probability'] ?? item['value'] ?? item['confidence'];

        if (diseaseName == null || probability == null) {
          continue;
        }

        result[diseaseName] = _toPercentage(probability);
      }
    }

    return result;
  }

  Future<void> _runPrediction() async {
    if (isLoading) {
      return;
    }

    final esr = _parseNumber(esrController);

    final crp = _parseNumber(crpController);

    final rf = _parseNumber(rfController);

    final antiCcp = _parseNumber(antiCcpController);

    final c3 = _parseNumber(c3Controller);

    final c4 = _parseNumber(c4Controller);

    if (esr == null ||
        crp == null ||
        rf == null ||
        antiCcp == null ||
        c3 == null ||
        c4 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all laboratory values.')),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final markers = <String, dynamic>{
        'gender': gender.toLowerCase(),

        'esr': esr,

        'crp': crp,

        'rheumatoid_factor': rf,

        'anti_ccp': antiCcp,

        'hla_b27': _isPositive(hlaB27),

        'ana': _isPositive(ana),

        'anti_ro': _isPositive(antiRo),

        'anti_la': _isPositive(antiLa),

        'anti_dsdna': _isPositive(antiDsDNA),

        'anti_sm': _isPositive(antiSm),

        'c3': c3,

        'c4': c4,
      };

      print('Patient ID: ${widget.patientId}');

      print('Markers: $markers');

      final createResponse = await _analysisService.createAnalysis(
        patientId: widget.patientId,
        markers: markers,
      );

      final dynamic analysisIdValue = createResponse['data']?['id'];

      if (analysisIdValue == null) {
        throw Exception('Analysis ID not found in create response');
      }

      final int analysisId = int.parse(analysisIdValue.toString());

      print('');
      print('ANALYSIS SAVED SUCCESSFULLY');

      print('Analysis ID: $analysisId');

      final predictionResponse = await _analysisService.runPrediction(
        analysisId: analysisId,
      );

      final dynamic data = predictionResponse['data'];

      if (data == null || data is! Map) {
        throw Exception('Prediction data not found');
      }

      print('PREDICTION COMPLETED');

      print('Prediction ID: ${data['id']}');

      print('Predicted disease: ${data['predicted_disease']}');

      print('Confidence: ${data['confidence']}');

      print('Raw probabilities: ${data['probabilities']}');

      final dynamic predictionIdValue = data['id'];

      if (predictionIdValue == null) {
        throw Exception('Prediction ID not found');
      }

      final int predictionId = int.parse(predictionIdValue.toString());

      final dynamic predictedDisease = data['predicted_disease'];

      if (predictedDisease is! Map || predictedDisease['id'] == null) {
        throw Exception('Predicted disease ID not found');
      }

      final int diseaseId = int.parse(predictedDisease['id'].toString());

      print('ANALYSIS ID: $analysisId');

      print('PREDICTION ID: $predictionId');

      print('DISEASE ID: $diseaseId');

      final Map<String, double> probabilities = _parseProbabilities(
        data['probabilities'],
      );

      print('PARSED PROBABILITIES: $probabilities');

      if (probabilities.isEmpty) {
        throw Exception('Prediction completed but probabilities are empty');
      }

      if (!mounted) {
        return;
      }

      widget.onPrediction(probabilities, analysisId, predictionId, diseaseId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Analysis and prediction completed successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('ANALYSIS ERROR');

      print(e.toString());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xffdce4f0)),

        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Enter the patient's clinical markers below to run the autoimmune risk prediction model.",
            style: TextStyle(fontSize: 12, color: Color(0xff50658a)),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _dropdown('Gender', gender, ['Male', 'Female'], (value) {
                  setState(() {
                    gender = value!;
                  });
                }),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _numberField('ESR (mm/hr)', 'e.g. 43', esrController),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _numberField('CRP (mg/L)', 'e.g. 23.4', crpController),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _numberField(
                  'Rheumatoid Factor\n(IU/mL)',
                  'e.g. 26',
                  rfController,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  'Anti-CCP (U/mL)',
                  'e.g. 39',
                  antiCcpController,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _dropdown('HLA-B27', hlaB27, ['Negative', 'Positive'], (
                  value,
                ) {
                  setState(() {
                    hlaB27 = value!;
                  });
                }),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _dropdown('ANA', ana, ['Negative', 'Positive'], (value) {
                  setState(() {
                    ana = value!;
                  });
                }),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _dropdown('Anti-Ro', antiRo, ['Negative', 'Positive'], (
                  value,
                ) {
                  setState(() {
                    antiRo = value!;
                  });
                }),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _dropdown('Anti-La', antiLa, ['Negative', 'Positive'], (
                  value,
                ) {
                  setState(() {
                    antiLa = value!;
                  });
                }),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _dropdown(
                  'Anti-dsDNA',
                  antiDsDNA,
                  ['Negative', 'Positive'],
                  (value) {
                    setState(() {
                      antiDsDNA = value!;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _dropdown('Anti-Sm', antiSm, ['Negative', 'Positive'], (
                  value,
                ) {
                  setState(() {
                    antiSm = value!;
                  });
                }),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _numberField(
                  'Complement C3\n(mg/dL)',
                  'e.g. 119',
                  c3Controller,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  'Complement C4\n(mg/dL)',
                  'e.g. 41',
                  c4Controller,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(child: SizedBox()),
            ],
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 52,

            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff159fa4),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),

              onPressed: isLoading ? null : _runPrediction,

              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Run Prediction',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    String title,
    String hint,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            color: Color(0xff29466e),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        TextFormField(
          controller: controller,

          keyboardType: const TextInputType.numberWithOptions(decimal: true),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: const TextStyle(fontSize: 12),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            color: Color(0xff29466e),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 6),

        DropdownButtonFormField<String>(
          value: value,

          isExpanded: true,

          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),

          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,

              child: Text(item, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),

          onChanged: onChanged,
        ),
      ],
    );
  }
}
