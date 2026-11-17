import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:immunova/const.dart';
import 'package:immunova/services/analysis_service.dart';
import 'prediction_result_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ImageUploadWidget extends StatefulWidget {
  final int patientId;

  /*
   * اختياري:
   * إذا حابب الأب يعرف إن رفع الصورة خلص بنجاح
   * ويرجعله analysisId الناتج.
   */
  final void Function(int analysisId)? onUploadCompleted;

  const ImageUploadWidget({
    super.key,
    required this.patientId,
    this.onUploadCompleted,
  });

  @override
  State<ImageUploadWidget> createState() =>
      _ImageUploadWidgetState();
}

class _ImageUploadWidgetState
    extends State<ImageUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  final AnalysisService _analysisService = AnalysisService();

  XFile? selectedImage;
  Uint8List? imageBytes;

  bool _isUploading = false;

  int? _analysisId;

  Map<String, double>? _predictionResults;
  int? _predictionId;
  int? _diseaseId;
  String _patientName = 'Patient';

  // =========================================================
  // TOKEN
  // =========================================================

  Future<String> _getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    final String? token =
        prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'Access token not found',
      );
    }

    return token;
  }

  // =========================================================
  // CHOOSE IMAGE
  // =========================================================

  Future<void> _chooseImage() async {
    try {
      final XFile? image =
          await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) {
        print('');
        print('====================================');
        print('IMAGE SELECTION CANCELLED');
        print('====================================');
        return;
      }

      final bytes =
          await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        selectedImage = image;
        imageBytes = bytes;
        _analysisId = null;
      });

      print('');
      print('====================================');
      print('IMAGE SELECTED');
      print('NAME: ${image.name}');
      print('PATH: ${image.path}');
      print('SIZE: ${bytes.length}');
      print('PATIENT ID: ${widget.patientId}');
      print('====================================');
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('IMAGE SELECTION ERROR');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select image: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // REMOVE IMAGE
  // =========================================================

  void _removeImage() {
    if (_isUploading) return;

    setState(() {
      selectedImage = null;
      imageBytes = null;
      _analysisId = null;
    });
  }

  // =========================================================
  // STEP 1: CREATE ANALYSIS
  // POST /api/v1/analyses
  // =========================================================

  Future<int> _createAnalysis({
    required String token,
  }) async {
    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/analyses',
    );

    final Map<String, dynamic> body = {
      'patient_id': widget.patientId,
      'input_method': 'image',
    };

    print('');
    print('====================================');
    print('CREATE IMAGE ANALYSIS');
    print('PATIENT ID: ${widget.patientId}');
    print('URL: $url');
    print('BODY: $body');
    print('====================================');

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
      body: jsonEncode(body),
    );

    print(
      'CREATE ANALYSIS STATUS: '
      '${response.statusCode}',
    );

    print(
      'CREATE ANALYSIS RESPONSE: '
      '${response.body}',
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Create analysis failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    final dynamic decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception(
        'Invalid create analysis response.',
      );
    }

    final dynamic data =
        decoded['data'];

    if (data is! Map) {
      throw Exception(
        'Analysis data was not returned.',
      );
    }

    final int? analysisId =
        int.tryParse(
      data['id']?.toString() ?? '',
    );

    final dynamic patientData = data['patient'];

    if (patientData is Map &&
        patientData['name'] != null) {
      _patientName =
          patientData['name'].toString();
    }

    if (analysisId == null) {
      throw Exception(
        'Analysis ID was not returned.',
      );
    }

    print('');
    print('====================================');
    print('ANALYSIS CREATED SUCCESSFULLY');
    print('ANALYSIS ID: $analysisId');
    print('PATIENT ID: ${widget.patientId}');
    print('INPUT METHOD: image');
    print('====================================');

    return analysisId;
  }

  // =========================================================
  // STEP 2: UPLOAD IMAGE
  // POST /api/v1/analyses/{analysisId}/files
  // multipart/form-data
  // key: file
  // =========================================================

  Future<void> _uploadImageFile({
    required String token,
    required int analysisId,
  }) async {
    final XFile? image =
        selectedImage;

    if (image == null) {
      throw Exception(
        'No image selected.',
      );
    }

    final Uri url = Uri.parse(
      'http://$localhost:8000/api/v1/'
      'analyses/$analysisId/files',
    );

    print('');
    print('====================================');
    print('UPLOAD IMAGE FILE');
    print('PATIENT ID: ${widget.patientId}');
    print('ANALYSIS ID: $analysisId');
    print('URL: $url');
    print('FILE NAME: ${image.name}');
    print(
      'FILE SIZE: ${imageBytes?.length}',
    );
    print('====================================');

    final request =
        http.MultipartRequest(
      'POST',
      url,
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization':
          'Bearer $token',
    });

    /*
     * نستخدم bytes حتى يشتغل بشكل صحيح على Android
     * وحتى ما نعتمد على path فقط.
     */
    final Uint8List bytes =
        imageBytes ??
            await image.readAsBytes();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ),
    );

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    print(
      'UPLOAD FILE STATUS: '
      '${response.statusCode}',
    );

    print(
      'UPLOAD FILE RESPONSE: '
      '${response.body}',
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Upload image failed '
        '(${response.statusCode}): '
        '${response.body}',
      );
    }

    print('');
    print('====================================');
    print('IMAGE UPLOADED AND OCR COMPLETED');
    print('PATIENT ID: ${widget.patientId}');
    print('ANALYSIS ID: $analysisId');
    print('FILE NAME: ${image.name}');
    print('====================================');
  }

  // =========================================================
  // STEP 3: RUN PREDICTION
  // =========================================================

  double _toPercentage(dynamic value) {
    final parsed =
        double.tryParse(value.toString());

    if (parsed == null) {
      return 0;
    }

    if (parsed >= 0 && parsed <= 1) {
      return parsed * 100;
    }

    return parsed;
  }

  Map<String, double> _parseProbabilities(
    dynamic rawProbabilities,
  ) {
    final Map<String, double> result = {};

    if (rawProbabilities is Map) {
      rawProbabilities.forEach((key, value) {
        result[key.toString()] =
            _toPercentage(value);
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
          diseaseName =
              disease['name']?.toString();
        }

        diseaseName ??=
            item['disease_name']?.toString();

        diseaseName ??=
            item['name']?.toString();

        final dynamic probability =
            item['probability'] ??
            item['value'] ??
            item['confidence'];

        if (diseaseName == null ||
            probability == null) {
          continue;
        }

        result[diseaseName] =
            _toPercentage(probability);
      }
    }

    return result;
  }

  Future<void> _runPrediction({
    required int analysisId,
  }) async {
    final predictionResponse =
        await _analysisService.runPrediction(
      analysisId: analysisId,
    );

    final dynamic data =
        predictionResponse['data'];

    if (data == null || data is! Map) {
      throw Exception(
        'Prediction data not found',
      );
    }

    final dynamic predictionIdValue =
        data['id'];

    if (predictionIdValue == null) {
      throw Exception(
        'Prediction ID not found',
      );
    }

    final dynamic predictedDisease =
        data['predicted_disease'];

    if (predictedDisease is! Map ||
        predictedDisease['id'] == null) {
      throw Exception(
        'Predicted disease ID not found',
      );
    }

    final int predictionId =
        int.parse(
      predictionIdValue.toString(),
    );

    final int diseaseId =
        int.parse(
      predictedDisease['id'].toString(),
    );

    final Map<String, double> probabilities =
        _parseProbabilities(
      data['probabilities'],
    );

    if (probabilities.isEmpty) {
      throw Exception(
        'Prediction completed but probabilities are empty',
      );
    }

    print('');
    print('====================================');
    print('IMAGE PREDICTION COMPLETED');
    print('ANALYSIS ID: $analysisId');
    print('PREDICTION ID: $predictionId');
    print('DISEASE ID: $diseaseId');
    print('PROBABILITIES: $probabilities');
    print('====================================');

    if (!mounted) return;

    setState(() {
      _predictionResults = probabilities;
      _predictionId = predictionId;
      _diseaseId = diseaseId;
    });
  }

  // =========================================================
  // COMPLETE FLOW
  // CREATE ANALYSIS -> UPLOAD IMAGE
  // =========================================================

  Future<void> _submitImage() async {
    if (_isUploading) return;

    if (selectedImage == null ||
        imageBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please choose an image first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String token =
          await _getToken();

      // STEP 1
      final int analysisId =
          await _createAnalysis(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _analysisId = analysisId;
      });

      // STEP 2
      await _uploadImageFile(
        token: token,
        analysisId: analysisId,
      );

      await _runPrediction(
        analysisId: analysisId,
      );

      print('');
      print('====================================');
      print('IMAGE ANALYSIS FLOW SUCCESS');
      print('PATIENT ID: ${widget.patientId}');
      print('ANALYSIS ID: $analysisId');
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Image uploaded and processed successfully',
          ),
          backgroundColor:
              Color(0xff159fa4),
        ),
      );

      widget.onUploadCompleted?.call(
        analysisId,
      );
    } catch (e, stackTrace) {
      print('');
      print('====================================');
      print('IMAGE ANALYSIS FLOW FAILED');
      print('PATIENT ID: ${widget.patientId}');
      print('ANALYSIS ID: $_analysisId');
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');
      print('====================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
          ),
          backgroundColor:
              Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  const Color(
                0xffdce4f0,
              ),
            ),
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(
                  20,
                ),
                decoration:
                    BoxDecoration(
                  border: Border.all(
                    color:
                        const Color(
                      0xffd9e2f0,
                    ),
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xffe2f8f5,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          15,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .image_outlined,
                        color:
                            Color(
                          0xff06988c,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    const Text(
                      'Upload a lab report image',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Color(
                          0xff17345f,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      "Choose a lab report image and we'll\nextract the patient markers automatically.",
                      textAlign:
                          TextAlign
                              .center,
                      style:
                          TextStyle(
                        color:
                            Color(
                          0xff8a9abd,
                        ),
                        fontSize:
                            11,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      height:
                          48,
                      child:
                          OutlinedButton(
                        onPressed:
                            _isUploading
                                ? null
                                : _chooseImage,
                        style:
                            OutlinedButton
                                .styleFrom(
                          side:
                              const BorderSide(
                            color:
                                Color(
                              0xffd9e2f0,
                            ),
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
                        child:
                            const Text(
                          'Choose Image',
                          style:
                              TextStyle(
                            color:
                                Color(
                              0xff17345f,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (selectedImage != null &&
                  imageBytes !=
                      null) ...[
                const SizedBox(
                  height: 14,
                ),

                Container(
                  padding:
                      const EdgeInsets.all(
                    10,
                  ),
                  decoration:
                      BoxDecoration(
                    border:
                        Border.all(
                      color:
                          const Color(
                        0xffdce4f0,
                      ),
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                        child:
                            Image.memory(
                          imageBytes!,
                          width: 55,
                          height: 55,
                          fit:
                              BoxFit.cover,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              selectedImage!
                                  .name,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color:
                                    Color(
                                  0xff17345f,
                                ),
                              ),
                            ),

                            if (_analysisId !=
                                null) ...[
                              const SizedBox(
                                height: 4,
                              ),
                              Text(
                                'Analysis #$_analysisId',
                                style:
                                    const TextStyle(
                                  fontSize:
                                      10,
                                  color:
                                      Color(
                                    0xff8a9abd,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      IconButton(
                        onPressed:
                            _isUploading
                                ? null
                                : _removeImage,
                        icon:
                            const Icon(
                          Icons.close,
                          color: Colors
                              .redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        SizedBox(
          width: double.infinity,
          height: 52,
          child:
              ElevatedButton(
            onPressed:
                selectedImage == null ||
                        _isUploading
                    ? null
                    : _submitImage,
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  const Color(
                0xff159fa4,
              ),
              disabledBackgroundColor:
                  const Color(
                0xffa8d8dc,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),
            ),
            child: _isUploading
                ? const Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                          color:
                              Colors.white,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Uploading & processing...',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Upload Image to continue',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
          ),
        ),

        if (_predictionResults != null &&
            _analysisId != null &&
            _predictionId != null &&
            _diseaseId != null)
          PredictionResultWidget(
            patientName: _patientName,
            probabilities:
                _predictionResults!,
            analysisId: _analysisId!,
            predictionId: _predictionId!,
            diseaseId: _diseaseId!,
            onClose: () {
              setState(() {
                _predictionResults = null;
                _predictionId = null;
                _diseaseId = null;
              });
            },
          ),
      ],
    );
  }
}
