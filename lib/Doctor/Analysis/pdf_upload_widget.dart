// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import 'package:immunova/const.dart';
// import 'package:immunova/services/analysis_service.dart';

// import 'prediction_result_widget.dart';

// class PdfUploadWidget extends StatefulWidget {
//   final int patientId;

//   const PdfUploadWidget({
//     super.key,
//     required this.patientId,
//   });

//   @override
//   State<PdfUploadWidget> createState() =>
//       _PdfUploadWidgetState();
// }

// class _PdfUploadWidgetState
//     extends State<PdfUploadWidget> {
//   final AnalysisService _analysisService =
//       AnalysisService();

//   PlatformFile? selectedPdf;

//   Uint8List? pdfBytes;

//   bool _isUploading = false;

//   int? _analysisId;

//   Map<String, double>? _predictionResults;

//   int? _predictionId;

//   int? _diseaseId;

//   String _patientName = 'Patient';

//   // =========================================================
//   // TOKEN
//   // =========================================================

//   Future<String> _getToken() async {
//     final prefs =
//         await SharedPreferences.getInstance();

//     final String? token =
//         prefs.getString('access_token');

//     if (token == null ||
//         token.isEmpty) {
//       throw Exception(
//         'Access token not found',
//       );
//     }

//     return token;
//   }

//   // =========================================================
//   // CHOOSE PDF
//   // =========================================================

//   Future<void> _choosePdf() async {
//     try {
//       final result =
//           await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['pdf'],
//         allowMultiple: false,
//         withData: true,
//       );

//       if (result == null) {
//         print('');
//         print('====================================');
//         print('PDF SELECTION CANCELLED');
//         print('====================================');
//         return;
//       }

//       final PlatformFile file =
//           result.files.single;

//       Uint8List? bytes =
//           file.bytes;

//       /*
//        * على بعض أجهزة Android قد لا يرجع FilePicker
//        * bytes رغم withData=true، لذلك نقرأ الملف من path
//        * كحل احتياطي بدون تغيير سلوك الواجهة.
//        */
//       if (bytes == null &&
//           file.path != null) {
//         bytes =
//             await File(
//           file.path!,
//         ).readAsBytes();
//       }

//       if (bytes == null) {
//         throw Exception(
//           'Unable to read PDF file.',
//         );
//       }

//       if (!mounted) return;

//       setState(() {
//         selectedPdf = file;
//         pdfBytes = bytes;

//         _analysisId = null;
//         _predictionResults = null;
//         _predictionId = null;
//         _diseaseId = null;
//       });

//       print('');
//       print('====================================');
//       print('PDF SELECTED');
//       print('NAME: ${file.name}');
//       print('PATH: ${file.path}');
//       print('SIZE: ${file.size}');
//       print(
//         'PATIENT ID: ${widget.patientId}',
//       );
//       print('====================================');
//     } catch (e, stackTrace) {
//       print('');
//       print('====================================');
//       print('PDF PICK ERROR');
//       print('ERROR: $e');
//       print(
//         'STACK TRACE: $stackTrace',
//       );
//       print('====================================');

//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Failed to select PDF: $e',
//           ),
//           backgroundColor:
//               Colors.red,
//         ),
//       );
//     }
//   }

//   // =========================================================
//   // REMOVE PDF
//   // =========================================================

//   void _removePdf() {
//     if (_isUploading) return;

//     setState(() {
//       selectedPdf = null;
//       pdfBytes = null;

//       _analysisId = null;
//       _predictionResults = null;
//       _predictionId = null;
//       _diseaseId = null;
//     });

//     print('');
//     print('====================================');
//     print('PDF REMOVED');
//     print('====================================');
//   }

//   // =========================================================
//   // STEP 1: CREATE ANALYSIS
//   // POST /api/v1/analyses
//   // =========================================================

//   Future<int> _createAnalysis({
//     required String token,
//   }) async {
//     final Uri url = Uri.parse(
//       'http://$localhost:8000/api/v1/analyses',
//     );

//     final Map<String, dynamic> body = {
//       'patient_id': widget.patientId,
//       'input_method': 'pdf',
//     };

//     print('');
//     print('====================================');
//     print('CREATE PDF ANALYSIS');
//     print(
//       'PATIENT ID: ${widget.patientId}',
//     );
//     print('URL: $url');
//     print('BODY: $body');
//     print('====================================');

