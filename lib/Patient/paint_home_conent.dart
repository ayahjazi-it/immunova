import 'package:flutter/material.dart';
import 'package:immunova/Patient/log_symptom_screen.dart';
import 'package:immunova/Patient/my_report_screen.dart';
import 'package:immunova/Patient/my_treatment_plan_screen.dart';

class PatientHomeContent extends StatelessWidget {
  final int patientId;

  const PatientHomeContent({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // OVERVIEW TITLE
            // ==========================================
            const Text(
              'OVERVIEW',
              style: TextStyle(
                color: Color(0xFF97A3BC),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // RISK INDEX CARD
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F7F8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular percentage
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 62,
                          height: 62,
                          child: CircularProgressIndicator(
                            value: 0.91,
                            strokeWidth: 7,
                            backgroundColor: Colors.white,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                              Color(0xFF12A99D),
                            ),
                          ),
                        ),
                        const Text(
                          '91%',
                          style: TextStyle(
                            color: Color(0xFF078C84),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your risk index',
                          style: TextStyle(
                            color: Color(0xFF101A38),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        SizedBox(height: 6),

                        Text(
                          'Elevated this week — recent symptoms and markers are trending up. Consider reaching out to your care team.',
                          style: TextStyle(
                            color: Color(0xFF56627A),
                            fontSize: 11.5,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // RECENT CHECK-INS
            const Text(
              'RECENT CHECK-INS',
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
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFDDE4EF),
                ),
              ),
              child: const Column(
                children: [
                  _SymptomItem(
                    icon: Icons.brightness_5_outlined,
                    iconColor: Color(0xFF0FA99F),
                    iconBackground: Color(0xFFE3F7F5),
                    title: 'Butterfly rash',
                    subtitle: 'Mild · Today',
                  ),

                  Divider(
                    height: 1,
                    color: Color(0xFFE2E7F0),
                  ),

                  _SymptomItem(
                    icon: Icons.brightness_5_outlined,
                    iconColor: Color(0xFFFF716D),
                    iconBackground: Color(0xFFFFEBE9),
                    title: 'Fatigue',
                    subtitle: 'Severe · 2 days ago',
                  ),

                  Divider(
                    height: 1,
                    color: Color(0xFFE2E7F0),
                  ),

                  _SymptomItem(
                    icon: Icons.brightness_5_outlined,
                    iconColor: Color(0xFF5788FF),
                    iconBackground: Color(0xFFE8F0FF),
                    title: 'Joint pain',
                    subtitle: 'Moderate · 2 days ago',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // MY CARE

            const Text(
              'MY CARE',
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
                  _CareItem(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF0DA89D),
                    iconBackground: const Color(0xFFE2F7F4),
                    title: 'My report',
                    subtitle: 'View your latest clinical summary',
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyReportScreen(
                          patientId: patientId,
                        ),
                      ),
                    );
                    },
                  ),

                  const Divider(
                    height: 1,
                    color: Color(0xFFE2E7F0),
                  ),

                  _CareItem(
                    icon: Icons.check_box_outlined,
                    iconColor: const Color(0xFF4277E8),
                    iconBackground: const Color(0xFFE8F0FF),
                    title: 'My treatment plan',
                    subtitle: 'See what your doctor prescribed',
                    onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MyTreatmentPlanScreen(
                        ),
                      ),
                    );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// SYMPTOM ITEM


class _SymptomItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  const _SymptomItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF101A38),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF8996AF),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// MY CARE ITEM


class _CareItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CareItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
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
                      style: const TextStyle(
                        color: Color(0xFF101A38),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8996AF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF93A0B9),
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}