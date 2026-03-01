import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'record_screen.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? selectedGender;
  bool isLoading = false;

  // Your signature Navy Blue
  final Color primaryNavy = const Color.fromARGB(255, 51, 73, 112);

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  // --- Logic remains the same as your original ---
  void _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RecordScreen(
            name: prefs.getString('name') ?? '',
            age: prefs.getString('age') ?? '',
            gender: prefs.getString('gender') ?? '',
            userId: userId,
          ),
        ),
      );
    }
  }

  void submitForm() async {
    if (_formKey.currentState!.validate() && selectedGender != null) {
      setState(() => isLoading = true);
      try {
        final url = Uri.parse('https://darija-backend-vtrh.onrender.com/api/register');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': nameController.text.trim(),
            'age': int.tryParse(ageController.text.trim()) ?? 0,
            'sex': selectedGender,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final userId = data['user_id'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          await prefs.setString('name', nameController.text.trim());
          await prefs.setString('age', ageController.text.trim());
          await prefs.setString('gender', selectedGender!);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RecordScreen(
                name: nameController.text.trim(),
                age: ageController.text.trim(),
                gender: selectedGender!,
                userId: userId,
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => isLoading = false);
      }
    } else if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your gender")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              // Header Section
              Text(
                "Marhba bik! 👋",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryNavy),
              ),
              const SizedBox(height: 10),
              Text(
                "Help us preserve the Darija dialect by sharing a bit about yourself.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 40),

              // Form Section
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("What's your name?"),
                    _buildTextField(
                      controller: nameController,
                      hint: "e.g. Amina",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 25),
                    
                    _buildLabel("How old are you?"),
                    _buildTextField(
                      controller: ageController,
                      hint: "e.g. 25",
                      icon: Icons.cake_outlined,
                      isNumber: true,
                    ),
                    const SizedBox(height: 25),

                    _buildLabel("Gender"),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _genderCard("Male", Icons.male_rounded),
                        const SizedBox(width: 15),
                        _genderCard("Female", Icons.female_rounded),
                      ],
                    ),
                    
                    const SizedBox(height: 50),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Continue to Recording", 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets for a cleaner build ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryNavy.withOpacity(0.8))),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: !isLoading,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
        style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: primaryNavy),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        validator: (value) => value == null || value.isEmpty ? "Required" : null,
      ),
    );
  }

  Widget _genderCard(String gender, IconData icon) {
    bool isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedGender = gender),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? primaryNavy : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? primaryNavy : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(color: primaryNavy.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : primaryNavy, size: 28),
              const SizedBox(height: 5),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? Colors.white : primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}