//     final response =
//         await http.post(
//       url,
//       headers: {
//         'Accept': 'application/json',
//         'Content-Type':
//             'application/json',
//         'Authorization':
//             'Bearer $token',
//       },
//       body: jsonEncode(
//         body,
//       ),
//     );

//     print(
//       'CREATE ANALYSIS STATUS: '
//       '${response.statusCode}',
//     );

//     print(
//       'CREATE ANALYSIS RESPONSE: '
//       '${response.body}',
//     );

//     if (response.statusCode != 200 &&
//         response.statusCode != 201) {
//       throw Exception(
//         'Create analysis failed '
//         '(${response.statusCode}): '
//         '${response.body}',
//       );
//     }

//     final dynamic decoded =
//         jsonDecode(
//       response.body,
//     );

//     if (decoded is! Map) {
//       throw Exception(
//         'Invalid create analysis response.',
//       );
//     }

//     final dynamic data =
//         decoded['data'];

//     if (data is! Map) {
//       throw Exception(
//         'Analysis data was not returned.',
//       );
//     }

//     final int? analysisId =
//         int.tryParse(
//       data['id']?.toString() ?? '',
//     );

//     final dynamic patientData =
//         data['patient'];

//     if (patientData is Map &&
//         patientData['name'] != null) {
//       _patientName =
//           patientData['name'].toString();
//     }

//     if (analysisId == null) {
//       throw Exception(
//         'Analysis ID was not returned.',
//       );
//     }

//     print('');
//     print('====================================');
//     print(
//       'ANALYSIS CREATED SUCCESSFULLY',
//     );
//     print(
//       'ANALYSIS ID: $analysisId',
//     );
//     print(
//       'PATIENT ID: ${widget.patientId}',
//     );
//     print('INPUT METHOD: pdf');
//     print('====================================');

//     return analysisId;
//   }

//   // =========================================================
//   // STEP 2: UPLOAD PDF
//   // POST /api/v1/analyses/{analysisId}/files
//   // multipart/form-data
//   // key: file
//   // =========================================================

//   Future<void> _uploadPdfFile({
//     required String token,
//     required int analysisId,
//   }) async {
//     final PlatformFile? file =
//         selectedPdf;

//     if (file == null) {
//       throw Exception(
//         'No PDF selected.',
//       );
//     }

//     Uint8List? bytes =
//         pdfBytes;

//     if (bytes == null &&
//         file.path != null) {
//       bytes =
//           await File(
//         file.path!,
//       ).readAsBytes();
//     }

//     if (bytes == null) {
//       throw Exception(
//         'Unable to read PDF file.',
//       );
//     }

//     final Uri url = Uri.parse(
//       'http://$localhost:8000/api/v1/'
//       'analyses/$analysisId/files',
//     );

//     print('');
//     print('====================================');
//     print('UPLOAD PDF FILE');
//     print(
//       'PATIENT ID: ${widget.patientId}',
//     );
//     print(
//       'ANALYSIS ID: $analysisId',
//     );
//     print('URL: $url');
//     print('FILE NAME: ${file.name}');
//     print('FILE SIZE: ${file.size}');
//     print('====================================');

//     final request =
//         http.MultipartRequest(
//       'POST',
//       url,
//     );

//     request.headers.addAll({
//       'Accept': 'application/json',
//       'Authorization':
//           'Bearer $token',
//     });

//     request.files.add(
//       http.MultipartFile.fromBytes(
//         'file',
//         bytes,
//         filename: file.name,
//       ),
//     );

//     final streamedResponse =
//         await request.send();

//     final response =
//         await http.Response.fromStream(
//       streamedResponse,
//     );

//     print(
//       'UPLOAD FILE STATUS: '
//       '${response.statusCode}',
//     );

//     print(
//       'UPLOAD FILE RESPONSE: '
//       '${response.body}',
//     );

//     if (response.statusCode != 200 &&
//         response.statusCode != 201) {
//       throw Exception(
//         'Upload PDF failed '
//         '(${response.statusCode}): '
//         '${response.body}',
//       );
//     }

//     print('');
//     print('====================================');
//     print(
//       'PDF UPLOADED AND OCR COMPLETED',
//     );
//     print(
//       'PATIENT ID: ${widget.patientId}',
//     );
//     print(
//       'ANALYSIS ID: $analysisId',
//     );
//     print('FILE NAME: ${file.name}');
//     print('====================================');
//   }

