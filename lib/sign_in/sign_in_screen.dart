// ignore_for_file: unused_import

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:immunova/Patient/Patient_Home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immunova/Doctor/Home_page.dart';
import 'package:immunova/const.dart';

class Sign_In_Screen extends StatefulWidget {
  static const String routeName = '/login';

  const Sign_In_Screen({super.key});

  @override
  State<Sign_In_Screen> createState() => _Sign_In_ScreenState();
}

class _Sign_In_ScreenState extends State<Sign_In_Screen> {
  final _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  bool _isLoading = false;

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

Future<void> _login() async {
  final formState = _formKey.currentState;

  if (formState == null) {
    print('ERROR: FORM STATE IS NULL');
    return;
  }

  if (!formState.validate()) {
    print('ERROR: FORM VALIDATION FAILED');
    return;
  }

  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  print('EMAIL: $email');
  print('PASSWORD LENGTH: ${password.length}');

  setState(() {
    _isLoading = true;
  });

  try {
    final String url =
        'http://$localhost:8000/api/v1/login';

    final response = await http.post(
      Uri.parse(url),
      headers: <String, String>{
        'Content-Type':
            'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(
        <String, String>{
          'email': email,
          'password': password,
        },
      ),
    );

    print('STATUS CODE: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      // READ TOKEN
      final String token =
          data['data']['token'].toString();

      // READ USER
      final Map<String, dynamic> user =
          Map<String, dynamic>.from(
        data['data']['user'],
      );

      final int userId = user['id'];

      final String role =
          user['role']?.toString() ?? '';

      final String userName =
          user['name']?.toString() ?? 'User';

      final String userEmail =
          user['email']?.toString() ?? email;

      final String userPhone =
          user['phone']?.toString() ?? '';

      // PRINT DATA FROM API
      print('TOKEN FROM API: $token');
      print('USER ID FROM API: $userId');
      print('USER NAME FROM API: $userName');
      print('USER EMAIL FROM API: $userEmail');
      print('USER PHONE FROM API: $userPhone');
      print('ROLE FROM API: $role');

      // SHARED PREFERENCES

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      // TOKEN
      final bool tokenSaved =
          await prefs.setString(
        'access_token',
        token,
      );

      // USER ID
      final bool userIdSaved =
          await prefs.setInt(
        'user_id',
        userId,
      );

      // ROLE
      final bool roleSaved =
          await prefs.setString(
        'role',
        role,
      );

      // =========================================
      // SAVE USER NAME
      // =========================================
      final bool nameSaved =
          await prefs.setString(
        'name',
        userName,
      );

      // EMAIL
      final bool emailSaved =
          await prefs.setString(
        'email',
        userEmail,
      );

      // PHONE
      final bool phoneSaved =
          await prefs.setString(
        'user_phone',
        userPhone,
      );

      print('TOKEN SAVE RESULT: $tokenSaved');
      print('USER ID SAVE RESULT: $userIdSaved');
      print('ROLE SAVE RESULT: $roleSaved');
      print('USER NAME SAVE RESULT: $nameSaved');
      print('USER EMAIL SAVE RESULT: $emailSaved');
      print('USER PHONE SAVE RESULT: $phoneSaved');


      // READ AGAIN AFTER SAVING
      final String? savedToken =
          prefs.getString('access_token');

      final int? savedUserId =
          prefs.getInt('user_id');

      final String? savedRole =
          prefs.getString('role');

      final String? savedUserName =
          prefs.getString('name');

      final String? savedUserEmail =
          prefs.getString('email');

      final String? savedUserPhone =
          prefs.getString('phone');

      print('SAVED TOKEN: $savedToken');
      print('SAVED USER ID: $savedUserId');
      print('SAVED ROLE: $savedRole');
      print('SAVED USER NAME: $savedUserName');
      print('SAVED USER EMAIL: $savedUserEmail');
      print('SAVED USER PHONE: $savedUserPhone');


      // CHECK TOKEN
      if (savedToken == null ||
          savedToken.isEmpty) {
        print('ERROR: TOKEN WAS NOT SAVED');

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Token could not be saved',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      print('TOKEN SAVED SUCCESSFULLY');
      print('USER NAME SAVED SUCCESSFULLY');

      if (!mounted) return;

      // NAVIGATION BY ROLE
      if (role == 'doctor') {
        print('NAVIGATING TO DOCTOR HOME');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                Home_Page_Screen(),
          ),
        );
      } else if (role == 'patient') {
        print('NAVIGATING TO PATIENT HOME');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PatientHomeScreen(),
          ),
        );
      } else {
        print('ERROR: UNKNOWN ROLE: $role');

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unknown user role: $role',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {

      // LOGIN FAILED
      print(
        'STATUS CODE: ${response.statusCode}',
      );
      print(
        'RESPONSE BODY: ${response.body}',
      );

      String errorMessage = 'Login failed';

      try {
        final Map<String, dynamic> errorData =
            jsonDecode(response.body);

        if (errorData['message'] != null) {
          errorMessage =
              errorData['message'].toString();
        }

        if (errorData['errors'] != null) {
          print(
            'VALIDATION ERRORS: ${errorData['errors']}',
          );
        }
      } catch (e) {
        print(
          'ERROR DECODING ERROR RESPONSE: $e',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Error: $e',
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,

            child: Column(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(200),

                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 100,
                    ),

                    child: const Image(
                      image: AssetImage(
                        'images/photo_2026-06-15_16-19-34.jpg',
                      ),
                      width: 400,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'sign in to review patient risk profiles and prediction',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 70),

                const Padding(
                  padding:
                      EdgeInsets.only(right: 320),
                  child: Text('Email'),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),

                  child: TextFormField(
                    controller: _emailController,

                    keyboardType:
                        TextInputType.emailAddress,

                    textInputAction:
                        TextInputAction.next,

                    decoration: InputDecoration(
                      hintText:
                          'Enter your Email',

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Please enter your email';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 30),

                const Padding(
                  padding:
                      EdgeInsets.only(right: 300),
                  child: Text('Password'),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),

                  child: TextFormField(
                    controller:
                        _passwordController,

                    obscureText: _obscureText,

                    textInputAction:
                        TextInputAction.done,

                    onFieldSubmitted: (_) {
                      if (!_isLoading) {
                        _login();
                      }
                    },

                    decoration: InputDecoration(
                      hintText:
                          'Enter your password',

                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            _obscureText =
                                !_obscureText;
                          });
                        },
                      ),

                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    validator: (value) {
                      if (value == null ||
                          value.isEmpty) {
                        return 'Please enter your password';
                      }

                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    right: 16,
                  ),

                  child: Align(
                    alignment:
                        Alignment.centerRight,

                    child: TextButton(
                      onPressed: () {
                        // Forgot Password لاحقاً
                      },

                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Color.fromARGB(
                            255,
                            5,
                            107,
                            73,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),

                  child: SizedBox(
                    width: double.infinity,
                    height: 50,

                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(
                          255,
                          5,
                          107,
                          73,
                        ),

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                            30,
                          ),
                        ),
                      ),

                      onPressed:
                            // Navigator.pushReplacement(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (context) =>
                            //           PatientHomeScreen(),
                            //     ),
                            //   );
                          _isLoading
                              ? null
                              : () {
                                  print(
                                    'SIGN IN BUTTON PRESSED',
                                  );

                                  _login();
                                },

                      child: _isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,

                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}