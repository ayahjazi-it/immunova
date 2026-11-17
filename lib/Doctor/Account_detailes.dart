import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:immunova/const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account_detailes extends StatefulWidget {
  static const String routeName = '/account-details';

  const Account_detailes({super.key});

  @override
  State<Account_detailes> createState() => _Account_detailesState();
}

class _Account_detailesState extends State<Account_detailes> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static const String _profileUrl = 'http://$localhost:8000/api/v1/me/profile';

  final TextEditingController _fullNameController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _phoneController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  // GET TOKEN
  Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      debugPrint('TOKEN NOT FOUND');
    } else {
      debugPrint('TOKEN FOUND SUCCESSFULLY');
      debugPrint('TOKEN LENGTH: ${token.length}');
    }

    return token;
  }

  // SAVE PROFILE WITH PATCH
  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

    final FormState? form = _formKey.currentState;

    if (form == null) {
      debugPrint('ERROR: FORM STATE IS NULL');
      return;
    }

    if (!form.validate()) {
      debugPrint('ERROR: FORM VALIDATION FAILED');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final String? token = await _getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        _showMessage(
          'Login token was not found. Please login again.',
          isError: true,
        );

        return;
      }
      final Map<String, dynamic> requestData = <String, dynamic>{
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      debugPrint('URL: $_profileUrl');
      debugPrint('BODY: ${jsonEncode(requestData)}');

      final http.Response response = await http.patch(
        Uri.parse(_profileUrl),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestData),
      );

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        String message = 'Account details updated successfully';

        try {
          final dynamic decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            message = decoded['message'].toString();
          }
        } catch (e) {
          debugPrint('SUCCESS RESPONSE JSON PARSE ERROR: $e');
        }

        debugPrint('PROFILE UPDATE SUCCESS');
        debugPrint('MESSAGE: $message');

        _showMessage(message, isError: false);

        await Future<void>.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pop(context, <String, String>{
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
      } else {
        final String message = _extractErrorMessage(response.body);

        debugPrint('UPDATE PROFILE ERROR');
        debugPrint('STATUS: ${response.statusCode}');
        debugPrint('MESSAGE: $message');

        _showMessage(message, isError: true);
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      _showMessage('Unable to connect to the server.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is Map<String, dynamic>) {
        final dynamic errors = decoded['errors'];

        if (errors is Map<String, dynamic>) {
          for (final dynamic value in errors.values) {
            if (value is List && value.isNotEmpty) {
              return value.first.toString();
            }

            if (value != null) {
              return value.toString();
            }
          }
        }

        if (decoded['message'] != null) {
          return decoded['message'].toString();
        }
      }
    } catch (e) {
      debugPrint('ERROR DECODING RESPONSE: $e');
    }

    return 'Something went wrong. Please try again.';
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFFE34545)
            : const Color(0xFF12A6A0),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF7E8AA4), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFDCE3ED), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFF2868D7), width: 1.3),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE34545), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE34545), width: 1.2),
      ),
      errorStyle: const TextStyle(
        color: Color(0xFFE34545),
        fontSize: 10,
        height: 1.15,
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF354465),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 12,

        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Color(0xFF2868D7),
                ),
              ),
            ),

            const SizedBox(width: 9),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Color(0xFF9AA6BE),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Account details',
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
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE4E9F2)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 24),
            children: [
              _fieldLabel('Full name'),

              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Color(0xFF101A38), fontSize: 13),
                decoration: _fieldDecoration(hintText: 'Enter full name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your full name.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),
              _fieldLabel('Email address'),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Color(0xFF101A38), fontSize: 13),
                decoration: _fieldDecoration(hintText: 'Enter email address'),
                validator: (value) {
                  final String email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return 'Enter your email address.';
                  }

                  final RegExp emailPattern = RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  );

                  if (!emailPattern.hasMatch(email)) {
                    return 'Enter a valid email address.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _fieldLabel('Phone number'),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) {
                  _saveChanges();
                },
                style: const TextStyle(color: Color(0xFF101A38), fontSize: 13),
                decoration: _fieldDecoration(hintText: 'Enter phone number'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your phone number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF316BD8), Color(0xFF14A9A3)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26316BD8),
                        blurRadius: 11,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(13),
                      onTap: _isSaving ? null : _saveChanges,
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.3,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
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