//   // =========================================================
//   // STEP 3: RUN PREDICTION
//   // =========================================================

//   double _toPercentage(
//     dynamic value,
//   ) {
//     final parsed =
//         double.tryParse(
//       value.toString(),
//     );

//     if (parsed == null) {
//       return 0;
//     }

//     if (parsed >= 0 &&
//         parsed <= 1) {
//       return parsed * 100;
//     }

//     return parsed;
//   }

//   Map<String, double>
//       _parseProbabilities(
//     dynamic rawProbabilities,
//   ) {
//     final Map<String, double> result =
//         {};

//     if (rawProbabilities is Map) {
//       rawProbabilities.forEach(
//         (key, value) {
//           result[key.toString()] =
//               _toPercentage(
//             value,
//           );
//         },
//       );

//       return result;
//     }

//     if (rawProbabilities is List) {
//       for (final item
//           in rawProbabilities) {
//         if (item is! Map) {
//           continue;
//         }

//         String? diseaseName;

//         final dynamic disease =
//             item['disease'];

//         if (disease is Map) {
//           diseaseName =
//               disease['name']
//                   ?.toString();
//         }

//         diseaseName ??=
//             item['disease_name']
//                 ?.toString();

//         diseaseName ??=
//             item['name']
//                 ?.toString();

//         final dynamic probability =
//             item['probability'] ??
//             item['value'] ??
//             item['confidence'];

//         if (diseaseName == null ||
//             probability == null) {
//           continue;
//         }

//         result[diseaseName] =
//             _toPercentage(
//           probability,
//         );
//       }
//     }

//     return result;
//   }

//   Future<void> _runPrediction({
//     required int analysisId,
//   }) async {
//     print('');
//     print('====================================');
//     print('RUN PDF PREDICTION');
//     print(
//       'PATIENT ID: ${widget.patientId}',
//     );
//     print(
//       'ANALYSIS ID: $analysisId',
//     );
//     print('====================================');

//     final predictionResponse =
//         await _analysisService
//             .runPrediction(
//       analysisId: analysisId,
//     );

//     final dynamic data =
//         predictionResponse['data'];

//     if (data == null ||
//         data is! Map) {
//       throw Exception(
//         'Prediction data not found',
//       );
//     }

//     final dynamic predictionIdValue =
//         data['id'];

//     if (predictionIdValue == null) {
//       throw Exception(
//         'Prediction ID not found',
//       );
//     }

//     final dynamic predictedDisease =
//         data['predicted_disease'];

//     if (predictedDisease is! Map ||
//         predictedDisease['id'] ==
//             null) {
//       throw Exception(
//         'Predicted disease ID not found',
//       );
//     }

//     final int predictionId =
//         int.parse(
//       predictionIdValue.toString(),
//     );

//     final int diseaseId =
//         int.parse(
//       predictedDisease['id']
//           .toString(),
//     );

//     final Map<String, double>
//         probabilities =
//         _parseProbabilities(
//       data['probabilities'],
//     );

//     if (probabilities.isEmpty) {
//       throw Exception(
//         'Prediction completed but probabilities are empty',
//       );
//     }

//     print('');
//     print('====================================');
//     print(
//       'PDF PREDICTION COMPLETED',
//     );
//     print(
//       'ANALYSIS ID: $analysisId',
//     );
//     print(
//       'PREDICTION ID: $predictionId',
//     );
//     print(
//       'DISEASE ID: $diseaseId',
//     );
//     print(
//       'PROBABILITIES: $probabilities',
//     );
//     print('====================================');

//     if (!mounted) return;

//     setState(() {
//       _predictionResults =
//           probabilities;

//       _predictionId =
//           predictionId;

//       _diseaseId =
//           diseaseId;
//     });
//   }

//   // =========================================================
//   // COMPLETE FLOW
//   // CREATE ANALYSIS -> UPLOAD PDF -> OCR -> PREDICTION
//   // =========================================================

//   Future<void> _submitPdf() async {
//     if (_isUploading) {
//       return;
//     }

//     if (selectedPdf == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Please choose a PDF first.',
//           ),
//         ),
//       );

//       return;
//     }

//     setState(() {
//       _isUploading = true;
//     });

//     try {
//       final String token =
//           await _getToken();

