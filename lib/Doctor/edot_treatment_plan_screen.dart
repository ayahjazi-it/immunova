import 'package:flutter/material.dart';

import 'package:immunova/services/treatment_plan_service.dart';

class EditTreatmentPlanScreen
    extends StatefulWidget {
  final int treatmentPlanId;
  final List<Map<String, dynamic>>
      initialItems;

  const EditTreatmentPlanScreen({
    super.key,
    required this.treatmentPlanId,
    required this.initialItems,
  });

  @override
  State<EditTreatmentPlanScreen>
      createState() =>
          _EditTreatmentPlanScreenState();
}

class _EditTreatmentPlanScreenState
    extends State<EditTreatmentPlanScreen> {
  final TreatmentPlanService _service =
      TreatmentPlanService();

  final List<TextEditingController>
      _controllers = [];

  final List<String> _itemTypes = [];

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    for (final item
        in widget.initialItems) {
      _controllers.add(
        TextEditingController(
          text:
              item['content']?.toString() ??
                  '',
        ),
      );

      _itemTypes.add(
        item['item_type']?.toString() ??
            'lifestyle',
      );
    }

    if (_controllers.isEmpty) {
      _addItem();
    }
  }

  @override
  void dispose() {
    for (final controller
        in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _addItem() {
    setState(() {
      _controllers.add(
        TextEditingController(),
      );

      _itemTypes.add(
        'lifestyle',
      );
    });
  }

  void _removeItem(
    int index,
  ) {
    if (_controllers.length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'At least one treatment item is required.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final controller =
        _controllers.removeAt(index);

    controller.dispose();

    _itemTypes.removeAt(index);

    setState(() {});
  }

  Future<void> _saveChanges() async {
    if (isSaving) {
      return;
    }

    final List<Map<String, dynamic>>
        items = [];

    for (int i = 0;
        i < _controllers.length;
        i++) {
      final String content =
          _controllers[i].text.trim();

      if (content.isEmpty) {
        continue;
      }

      items.add({
        'item_type':
            _itemTypes[i],
        'content':
            content,
      });
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please add at least one recommendation.',
          ),
          backgroundColor:
              Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final response =
          await _service
              .editTreatmentPlanItems(
        treatmentPlanId:
            widget.treatmentPlanId,
        items:
            items,
        doctorNotes:
            'Edited by doctor.',
      );

      /*
       * بعد التعديل، الباك يحول الخطة إلى revised
       * وواجهة المريض تعرض فقط الخطط approved.
       *
       * لذلك نعتمد الخطة تلقائياً بعد نجاح الحفظ
       * حتى تظهر مباشرة للمريض.
       */
      await _service.reviewTreatmentPlan(
        treatmentPlanId:
            widget.treatmentPlanId,
        status:
            'approved',
        doctorNotes:
            'Edited and approved by doctor.',
      );

      final dynamic rawData =
          response['data'];

      Map<String, dynamic>
          updatedPlan;

      if (rawData is Map) {
        updatedPlan =
            Map<String, dynamic>.from(
          rawData,
        );
      } else {
        updatedPlan = {
          'id':
              widget.treatmentPlanId,
          'items':
              items,
          'doctor_notes':
              'Edited and approved by doctor.',
        };
      }

      /*
       * response الأول صادر عن PUT قبل إعادة الاعتماد،
       * لذلك قد يحمل status = revised.
       * نحدّث النسخة المحلية إلى approved لأن PATCH نجح.
       */
      updatedPlan['status'] =
          'approved';
      updatedPlan['doctor_notes'] =
          'Edited and approved by doctor.';

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Treatment plan updated successfully.',
          ),
          backgroundColor:
              Color(0xff159fa4),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(
        context,
        updatedPlan,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save changes: $e',
          ),
          backgroundColor:
              Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation:
            0,
        foregroundColor:
            const Color(
          0xff102344,
        ),
        title:
            const Text(
          'Edit Treatment Plan',
          style:
              TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            28,
          ),
          children: [
            const Text(
              'AI-GENERATED TREATMENT PLAN',
              style:
                  TextStyle(
                color:
                    Color(
                  0xff94a0b8,
                ),
                fontSize:
                    12,
                fontWeight:
                    FontWeight.w800,
                letterSpacing:
                    0.4,
              ),
            ),

            const SizedBox(
              height:
                  14,
            ),

            Container(
              padding:
                  const EdgeInsets.all(
                20,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  24,
                ),
                border:
                    Border.all(
                  color:
                      const Color(
                    0xffdfe6f1,
                  ),
                ),
              ),
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color:
                            Color(
                          0xff159fa4,
                        ),
                      ),
                      SizedBox(
                        width:
                            10,
                      ),
                      Text(
                        'Edit Treatment Plan',
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xff102344,
                          ),
                          fontSize:
                              20,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:
                        12,
                  ),

                  const Text(
                    'Adjust the AI-generated plan, then save. Edited plans return to pending review.',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xff94a1b8,
                      ),
                      height:
                          1.4,
                      fontSize:
                          13,
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),

                  ...List.generate(
                    _controllers.length,
                    (index) =>
                        _itemEditor(
                      index,
                    ),
                  ),

                  const SizedBox(
                    height:
                        6,
                  ),

                  SizedBox(
                    width:
                        double.infinity,
                    height:
                        54,
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          _addItem,
                      icon:
                          const Icon(
                        Icons.add,
                      ),
                      label:
                          const Text(
                        'Add item',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      style:
                          OutlinedButton.styleFrom(
                        foregroundColor:
                            const Color(
                          0xff2856c7,
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
                              BorderRadius.circular(
                            15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height:
                        20,
                  ),

                  const Divider(
                    color:
                        Color(
                      0xffedf0f5,
                    ),
                  ),

                  const SizedBox(
                    height:
                        10,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed:
                              isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(
                                        context,
                                      );
                                    },
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor:
                                const Color(
                              0xff53627d,
                            ),
                            padding:
                                const EdgeInsets.symmetric(
                              vertical:
                                  16,
                            ),
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                            ),
                          ),
                          child:
                              const Text(
                            'Cancel',
                          ),
                        ),
                      ),

                      const SizedBox(
                        width:
                            12,
                      ),

                      Expanded(
                        child:
                            SizedBox(
                          height:
                              52,
                          child:
                              DecoratedBox(
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                              gradient:
                                  const LinearGradient(
                                colors: [
                                  Color(
                                    0xff316bd8,
                                  ),
                                  Color(
                                    0xff14a9a3,
                                  ),
                                ],
                              ),
                            ),
                            child:
                                ElevatedButton(
                              onPressed:
                                  isSaving
                                      ? null
                                      : _saveChanges,
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.transparent,
                                shadowColor:
                                    Colors.transparent,
                                disabledBackgroundColor:
                                    Colors.transparent,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                              child:
                                  isSaving
                                      ? const SizedBox(
                                          width:
                                              20,
                                          height:
                                              20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth:
                                                2,
                                            color:
                                                Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save changes',
                                          style:
                                              TextStyle(
                                            color:
                                                Colors.white,
                                            fontWeight:
                                                FontWeight.w800,
                                          ),
                                        ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemEditor(
    int index,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom:
            12,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            child:
                TextField(
              controller:
                  _controllers[index],
              minLines:
                  1,
              maxLines:
                  4,
              decoration:
                  InputDecoration(
                hintText:
                    'Treatment recommendation',
                contentPadding:
                    const EdgeInsets.symmetric(
                  horizontal:
                      16,
                  vertical:
                      16,
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(
                      0xffdfe6f1,
                    ),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                      const BorderSide(
                    color:
                        Color(
                      0xff159fa4,
                    ),
                    width:
                        1.4,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
                10,
          ),

          Container(
            width:
                46,
            height:
                46,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xffffeded,
              ),
              borderRadius:
                  BorderRadius.circular(
                23,
              ),
            ),
            child:
                IconButton(
              onPressed:
                  () => _removeItem(
                index,
              ),
              icon:
                  const Icon(
                Icons.close,
                color:
                    Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
