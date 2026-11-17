import 'package:flutter/material.dart';

import 'package:immunova/Doctor/Analysis/new_analysis_screen.dart';
import 'package:immunova/Doctor/Page_one.dart';
import 'package:immunova/Doctor/Patients_Page.dart';
import 'package:immunova/Doctor/Profile/Profile.dart';

class Home_Page_Screen extends StatefulWidget {
  static const String routeName = '/home';

  const Home_Page_Screen({super.key});

  @override
  State<Home_Page_Screen> createState() =>
      _Home_Page_ScreenState();
}

class _Home_Page_ScreenState
    extends State<Home_Page_Screen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Home',
    'Patients',
    'New Analysis',
    'Profile',
  ];

  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return Page_One_Screen(
          onViewAllPatients: () {
            _changePage(1);
          },
        );

      case 1:
        return const Patients_Page_Screen();

      case 2:
        return  NewAnalysisScreen();

      case 3:
        return const Profile_Screen();

      default:
        return Page_One_Screen(
          onViewAllPatients: () {
            _changePage(1);
          },
        );
    }
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
        toolbarHeight: 74,
        titleSpacing: 12,

        title: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(30),

              onTap: () {
                if (_selectedIndex != 0) {
                  _changePage(0);
                } else if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },

              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,

                decoration: const BoxDecoration(
                  color: Color(0xFFF0F5FF),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 17,
                  color: Color(0xFF2868D7),
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    'Immunova',
                    style: TextStyle(
                      color: Color(0xFF9AA6BE),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    _titles[_selectedIndex],

                    style: const TextStyle(
                      color: Color(0xFF101A38),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            InkWell(
              borderRadius: BorderRadius.circular(30),

              onTap: () {
                _changePage(3);
              },

              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,

                decoration: const BoxDecoration(
                  color: Color(0xFF0B98B5),
                  shape: BoxShape.circle,
                ),

                child: const Text(
                  'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

      body: _getSelectedPage(),

      bottomNavigationBar: Container(
        height: 78,

        decoration: const BoxDecoration(
          color: Colors.white,

          border: Border(
            top: BorderSide(
              color: Color(0xFFE4E9F2),
              width: 1,
            ),
          ),
        ),

        child: SafeArea(
          top: false,

          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,

            children: [
              _buildNavigationItem(
                index: 0,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: 'Home',
              ),

              _buildNavigationItem(
                index: 1,
                icon: Icons.people_outline_rounded,
                selectedIcon: Icons.people_rounded,
                label: 'Patients',
              ),

              _buildNavigationItem(
                index: 2,
                icon: Icons.zoom_in_rounded,
                selectedIcon:
                    Icons.manage_search_rounded,
                label: 'New Analysis',
              ),

              _buildNavigationItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool isSelected =
        _selectedIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          _changePage(index);
        },

        child: SizedBox(
          height: 72,

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                isSelected
                    ? selectedIcon
                    : icon,

                size: 23,

                color: isSelected
                    ? const Color(0xFF2868D7)
                    : const Color(0xFF8E9BB5),
              ),

              const SizedBox(height: 4),

              Text(
                label,

                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF2868D7)
                      : const Color(0xFF8E9BB5),

                  fontSize: 10,

                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