//       // STEP 1
//       final int analysisId =
//           await _createAnalysis(
//         token: token,
//       );

//       if (!mounted) return;

//       setState(() {
//         _analysisId = analysisId;
//       });

//       // STEP 2
//       await _uploadPdfFile(
//         token: token,
//         analysisId: analysisId,
//       );

//       // STEP 3
//       await _runPrediction(
//         analysisId: analysisId,
//       );

//       print('');
//       print('====================================');
//       print(
//         'PDF ANALYSIS FLOW SUCCESS',
//       );
//       print(
//         'PATIENT ID: ${widget.patientId}',
//       );
//       print(
//         'ANALYSIS ID: $analysisId',
//       );
//       print('====================================');

//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         const SnackBar(
//           content: Text(
//             'PDF uploaded, processed and predicted successfully',
//           ),
//           backgroundColor:
//               Color(
//             0xff159fa4,
//           ),
//         ),
//       );
//     } catch (e, stackTrace) {
//       print('');
//       print('====================================');
//       print(
//         'PDF ANALYSIS FLOW FAILED',
//       );
//       print(
//         'PATIENT ID: ${widget.patientId}',
//       );
//       print(
//         'ANALYSIS ID: $_analysisId',
//       );
//       print('ERROR: $e');
//       print(
//         'STACK TRACE: $stackTrace',
//       );
//       print('====================================');

//       if (!mounted) return;

//       ScaffoldMessenger.of(context)
//           .showSnackBar(
//         SnackBar(
//           content: Text(
//             'Upload failed: $e',
//           ),
//           backgroundColor:
//               Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isUploading = false;
//         });
//       }
//     }
//   }

//   // =========================================================
//   // BUILD
//   // =========================================================

//   @override
//   Widget build(
//     BuildContext context,
//   ) {
//     return Column(
//       children: [
//         Container(
//           width: double.infinity,
//           padding:
//               const EdgeInsets.all(
//             16,
//           ),
//           decoration:
//               BoxDecoration(
//             border:
//                 Border.all(
//               color:
//                   const Color(
//                 0xffdce4f0,
//               ),
//             ),
//             borderRadius:
//                 BorderRadius.circular(
//               22,
//             ),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 width:
//                     double.infinity,
//                 padding:
//                     const EdgeInsets
//                         .symmetric(
//                   horizontal: 14,
//                   vertical: 20,
//                 ),
//                 decoration:
//                     BoxDecoration(
//                   border:
//                       Border.all(
//                     color:
//                         const Color(
//                       0xffd9e2f0,
//                     ),
//                   ),
//                   borderRadius:
//                       BorderRadius
//                           .circular(
//                     16,
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       width: 50,
//                       height: 50,
//                       decoration:
//                           BoxDecoration(
//                         color:
//                             const Color(
//                           0xffe2f8f5,
//                         ),
//                         borderRadius:
//                             BorderRadius
//                                 .circular(
//                           15,
//                         ),
//                       ),
//                       child:
//                           const Icon(
//                         Icons
//                             .file_download_outlined,
//                         color:
//                             Color(
//                           0xff06988c,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 15,
//                     ),

//                     const Text(
//                       'Upload a lab report PDF',
//                       style:
//                           TextStyle(
//                         fontWeight:
//                             FontWeight
//                                 .bold,
//                         color:
//                             Color(
//                           0xff17345f,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 6,
//                     ),

//                     const Text(
//                       "We'll scan the document and pull out\n"
//                       "patient markers automatically.",
//                       textAlign:
//                           TextAlign
//                               .center,
//                       style:
//                           TextStyle(
//                         color:
//                             Color(
//                           0xff8a9abd,
//                         ),
//                         fontSize:
//                             11,
//                       ),
//                     ),

//                     const SizedBox(
//                       height: 18,
//                     ),

//                     SizedBox(
//                       width:
//                           double.infinity,
//                       height: 48,
//                       child:
//                           OutlinedButton(
//                         onPressed:
//                             _isUploading
//                                 ? null
//                                 : _choosePdf,
//                         style:
//                             OutlinedButton
//                                 .styleFrom(
//                           side:
//                               const BorderSide(
//                             color:
//                                 Color(
//                               0xffd9e2f0,
//                             ),
//                           ),
//                           shape:
//                               RoundedRectangleBorder(
//                             borderRadius:
//                                 BorderRadius
//                                     .circular(
//                               14,
//                             ),
//                           ),
//                         ),
//                         child:
//                             const Text(
//                           'Choose PDF File',
//                           style:
//                               TextStyle(
//                             color:
//                                 Color(
//                               0xff17345f,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               if (selectedPdf != null) ...[
//                 const SizedBox(
//                   height: 14,
//                 ),

