
import 'package:flutter/material.dart';
import 'package:immunova/Doctor/Home_page.dart';
import 'package:immunova/Patient/Patient_Home.dart';
import 'package:immunova/sign_in/sign_in_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.getString('token') != null;

  runApp(MyApp(startRoute: hasToken ? '/login' : '/login'));
}

class MyApp extends StatelessWidget {
  final String startRoute;
  const MyApp({super.key, required this.startRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: startRoute,
      routes: {
        '/login': (context) => Sign_In_Screen(),
        // UsersScreen.screenRoot:(context) => UsersScreen(),
        'home': (context) => Home_Page_Screen(),
        'patient_home': (context) => PatientHomeScreen(),
      },
    );
  }
}
