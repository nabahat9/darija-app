import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'record_screen.dart';
import 'theme/app_colors.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? selectedGender;
  bool isLoading = false; // 🔹 loading state

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  void _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
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
      setState(() {
        isLoading = true; // 🔹 show loader
      });

      try {
        final url =
            Uri.parse('https://darija-backend-vtrh.onrender.com/api/register');

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

          // Save all info locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', userId);
          await prefs.setString('name', nameController.text.trim());
          await prefs.setString('age', ageController.text.trim());
          await prefs.setString('gender', selectedGender!);

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
        } else {
          final error =
              jsonDecode(response.body)['error'] ?? 'Registration failed';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() {
          isLoading = false; // 🔹 hide loader
        });
      }
    } else if (selectedGender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select your gender")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 30),
                Center(
                  child: Text(
                    "Welcome to Darija-app",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Center(
                  child: Text(
                    "Explore, record, and enjoy sharing your voice",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Full Name",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 5),
                      TextFormField(
                        enabled: !isLoading, // 🔹 disable when loading
                        controller: nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "Enter your name",
                          suffixIcon: Icon(Icons.person_2_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? "Enter your name"
                            : null,
                      ),
                      SizedBox(height: 15),
                      Text("Age",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 5),
                      TextFormField(
                        enabled: !isLoading, // 🔹 disable when loading
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: "Enter your age",
                          suffixIcon: Icon(Icons.cake_outlined,
                              color: AppColors.primary),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text("Sex",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                      SizedBox(height: 5),
                      ToggleButtons(
                        isSelected: [
                          selectedGender == "Male",
                          selectedGender == "Female"
                        ],
                        onPressed: isLoading
                            ? null
                            : (index) {
                                setState(() {
                                  selectedGender =
                                      index == 0 ? "Male" : "Female";
                                });
                              },
                        borderRadius: BorderRadius.circular(15),
                        borderColor: Colors.grey,
                        selectedBorderColor: AppColors.primary,
                        fillColor: AppColors.primary.withOpacity(0.2),
                        selectedColor: AppColors.primary,
                        color: AppColors.textSecondary,
                        constraints:
                            BoxConstraints(minHeight: 45, minWidth: 110),
                        children: [Text("Male"), Text("Female")],
                      ),
                      SizedBox(height: 35),
                      SizedBox(
                        width: double.infinity,
                        child: isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: submitForm,
                                child: Text(
                                  "Continue",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