//                 Container(
//                   padding:
//                       const EdgeInsets
//                           .all(
//                     12,
//                   ),
//                   decoration:
//                       BoxDecoration(
//                     border:
//                         Border.all(
//                       color:
//                           const Color(
//                         0xffdce4f0,
//                       ),
//                     ),
//                     borderRadius:
//                         BorderRadius
//                             .circular(
//                       16,
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Container(
//                         width: 40,
//                         height: 40,
//                         decoration:
//                             BoxDecoration(
//                           color:
//                               const Color(
//                             0xffeef4ff,
//                           ),
//                           borderRadius:
//                               BorderRadius
//                                   .circular(
//                             10,
//                           ),
//                         ),
//                         child:
//                             const Icon(
//                           Icons
//                               .insert_drive_file_outlined,
//                           color:
//                               Color(
//                             0xff2868dc,
//                           ),
//                         ),
//                       ),

//                       const SizedBox(
//                         width: 10,
//                       ),

//                       Expanded(
//                         child: Text(
//                           selectedPdf!
//                               .name,
//                           overflow:
//                               TextOverflow
//                                   .ellipsis,
//                           style:
//                               const TextStyle(
//                             fontWeight:
//                                 FontWeight
//                                     .w600,
//                             color:
//                                 Color(
//                               0xff17345f,
//                             ),
//                           ),
//                         ),
//                       ),

//                       IconButton(
//                         onPressed:
//                             _isUploading
//                                 ? null
//                                 : _removePdf,
//                         icon:
//                             const Icon(
//                           Icons.close,
//                           color: Colors
//                               .redAccent,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),

//         const SizedBox(
//           height: 14,
//         ),

//         SizedBox(
//           width: double.infinity,
//           height: 52,
//           child:
//               ElevatedButton(
//             onPressed:
//                 selectedPdf == null ||
//                         _isUploading
//                     ? null
//                     : _submitPdf,
//             style:
//                 ElevatedButton
//                     .styleFrom(
//               backgroundColor:
//                   const Color(
//                 0xff159fa4,
//               ),
//               disabledBackgroundColor:
//                   const Color(
//                 0xffa8d8dc,
//               ),
//               shape:
//                   RoundedRectangleBorder(
//                 borderRadius:
//                     BorderRadius
//                         .circular(
//                   15,
//                 ),
//               ),
//             ),
//             child: _isUploading
//                 ? const Row(
//                     mainAxisAlignment:
//                         MainAxisAlignment
//                             .center,
//                     children: [
//                       SizedBox(
//                         width: 20,
//                         height: 20,
//                         child:
//                             CircularProgressIndicator(
//                           strokeWidth:
//                               2,
//                           color:
//                               Colors.white,
//                         ),
//                       ),
//                       SizedBox(
//                         width: 10,
//                       ),
//                       Text(
//                         'Uploading & processing...',
//                         style:
//                             TextStyle(
//                           color:
//                               Colors.white,
//                           fontWeight:
//                               FontWeight
//                                   .bold,
//                         ),
//                       ),
//                     ],
//                   )
//                 : const Text(
//                     'Upload PDF to continue',
//                     style:
//                         TextStyle(
//                       color:
//                           Colors.white,
//                       fontWeight:
//                           FontWeight
//                               .bold,
//                     ),
//                   ),
//           ),
//         ),

//         if (_predictionResults != null &&
//             _analysisId != null &&
//             _predictionId != null &&
//             _diseaseId != null)
//           PredictionResultWidget(
//             patientName:
//                 _patientName,
//             probabilities:
//                 _predictionResults!,
//             analysisId:
//                 _analysisId!,
//             predictionId:
//                 _predictionId!,
//             diseaseId:
//                 _diseaseId!,
//             onClose: () {
//               setState(() {
//                 _predictionResults =
//                     null;

//                 _predictionId =
//                     null;

//                 _diseaseId =
//                     null;
//               });
//             },
//           ),
//       ],
//     );
//   }
// }
