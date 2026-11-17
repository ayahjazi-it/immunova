import 'package:flutter/material.dart';
import 'package:immunova/services/diagnostic_support_service.dart';

class DiagnosticSupportScreen extends StatefulWidget {
  final int analysisId;
  final int predictionId;

  const DiagnosticSupportScreen({
    super.key,
    required this.analysisId,
    required this.predictionId,
  });

  @override
  State<DiagnosticSupportScreen> createState() =>
      _DiagnosticSupportScreenState();
}

class _DiagnosticSupportScreenState
    extends State<DiagnosticSupportScreen> {
  final DiagnosticSupportService _service =
      DiagnosticSupportService();

  bool isLoading = true;
  bool isSending = false;

  String? errorMessage;

  String? sessionId;

  Map<String, dynamic>? currentQuestion;
  Map<String, dynamic>? finalResult;

  String? selectedAnswer;

  int questionNumber = 1;

  @override
  void initState() {
    super.initState();

    _startDiagnosticSupport();
  }

  // =========================================================
  // START DIAGNOSTIC SUPPORT
  // =========================================================

  Future<void> _startDiagnosticSupport() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentQuestion = null;
      finalResult = null;
      selectedAnswer = null;
      questionNumber = 1;
    });

    try {
      final response =
          await _service.startDiagnosticSupport(
        analysisId: widget.analysisId,
        predictionId: widget.predictionId,
      );

      if (!mounted) return;

      _handleResponse(response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // HANDLE BACKEND RESPONSE
  // =========================================================

  void _handleResponse(
    Map<String, dynamic> response,
  ) {
    final dynamic rawData = response['data'];

    Map<String, dynamic> data = {};

    if (rawData is Map) {
      data = Map<String, dynamic>.from(
        rawData,
      );
    }

    if (data['session_id'] != null) {
      sessionId =
          data['session_id'].toString();
    }

    final String type =
        data['type']
                ?.toString()
                .toLowerCase() ??
            '';

    print('');
    print('================================');
    print('DIAGNOSTIC SUPPORT RESPONSE');
    print('TYPE: $type');
    print('SESSION: $sessionId');
    print('DATA: $data');
    print('================================');

    // =======================================================
    // NEXT QUESTION
    // =======================================================

    if (type == 'question' &&
        data['question'] is Map) {
      setState(() {
        currentQuestion =
            Map<String, dynamic>.from(
          data['question'],
        );

        finalResult = null;
        selectedAnswer = null;
        errorMessage = null;
      });

      return;
    }

    // =======================================================
    // FINAL RESULT
    // =======================================================

    setState(() {
      currentQuestion = null;
      selectedAnswer = null;

      finalResult = data;

      errorMessage = null;
    });
  }

  // =========================================================
  // SUBMIT ANSWER
  // =========================================================

  Future<void> _submitAnswer() async {
    if (isSending) return;

    final question =
        currentQuestion;

    if (question == null) {
      return;
    }

    final String? questionId =
        question['id']?.toString();

    if (questionId == null ||
        questionId.isEmpty) {
      _showError(
        'Question ID was not returned from server.',
      );

      return;
    }

    if (selectedAnswer == null) {
      _showError(
        'Please select an answer first.',
      );

      return;
    }

    setState(() {
      isSending = true;
      errorMessage = null;
    });

    try {
      final response =
          await _service.answerQuestion(
        analysisId: widget.analysisId,
        predictionId: widget.predictionId,
        questionId: questionId,
        answer: selectedAnswer!,
      );

      if (!mounted) return;

      questionNumber++;

      _handleResponse(response);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });

      _showError(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // =========================================================
  // ERROR SNACKBAR
  // =========================================================

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        backgroundColor:
            Colors.red,
      ),
    );
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
          const Color(
        0xfff7f9fc,
      ),

      appBar: AppBar(
        elevation: 0,

        backgroundColor:
            Colors.white,

        foregroundColor:
            const Color(
          0xff071b44,
        ),

        title: const Text(
          'Clinical Symptoms',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? _buildLoading()
            : errorMessage != null &&
                    currentQuestion ==
                        null &&
                    finalResult == null
                ? _buildError()
                : finalResult != null
                    ? _buildResult()
                    : _buildQuestion(),
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          CircularProgressIndicator(
            color:
                Color(
              0xff159fa4,
            ),
          ),

          SizedBox(
            height: 18,
          ),

          Text(
            'Preparing clinical questions...',
            style: TextStyle(
              color:
                  Color(
                0xff71809d,
              ),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR SCREEN
  // =========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          24,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
              color: Colors.red,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              errorMessage ??
                  'Something went wrong.',
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(
              height: 20,
            ),

            ElevatedButton(
              onPressed:
                  _startDiagnosticSupport,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xff159fa4,
                ),

                foregroundColor:
                    Colors.white,
              ),

              child: const Text(
                'Try Again',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // QUESTION SCREEN
  // =========================================================

  Widget _buildQuestion() {
    final question =
        currentQuestion;

    if (question == null) {
      return const Center(
        child: Text(
          'No question returned.',
        ),
      );
    }

    final String questionText =
        question['question']
                ?.toString() ??
            'Clinical question';

    final String responseType =
        question['response_type']
                ?.toString() ??
            '';

    final dynamic rawOptions =
        question['options'];

    final List<Map<String, dynamic>>
        options = [];

    if (rawOptions is List) {
      for (final item
          in rawOptions) {
        if (item is Map) {
          options.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(
        20,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ===================================================
          // HEADER
          // ===================================================

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              16,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffeaf8f7,
              ),

              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Row(
                  children: [
                    Icon(
                      Icons
                          .medical_information_outlined,
                      color:
                          Color(
                        0xff159fa4,
                      ),
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'Diagnostic Support',
                      style:
                          TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Color(
                          0xff071b44,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Answer the following clinical questions to support the AI prediction.',
                  style:
                      TextStyle(
                    fontSize:
                        12,
                    color:
                        Color(
                      0xff71809d,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  'Question $questionNumber',
                  style:
                      const TextStyle(
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight
                            .w600,
                    color:
                        Color(
                      0xff159fa4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // ===================================================
          // QUESTION CARD
          // ===================================================

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              18,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              border:
                  Border.all(
                color:
                    const Color(
                  0xffe2e8f0,
                ),
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  questionText,

                  style:
                      const TextStyle(
                    fontSize:
                        16,
                    height:
                        1.5,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        Color(
                      0xff071b44,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  responseType ==
                          'single_choice'
                      ? 'Select one answer'
                      : 'Select an answer',

                  style:
                      const TextStyle(
                    fontSize:
                        12,
                    color:
                        Color(
                      0xff71809d,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                ...options.map(
                  (option) {
                    final String? value =
                        option['value']
                            ?.toString();

                    final String label =
                        option['label']
                                ?.toString() ??
                            value ??
                            '';

                    if (value == null) {
                      return const SizedBox
                          .shrink();
                    }

                    return _buildOption(
                      value:
                          value,
                      label:
                          label,
                    );
                  },
                ),
              ],
            ),
          ),

          if (errorMessage != null)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 14,
              ),

              child: Text(
                errorMessage!,

                style:
                    const TextStyle(
                  color:
                      Colors.red,
                  fontSize:
                      12,
                ),
              ),
            ),

          const SizedBox(
            height: 24,
          ),

          // ===================================================
          // CONTINUE BUTTON
          // ===================================================

          SizedBox(
            width:
                double.infinity,
            height:
                54,

            child:
                ElevatedButton(
              onPressed:
                  selectedAnswer ==
                              null ||
                          isSending
                      ? null
                      : _submitAnswer,

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    const Color(
                  0xff159fa4,
                ),

                foregroundColor:
                    Colors.white,

                disabledBackgroundColor:
                    const Color(
                  0xffcbd5e1,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    16,
                  ),
                ),
              ),

              child: isSending
                  ? const SizedBox(
                      width:
                          22,
                      height:
                          22,

                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        fontSize:
                            15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OPTION
  // =========================================================

  Widget _buildOption({
    required String value,
    required String label,
  }) {
    final bool selected =
        selectedAnswer ==
            value;

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 10,
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(
          14,
        ),

        onTap: isSending
            ? null
            : () {
                setState(() {
                  selectedAnswer =
                      value;
                });
              },

        child:
            AnimatedContainer(
          duration:
              const Duration(
            milliseconds:
                150,
          ),

          width:
              double.infinity,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 14,
          ),

          decoration:
              BoxDecoration(
            color: selected
                ? const Color(
                    0xffeaf8f7,
                  )
                : const Color(
                    0xfff8fafc,
                  ),

            borderRadius:
                BorderRadius.circular(
              14,
            ),

            border:
                Border.all(
              color: selected
                  ? const Color(
                      0xff159fa4,
                    )
                  : const Color(
                      0xffe2e8f0,
                    ),

              width:
                  selected
                      ? 1.5
                      : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,

                  border:
                      Border.all(
                    color: selected
                        ? const Color(
                            0xff159fa4,
                          )
                        : const Color(
                            0xff9ca3af,
                          ),

                    width: 2,
                  ),
                ),

                child: selected
                    ? Center(
                        child:
                            Container(
                          width: 10,
                          height: 10,

                          decoration:
                              const BoxDecoration(
                            color:
                                Color(
                              0xff159fa4,
                            ),

                            shape:
                                BoxShape
                                    .circle,
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Text(
                  label,

                  style:
                      TextStyle(
                    fontSize:
                        14,

                    fontWeight:
                        selected
                            ? FontWeight
                                .w600
                            : FontWeight
                                .normal,

                    color:
                        const Color(
                      0xff17345f,
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

  // =========================================================
  // FINAL CLINICAL ASSESSMENT
  // =========================================================

  Widget _buildResult() {
    final result =
        finalResult ?? {};

    final String predictedDiagnosis =
        result['predicted_diagnosis']
                ?.toString() ??
            'Clinical Assessment';

    final String interpretation =
        result['interpretation']
                ?.toString() ??
            'Clinical assessment completed.';

    // =======================================================
    // CLINICAL SUPPORT
    // =======================================================

    final Map<String, dynamic>
        clinicalSupport =
        result['clinical_support']
                is Map
            ? Map<String, dynamic>.from(
                result[
                    'clinical_support'],
              )
            : {};

    final String supportLabel =
        clinicalSupport['label']
                ?.toString() ??
            clinicalSupport['level']
                ?.toString() ??
            'Assessment complete';

    final String supportLevel =
        clinicalSupport['level']
                ?.toString()
                .toLowerCase() ??
            '';

    final double? cf =
        double.tryParse(
      clinicalSupport['cf']
              ?.toString() ??
          '',
    );

    // =======================================================
    // SUPPORTING FINDINGS
    // =======================================================

    final List<String>
        supportingFindings =
        [];

    final dynamic rawSupporting =
        result[
            'supporting_findings'];

    if (rawSupporting is List) {
      for (final item
          in rawSupporting) {
        if (item != null) {
          supportingFindings.add(
            item.toString(),
          );
        }
      }
    }

    // =======================================================
    // CONFLICTING FINDINGS
    // =======================================================

    final List<String>
        conflictingFindings =
        [];

    final dynamic rawConflicting =
        result[
            'conflicting_findings'];

    if (rawConflicting is List) {
      for (final item
          in rawConflicting) {
        if (item != null) {
          conflictingFindings.add(
            item.toString(),
          );
        }
      }
    }

    // =======================================================
    // COLORS BASED ON SUPPORT LEVEL
    // =======================================================

    Color supportColor;
    Color supportBackground;

    if (supportLevel ==
        'strong') {
      supportColor =
          const Color(
        0xff078d80,
      );

      supportBackground =
          const Color(
        0xffe7f8f5,
      );
    } else if (supportLevel ==
        'moderate') {
      supportColor =
          const Color(
        0xffb7791f,
      );

      supportBackground =
          const Color(
        0xfffff7dd,
      );
    } else if (supportLevel ==
            'limited' ||
        supportLevel ==
            'weak') {
      supportColor =
          const Color(
        0xff2563eb,
      );

      supportBackground =
          const Color(
        0xffeaf2ff,
      );
    } else {
      supportColor =
          const Color(
        0xff159fa4,
      );

      supportBackground =
          const Color(
        0xffeaf8f7,
      );
    }

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(
        20,
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'CLINICAL ASSESSMENT',

            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  FontWeight.bold,
              color: Color(
                0xff8290aa,
              ),
              letterSpacing:
                  0.5,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              18,
            ),

            decoration:
                BoxDecoration(
              color:
                  Colors.white,

              borderRadius:
                  BorderRadius.circular(
                20,
              ),

              border:
                  Border.all(
                color:
                    const Color(
                  0xff15b8ae,
                ),
                width:
                    1.2,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ===========================================
                // SUPPORT BADGE
                // ===========================================

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        10,
                    vertical:
                        6,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        supportBackground,

                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                  ),

                  child: Text(
                    supportLabel,

                    style:
                        TextStyle(
                      fontSize:
                          11,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          supportColor,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                // ===========================================
                // DIAGNOSIS NAME
                // ===========================================

                Text(
                  predictedDiagnosis,

                  style:
                      const TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight
                            .bold,
                    color:
                        Color(
                      0xff071b44,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ===========================================
                // INTERPRETATION
                // ===========================================

                Text(
                  interpretation,

                  style:
                      const TextStyle(
                    fontSize:
                        13,
                    height:
                        1.55,
                    color:
                        Color(
                      0xff5f6f89,
                    ),
                  ),
                ),

                // ===========================================
                // CLINICAL SUPPORT SCORE
                // ===========================================

                if (cf !=
                    null) ...[
                  const SizedBox(
                    height:
                        16,
                  ),

                  Row(
                    children: [
                      const Text(
                        'Clinical support score',
                        style:
                            TextStyle(
                          fontSize:
                              11,
                          color:
                              Color(
                            0xff8290aa,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Text(
                        '${(cf * 100).toStringAsFixed(1)}%',

                        style:
                            TextStyle(
                          fontSize:
                              12,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color:
                              supportColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        7,
                  ),

                  ClipRRect(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),

                    child:
                        LinearProgressIndicator(
                      value:
                          cf.clamp(
                        0.0,
                        1.0,
                      ),

                      minHeight:
                          6,

                      backgroundColor:
                          const Color(
                        0xffedf1f6,
                      ),

                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        supportColor,
                      ),
                    ),
                  ),
                ],

                // ===========================================
                // SUPPORTING FINDINGS
                // ===========================================

                if (supportingFindings
                    .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        24,
                  ),

                  const Text(
                    'Supporting findings',

                    style:
                        TextStyle(
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          Color(
                        0xff071b44,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  ...supportingFindings
                      .map(
                    (finding) =>
                        _buildClinicalFindingRow(
                      text:
                          finding,
                      supported:
                          true,
                    ),
                  ),
                ],

                // ===========================================
                // CONFLICTING FINDINGS
                // ===========================================

                if (conflictingFindings
                    .isNotEmpty) ...[
                  const SizedBox(
                    height:
                        20,
                  ),

                  const Text(
                    'Conflicting findings',

                    style:
                        TextStyle(
                      fontSize:
                          12,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          Color(
                        0xff071b44,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  ...conflictingFindings
                      .map(
                    (finding) =>
                        _buildClinicalFindingRow(
                      text:
                          finding,
                      supported:
                          false,
                    ),
                  ),
                ],

                // ===========================================
                // NO CONFLICTING FINDINGS
                // ===========================================

                if (conflictingFindings
                    .isEmpty) ...[
                  const SizedBox(
                    height:
                        18,
                  ),

                  _buildNoConflictingFindings(),
                ],

                const SizedBox(
                  height: 24,
                ),

                // ===========================================
                // BACK TO PREDICTION
                // ===========================================

                SizedBox(
                  width:
                      double.infinity,

                  height:
                      52,

                  child:
                      ElevatedButton.icon(
                    onPressed:
                        () {
                      Navigator.pop(
                        context,
                        result,
                      );
                    },

                    icon:
                        const Icon(
                      Icons
                          .arrow_back,
                      size:
                          18,
                    ),

                    label:
                        const Text(
                      'Back to Prediction',

                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xff159fa4,
                      ),

                      foregroundColor:
                          Colors.white,

                      elevation:
                          0,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CLINICAL FINDING ROW
  // =========================================================

  Widget _buildClinicalFindingRow({
    required String text,
    required bool supported,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      decoration:
          const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(
            color:
                Color(
              0xffedf1f5,
            ),
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 30,
            height: 30,

            decoration:
                BoxDecoration(
              color: supported
                  ? const Color(
                      0xffe7f8f5,
                    )
                  : const Color(
                      0xffffeeee,
                    ),

              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),

            child: Icon(
              supported
                  ? Icons.check
                  : Icons.close,

              size: 18,

              color: supported
                  ? const Color(
                      0xff159fa4,
                    )
                  : Colors.red,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  text,

                  style:
                      const TextStyle(
                    fontSize:
                        12,
                    height:
                        1.4,
                    fontWeight:
                        FontWeight
                            .w600,
                    color:
                        Color(
                      0xff17345f,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  supported
                      ? 'Supports current prediction'
                      : 'Conflicts with current prediction',

                  style:
                      TextStyle(
                    fontSize:
                        10,

                    color: supported
                        ? const Color(
                            0xff159fa4,
                          )
                        : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NO CONFLICTING FINDINGS
  // =========================================================

  Widget _buildNoConflictingFindings() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 30,
            height: 30,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffe7f8f5,
              ),

              borderRadius:
                  BorderRadius.circular(
                9,
              ),
            ),

            child:
                const Icon(
              Icons.check,
              size: 18,
              color:
                  Color(
                0xff159fa4,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  'No conflicting clinical findings identified.',

                  style:
                      TextStyle(
                    fontSize:
                        12,
                    height:
                        1.4,
                    fontWeight:
                        FontWeight
                            .w600,
                    color:
                        Color(
                      0xff17345f,
                    ),
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'No',

                  style:
                      TextStyle(
                    fontSize:
                        10,
                    color:
                        Color(
                      0xff8290aa,
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
}