import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:immunova/const.dart';

class Add_Patient_Screen extends StatefulWidget {
  static const String routeName = '/add-patient';

  const Add_Patient_Screen({super.key});

  @override
  State<Add_Patient_Screen> createState() => _Add_Patient_ScreenState();
}

class _Add_Patient_ScreenState extends State<Add_Patient_Screen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _genders = const [
    'Male',
    'Female',
  ];

  String? _selectedGender;
  bool _isSaving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _patientIdController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();

    final DateTime now = DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
    );

    if (selectedDate == null) return;

    setState(() {
      _dateOfBirthController.text =
          '${selectedDate.month.toString().padLeft(2, '0')}/'
          '${selectedDate.day.toString().padLeft(2, '0')}/'
          '${selectedDate.year}';
    });
  }

  Future<void> _savePatient() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      print('FORM VALIDATION FAILED');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        print('ERROR: TOKEN NOT FOUND');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login token not found'),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      final dateParts = _dateOfBirthController.text.split('/');

      String dateOfBirth = _dateOfBirthController.text.trim();

      if (dateParts.length == 3) {
        final month = dateParts[0];
        final day = dateParts[1];
        final year = dateParts[2];

        dateOfBirth = '$year-$month-$day';
      }

      final Map<String, dynamic> requestBody = {
        'name': _fullNameController.text.trim(),
        'patient_code': _patientIdController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'date_of_birth': dateOfBirth,
        'gender': _selectedGender?.toLowerCase(),
        'phone': _phoneController.text.trim(),
        'medical_notes': _notesController.text.trim(),
      };

      final String url = 'http://$localhost:8000/api/v1/patients';

      print('BODY: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(
          context,
          {
            'fullName': _fullNameController.text.trim(),
            'patientId': _patientIdController.text.trim(),
            'dateOfBirth': dateOfBirth,
            'gender': _selectedGender,
            'phone': _phoneController.text.trim(),
            'notes': _notesController.text.trim(),
          },
        );
      } else {
        print('FAILED TO ADD PATIENT');
        print('STATUS CODE: ${response.statusCode}');
        print('ERROR BODY: ${response.body}');

        String errorMessage = 'Failed to add patient';

        try {
          final errorData = jsonDecode(response.body);

          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }

          if (errorData['errors'] != null) {
            print('VALIDATION ERRORS:');
            print(errorData['errors']);
          }
        } catch (e) {
          print('ERROR DECODING RESPONSE: $e');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
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

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF78849D),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 42,
        minHeight: 42,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFDCE3ED),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF2868D7),
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE34545),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE34545),
          width: 1.2,
        ),
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

  Widget _verticalSpace() {
    return const SizedBox(height: 13);
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
              onTap: () => Navigator.pop(context),
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
                    'Patients',
                    style: TextStyle(
                      color: Color(0xFF9AA6BE),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Add Patient',
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
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              14,
              15,
              14,
              14,
            ),
            children: [
              _fieldLabel('Full name'),

              TextFormField(
                controller: _fullNameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'e.g. Alex Turner',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Enter the patient's full name.";
                  }

                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Patient ID'),

              TextFormField(
                controller: _patientIdController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'e.g. PT-1078',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a patient ID.';
                  }

                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Date of birth'),

              TextFormField(
                controller: _dateOfBirthController,
                readOnly: true,
                onTap: _selectDate,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'mm/dd/yyyy',
                  suffixIcon: IconButton(
                    padding: EdgeInsets.zero,
                    splashRadius: 18,
                    onPressed: _selectDate,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      size: 17,
                      color: Color(0xFF28354D),
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Select the date of birth.';
                  }

                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Gender'),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF101A38),
                  size: 20,
                ),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'Select gender',
                ),
                items: _genders.map((gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select gender.';
                  }

                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Email'),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'patient@email.com',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter email.';
                  }
                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Password'),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: '********',
                ),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),

              _verticalSpace(),

              _fieldLabel('Phone'),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: '(555) 010-0000',
                ),
              ),

              _verticalSpace(),

              _fieldLabel('Notes'),

              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Color(0xFF101A38),
                  fontSize: 13,
                ),
                decoration: _fieldDecoration(
                  hintText: 'Intake notes, symptoms, history...',
                ).copyWith(
                  contentPadding: const EdgeInsets.fromLTRB(
                    13,
                    13,
                    13,
                    13,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF316BD8),
                        Color(0xFF14A9A3),
                      ],
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

                      // الربط مع API
                      onTap: _isSaving ? null : _savePatient,

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
                                'Save Patient',
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