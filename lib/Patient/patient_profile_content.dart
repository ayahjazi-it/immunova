import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:immunova/const.dart';

class PatientProfileContent extends StatefulWidget {
  const PatientProfileContent({super.key});

  @override
  State<PatientProfileContent> createState() =>
      _PatientProfileContentState();
}

class _PatientProfileContentState
    extends State<PatientProfileContent> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final String? token =
          prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('auth_token');

      if (token == null || token.trim().isEmpty) {
        await prefs.clear();

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );

        return;
      }

      final Uri url = Uri.parse(
        'http://$localhost:8000/api/v1/logout',
      );

      print('');
      print('====================================');
      print('PATIENT LOGOUT');
      print('URL: $url');
      print('====================================');

      final http.Response response =
          await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('LOGOUT STATUS: ${response.statusCode}');
      print('LOGOUT RESPONSE: ${response.body}');

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        throw Exception(
          'Logout failed (${response.statusCode})',
        );
      }

      await prefs.clear();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      print('LOGOUT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to log out: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================
            // PATIENT INFO
            // =========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDE4EF),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2B82D5),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maya Reyes',
                          style: TextStyle(
                            color: Color(0xFF101A38),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Patient',
                            style: TextStyle(
                              color: Color(0xFF2868D7),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =========================================
            // SETTINGS
            // =========================================
            const Text(
              'SETTINGS',
              style: TextStyle(
                color: Color(0xFF97A3BC),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDE4EF),
                ),
              ),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF3976EB),
                    iconBackground: const Color(0xFFEAF2FF),
                    title: 'Account details',
                    subtitle: 'Name, email, credentials',
                    showArrow: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account details clicked'),
                        ),
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    color: Color(0xFFE4E9F2),
                  ),

                  _ProfileItem(
                    icon: Icons.sync_alt_rounded,
                    iconColor: const Color(0xFF3976EB),
                    iconBackground: const Color(0xFFEAF2FF),
                    title: 'Switch role',
                    subtitle: 'Return to sign in',
                    showArrow: true,
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =========================================
            // LOG OUT
            // =========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDE4EF),
                ),
              ),
              child: _ProfileItem(
                icon: Icons.logout_rounded,
                iconColor: const Color(0xFFE75B59),
                iconBackground: const Color(0xFFFFECEB),
                title: _isLoggingOut
                    ? 'Logging out...'
                    : 'Log out',
                subtitle: null,
                showArrow: false,
                titleColor: const Color(0xFFE75B59),
                onTap: _isLoggingOut
                    ? () {}
                    : _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PROFILE ITEM
// =====================================================

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? subtitle;
  final bool showArrow;
  final VoidCallback onTap;
  final Color? titleColor;

  const _ProfileItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.showArrow,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? const Color(0xFF101A38),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: Color(0xFF8996AF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (showArrow)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF93A0B9),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}