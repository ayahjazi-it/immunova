import 'package:flutter/material.dart';
import 'package:immunova/Doctor/edot_treatment_plan_screen.dart';

import 'package:immunova/services/treatment_plan_service.dart';


class TreatmentPlanScreen extends StatefulWidget {
  final int diagnosisId;

  const TreatmentPlanScreen({
    super.key,
    required this.diagnosisId,
  });

  @override
  State<TreatmentPlanScreen> createState() =>
      _TreatmentPlanScreenState();
}

class _TreatmentPlanScreenState
    extends State<TreatmentPlanScreen> {
  final TreatmentPlanService _service =
      TreatmentPlanService();

  bool isLoading = true;
  bool isAnswering = false;
  bool isReviewing = false;
  bool isApproved = false;

  String? errorMessage;

  String? sessionId;

  Map<String, dynamic>? currentQuestion;

  Map<String, dynamic>? treatmentPlanData;

  int questionNumber = 1;

  @override
  void initState() {
    super.initState();

    _startTreatmentPlan();
  }

  Future<void> _startTreatmentPlan() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response =
          await _service.startTreatmentPlan(
        diagnosisId: widget.diagnosisId,
      );

      _handleKbsResponse(response);
    } catch (e) {
      print('START TREATMENT ERROR: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _handleKbsResponse(
    Map<String, dynamic> response,
  ) {
    final dynamic rawData =
        response['data'];

    if (rawData is! Map) {
      throw Exception(
        'Invalid treatment plan response',
      );
    }

    final Map<String, dynamic> data =
        Map<String, dynamic>.from(
      rawData,
    );

    sessionId =
        data['session_id']?.toString();

    final String type =
        data['type']?.toString() ?? '';

    print('');
    print('========================');
    print('KBS RESPONSE TYPE: $type');
    print('SESSION: $sessionId');
    print('FULL KBS DATA: $data');
    print('========================');

    if (type == 'question') {
      final dynamic rawQuestion =
          data['question'];

      if (rawQuestion is! Map) {
        throw Exception(
          'Question not found in KBS response',
        );
      }

      setState(() {
        currentQuestion =
            Map<String, dynamic>.from(
          rawQuestion,
        );

        treatmentPlanData = null;

        isLoading = false;
        isAnswering = false;
      });

      return;
    }

    /*
     * هون وصلنا للنتيجة النهائية
     *
     * الشكل الحقيقي عندك:
     *
     * {
     *   "type": "result",
     *   "assessment": {...},
     *   "treatment_plan": {
     *      "id": 1,
     *      "items": [...]
     *   }
     * }
     */
    setState(() {
      currentQuestion = null;

      treatmentPlanData = data;

      isLoading = false;
      isAnswering = false;
    });

    print('');
    print('========================');
    print('TREATMENT PLAN RESULT');
    print('DATA: $data');
    print(
      'EXTRACTED ITEMS: ${_extractPlanItems(data)}',
    );
    print('========================');
  }

  Future<void> _selectAnswer(
    String questionId,
    String answer,
  ) async {
    if (isAnswering) return;

    setState(() {
      isAnswering = true;
      errorMessage = null;
    });

    try {
      final response =
          await _service.answerQuestion(
        diagnosisId: widget.diagnosisId,
        questionId: questionId,
        answer: answer,
      );

      if (!mounted) return;

      final dynamic rawData =
          response['data'];

      final bool nextIsQuestion =
          rawData is Map &&
              rawData['type']
                      ?.toString() ==
                  'question';

      _handleKbsResponse(response);

      if (nextIsQuestion) {
        setState(() {
          questionNumber++;
        });
      }
    } catch (e) {
      print(
        'ANSWER QUESTION ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isAnswering = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        foregroundColor:
            const Color(
          0xff071b44,
        ),

        title: const Text(
          'Treatment Plan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: isLoading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(
                  20,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    if (currentQuestion != null)
                      const Text(
                        'CLINICAL QUESTIONS',
                        style: TextStyle(
                          color:
                              Color(
                            0xff94a1b8,
                          ),
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),

                    if (currentQuestion != null)
                      const SizedBox(
                        height: 16,
                      ),

                    if (errorMessage != null)
                      _errorBox(),

                    if (currentQuestion != null)
                      _questionCard(),

                    if (treatmentPlanData !=
                        null)
                      _treatmentPlanCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 15,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(
          0xffffeeee,
        ),

        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      child: Text(
        errorMessage!,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _questionCard() {
    final Map<String, dynamic> question =
        currentQuestion!;

    final String questionId =
        question['id']
                ?.toString() ??
            '';

    final String questionText =
        question['question']
                ?.toString() ??
            '';

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

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        border:
            Border.all(
          color:
              const Color(
            0xffdfe6f1,
          ),
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Question $questionNumber',

            style:
                const TextStyle(
              color:
                  Color(
                0xff94a1b8,
              ),
              fontSize:
                  15,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            questionText,

            style:
                const TextStyle(
              color:
                  Color(
                0xff102344,
              ),
              fontSize:
                  20,
              height:
                  1.45,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            responseType ==
                    'single_choice'
                ? 'Select one answer'
                : 'Select an answer',

            style:
                const TextStyle(
              color:
                  Color(
                0xff94a1b8,
              ),
              fontSize:
                  15,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          ...options.map(
            (option) {
              final String label =
                  option['label']
                          ?.toString() ??
                      '';

              final String value =
                  option['value']
                          ?.toString() ??
                      '';

              return Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 12,
                ),

                child:
                    SizedBox(
                  width:
                      double.infinity,

                  child:
                      OutlinedButton(
                    onPressed:
                        isAnswering
                            ? null
                            : () {
                                print('');
                                print(
                                  '========================',
                                );
                                print(
                                  'USER SELECTED OPTION',
                                );
                                print(
                                  'QUESTION ID: $questionId',
                                );
                                print(
                                  'LABEL: $label',
                                );
                                print(
                                  'VALUE: $value',
                                );
                                print(
                                  '========================',
                                );

                                _selectAnswer(
                                  questionId,
                                  value,
                                );
                              },

                    style:
                        OutlinedButton
                            .styleFrom(
                      alignment:
                          Alignment
                              .centerLeft,

                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal:
                            18,
                        vertical:
                            20,
                      ),

                      side:
                          const BorderSide(
                        color:
                            Color(
                          0xffdfe6f1,
                        ),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),
                    ),

                    child:
                        Text(
                      label,

                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xff102344,
                        ),
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          if (isAnswering)
            const Padding(
              padding:
                  EdgeInsets.only(
                top: 8,
              ),

              child:
                  Center(
                child:
                    CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }


  Future<void> _approveTreatmentPlan(
    int treatmentPlanId,
  ) async {
    if (isReviewing || isApproved) {
      return;
    }

    setState(() {
      isReviewing = true;
      errorMessage = null;
    });

    try {
      print('');
      print('========================');
      print('APPROVING TREATMENT PLAN');
      print('TREATMENT PLAN ID: $treatmentPlanId');
      print('========================');

      final response =
          await _service.reviewTreatmentPlan(
        treatmentPlanId: treatmentPlanId,
        status: 'approved',
        doctorNotes: 'Approved by doctor.',
      );

      print('');
      print('========================');
      print('TREATMENT PLAN APPROVED');
      print('RESPONSE: $response');
      print('========================');

      if (!mounted) return;

      setState(() {
        isApproved = true;
        isReviewing = false;

        final dynamic rawPlan =
            treatmentPlanData?['treatment_plan'];

        if (rawPlan is Map) {
          rawPlan['status'] = 'approved';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Treatment plan approved successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('');
      print('========================');
      print('APPROVE TREATMENT PLAN ERROR');
      print(e);
      print('========================');

      if (!mounted) return;

      setState(() {
        isReviewing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to approve treatment plan: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openEditTreatmentPlan(
    Map<String, dynamic> treatmentPlan,
  ) async {
    final int? treatmentPlanId =
        int.tryParse(
      treatmentPlan['id']?.toString() ??
          '',
    );

    if (treatmentPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Treatment plan ID not found.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>>
        initialItems = [];

    final dynamic rawItems =
        treatmentPlan['items'];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          initialItems.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    final updatedPlan =
        await Navigator.push<
            Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTreatmentPlanScreen(
          treatmentPlanId:
              treatmentPlanId,
          initialItems:
              initialItems,
        ),
      ),
    );

    if (!mounted ||
        updatedPlan == null) {
      return;
    }

    setState(() {
      final dynamic rawPlan =
          treatmentPlanData?[
              'treatment_plan'];

      if (rawPlan is Map) {
        treatmentPlanData![
                'treatment_plan'] =
            updatedPlan;
      }

      isApproved =
          updatedPlan['status']
                  ?.toString() ==
              'approved';
    });

    print('');
    print('========================');
    print('TREATMENT PLAN UPDATED IN UI');
    print(
      'UPDATED PLAN: $updatedPlan',
    );
    print('========================');
  }

  Widget _treatmentPlanCard() {
    final List<String> items =
        _extractPlanItems(
      treatmentPlanData!,
    );

    final Map<String, dynamic>?
        treatmentPlan =
        _extractTreatmentPlanMap(
      treatmentPlanData!,
    );

    final String status =
        treatmentPlan?['status']
                ?.toString() ??
            'pending';

    final String modelVersion =
        treatmentPlan?[
                    'ai_model_version']
                ?.toString() ??
            '';

    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        22,
      ),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        border:
            Border.all(
          color:
              const Color(
            0xffdfe6f1,
          ),
        ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),
      ),

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const Expanded(
                child:
                    Text(
                  'AI\nTreatment\nPlan',

                  style:
                      TextStyle(
                    color:
                        Color(
                      0xff102344,
                    ),
                    fontSize:
                        21,
                    height:
                        1.3,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal:
                      12,
                  vertical:
                      7,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xfffff0df,
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child:
                    Text(
                  'AI Generated · ${status == 'pending' ? 'Pending review' : status}',

                  style:
                      const TextStyle(
                    color:
                        Color(
                      0xffa65d08,
                    ),
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Generated by Immunova AI — review before applying to the patient record.',

            style:
                TextStyle(
              color:
                  Color(
                0xff94a1b8,
              ),
              height:
                  1.4,
              fontSize:
                  14,
            ),
          ),

          if (modelVersion.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),

            Text(
              'Model: $modelVersion',

              style:
                  const TextStyle(
                color:
                    Color(
                  0xff94a1b8,
                ),
                fontSize:
                    11,
              ),
            ),
          ],

          const SizedBox(
            height: 20,
          ),

          /*
           * هون العناصر الحقيقية
           * القادمة من:
           *
           * treatment_plan.items
           */
          if (items.isEmpty)
            const Text(
              'No treatment plan items were returned.',

              style:
                  TextStyle(
                color:
                    Colors.red,
              ),
            )
          else
            ...items.map(
              (item) =>
                  _planItem(
                item,
              ),
            ),

          const SizedBox(
            height: 22,
          ),

          Row(
            children: [
              Expanded(
                child:
                    OutlinedButton.icon(
                  onPressed:
                      treatmentPlan == null
                          ? null
                          : () {
                              _openEditTreatmentPlan(
                                treatmentPlan,
                              );
                            },

                  icon:
                      const Icon(
                    Icons.edit_outlined,
                  ),

                  label:
                      const Text(
                    'Edit',
                  ),

                  style:
                      OutlinedButton
                          .styleFrom(
                    foregroundColor:
                        const Color(
                      0xff2856c7,
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical:
                          16,
                    ),

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

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    ElevatedButton.icon(
                  onPressed:
                      isReviewing || isApproved
                          ? null
                          : () {
                              final dynamic
                                  treatmentPlanIdValue =
                                  treatmentPlan?['id'];

                              if (treatmentPlanIdValue ==
                                  null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Treatment plan ID not found.',
                                    ),
                                    backgroundColor:
                                        Colors.red,
                                  ),
                                );

                                return;
                              }

                              final int treatmentPlanId =
                                  int.parse(
                                treatmentPlanIdValue
                                    .toString(),
                              );

                              _approveTreatmentPlan(
                                treatmentPlanId,
                              );
                            },

                  icon:
                      isReviewing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              isApproved
                                  ? Icons.check_circle
                                  : Icons.check,
                              color: Colors.white,
                            ),

                  label:
                      Text(
                    isApproved
                        ? 'Approved'
                        : isReviewing
                            ? 'Approving...'
                            : 'Approve',

                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                    ),
                  ),

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xff159fa4,
                    ),

                    disabledBackgroundColor:
                        const Color(
                      0xff159fa4,
                    ),

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical:
                          16,
                    ),

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

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child:
                    TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child:
                      const Text(
                    'Cancel',

                    style:
                        TextStyle(
                      color:
                          Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*
   * ============================================
   * استخراج treatment_plan نفسه
   * ============================================
   */
  Map<String, dynamic>?
      _extractTreatmentPlanMap(
    Map<String, dynamic> data,
  ) {
    final dynamic rawTreatmentPlan =
        data['treatment_plan'];

    if (rawTreatmentPlan is Map) {
      return Map<String, dynamic>.from(
        rawTreatmentPlan,
      );
    }

    return null;
  }

  /*
   * ============================================
   * استخراج عناصر الخطة
   *
   * الشكل الحقيقي القادم من الباك:
   *
   * data
   *   ↓
   * treatment_plan
   *   ↓
   * items
   *   ↓
   * content
   * ============================================
   */
  List<String> _extractPlanItems(
    Map<String, dynamic> data,
  ) {
    final List<String> result =
        [];

    dynamic rawItems;

    /*
     * أولاً الشكل الحقيقي عندك
     */
    final dynamic rawTreatmentPlan =
        data['treatment_plan'];

    if (rawTreatmentPlan is Map) {
      rawItems =
          rawTreatmentPlan['items'];
    }

    /*
     * fallback لأي شكل آخر
     */
    rawItems ??=
        data['items'];

    rawItems ??=
        data['recommendations'];

    rawItems ??=
        data['plan_items'];

    if (rawItems is List) {
      for (final item
          in rawItems) {
        /*
         * إذا العنصر String مباشرة
         */
        if (item is String) {
          final text =
              item.trim();

          if (text.isNotEmpty) {
            result.add(
              text,
            );
          }

          continue;
        }

        /*
         * الشكل الحقيقي:
         *
         * {
         *   id: 1,
         *   item_type: lifestyle,
         *   content: "...",
         *   sort_order: 0,
         *   is_ai_generated: true
         * }
         */
        if (item is Map) {
          final dynamic rawText =
              item['content'] ??
                  item['text'] ??
                  item[
                      'recommendation'] ??
                  item[
                      'description'] ??
                  item['title'];

          if (rawText != null) {
            final String text =
                rawText
                    .toString()
                    .trim();

            if (text.isNotEmpty) {
              result.add(
                text,
              );
            }
          }
        }
      }
    }

    print('');
    print('========================');
    print(
      'EXTRACTED TREATMENT ITEMS',
    );
    print(
      'COUNT: ${result.length}',
    );

    for (int i = 0;
        i < result.length;
        i++) {
      print(
        '${i + 1}: ${result[i]}',
      );
    }

    print('========================');

    return result;
  }

  Widget _planItem(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
      ),

      decoration:
          const BoxDecoration(
        border:
            Border(
          bottom:
              BorderSide(
            color:
                Color(
              0xffedf0f5,
            ),
          ),
        ),
      ),

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 48,
            height: 48,

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffe1f7f5,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                const Icon(
              Icons.check,
              color:
                  Color(
                0xff118d86,
              ),
              size: 27,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child:
                Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),

              child:
                  Text(
                text,

                style:
                    const TextStyle(
                  color:
                      Color(
                    0xff102344,
                  ),
                  fontSize:
                      16,
                  height:
                      1.45,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}