import 'package:flutter/material.dart';
import 'package:immunova/Doctor/Account_detailes.dart';

class Profile_Screen extends StatelessWidget {
  const Profile_Screen({
    super.key,
    this.onAccountDetailsTap,
    this.onNotificationsTap,
    this.onSwitchRoleTap,
    this.onLogoutTap,
  });

  final VoidCallback? onAccountDetailsTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSwitchRoleTap;
  final VoidCallback? onLogoutTap;

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Log out',
            style: TextStyle(
              color: Color(0xFF101A38),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Color(0xFF6F7C96)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE85050),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);

                if (onLogoutTap != null) {
                  onLogoutTap!();
                } else {
                  _showMessage(context, 'Logged out');
                }
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF316BD8), Color(0xFF14A9A3)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. Elena Cho',
                      style: TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          child: Text(
                            'Doctor',
                            style: TextStyle(
                              color: Color(0xFF2868D7),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'SETTINGS',
          style: TextStyle(
            color: Color(0xFF94A0B8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
          ),
        ),

        const SizedBox(height: 9),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E7F0)),
          ),
          child: Column(
            children: [
              ProfileOptionTile(
                icon: Icons.person_outline_rounded,
                iconColor: const Color(0xFF2868D7),
                iconBackground: const Color(0xFFEAF1FF),
                title: 'Account details',
                subtitle: 'Name, email, credentials',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Account_detailes(),
                    ),
                  );
                },
              ),

              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: Color(0xFFE4E9F2),
              ),

              ProfileOptionTile(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFF12A6A0),
                iconBackground: const Color(0xFFE5F8F6),
                title: 'Notifications',
                subtitle: 'Alerts and reminders',
                onTap: () {
                  if (onNotificationsTap != null) {
                    onNotificationsTap!();
                  } else {
                    _showMessage(context, 'Notifications selected');
                  }
                },
              ),

              const Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: Color(0xFFE4E9F2),
              ),

              ProfileOptionTile(
                icon: Icons.sync_alt_rounded,
                iconColor: const Color(0xFF2868D7),
                iconBackground: const Color(0xFFEAF1FF),
                title: 'Switch role',
                subtitle: 'Return to role selection',
                onTap: () {
                  if (onSwitchRoleTap != null) {
                    onSwitchRoleTap!();
                  } else {
                    _showMessage(context, 'Switch role selected');
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1E7F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEC),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFE85050),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Log out',
                      style: TextStyle(
                        color: Color(0xFFE85050),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileOptionTile extends StatelessWidget {
  const ProfileOptionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A96AD),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA0ABC0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
