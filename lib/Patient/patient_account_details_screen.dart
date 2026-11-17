import 'package:flutter/material.dart';

class PatientAccountDetailsScreen extends StatefulWidget {
  static const String routeName = '/patient_account_details';

  const PatientAccountDetailsScreen({super.key});

  @override
  State<PatientAccountDetailsScreen> createState() =>
      _PatientAccountDetailsScreenState();
}

class _PatientAccountDetailsScreenState
    extends State<PatientAccountDetailsScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Maya Reyes',
  );

  final TextEditingController _dateController = TextEditingController(
    text: '03/12/1994',
  );

  final TextEditingController _emailController = TextEditingController(
    text: 'maya.reyes@patient.immunova.app',
  );

  final TextEditingController _phoneController = TextEditingController(
    text: '(555) 214-7788',
  );

  String _selectedGender = 'Female';

  final List<String> _genderOptions = ['Female', 'Male'];

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1994, 3, 12),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _dateController.text =
            '${selectedDate.month.toString().padLeft(2, '0')}/'
            '${selectedDate.day.toString().padLeft(2, '0')}/'
            '${selectedDate.year}';
      });
    }
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account details updated successfully')),
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
        toolbarHeight: 74,
        titleSpacing: 12,

        title: Row(
          children: [
            // BACK
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.pop(context);
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

            // TITLE
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: TextStyle(
                      color: Color(0xFF9AA6BE),
                      fontSize: 10,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FULL NAME
              const _FieldLabel(text: 'Full name'),

              const SizedBox(height: 7),

              TextField(
                controller: _nameController,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 16),

              // DATE OF BIRTH
              const _FieldLabel(text: 'Date of birth'),

              const SizedBox(height: 7),

              TextField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: _inputDecoration(
                  suffixIcon: IconButton(
                    onPressed: _selectDate,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Color(0xFF101A38),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // GENDER
              const _FieldLabel(text: 'Gender'),

              const SizedBox(height: 7),

              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDDE4EF)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF101A38),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF101A38),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    items: _genderOptions.map((gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // EMAIL
              const _FieldLabel(text: 'Email address'),

              const SizedBox(height: 7),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 16),
              // PHONE
              const _FieldLabel(text: 'Phone number'),

              const SizedBox(height: 7),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration(),
              ),

              const SizedBox(height: 16),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D6CDE), Color(0xFF10AAA6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2868D7).withValues(alpha: 0.20),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _saveChanges,
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Text(
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

  // INPUT STYLE
  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFD),

      suffixIcon: suffixIcon,

      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDDE4EF)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2868D7), width: 1.3),
      ),

      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

// FIELD LABEL
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF34415E),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
