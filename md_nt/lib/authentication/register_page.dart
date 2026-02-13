import 'package:flutter/material.dart';
import 'dart:convert'; // For JSON encoding
import 'package:http/http.dart' as http; // For making requests
import 'package:md_nt/config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // To show loading spinner

  final Color primaryColor = const Color.fromARGB(255, 0, 132, 255);

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> register() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // --- 1. Client-Side Validation (Keep this to save server resources) ---
    if (username.isEmpty) {
      showSnack('Username must not be empty');
      return;
    }
    if (email.isEmpty) {
      showSnack('Email must not be empty');
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      showSnack('Enter a valid email');
      return;
    }
    
    // Password Strength Checks
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'\d'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLen = password.length >= 8;

    if (!hasUpper || !hasLower || !hasDigit || !hasSpecial || !hasMinLen) {
      showSnack('Password does not meet requirements');
      return;
    }

    if (password != confirmPassword) {
      showSnack('Passwords do not match');
      return;
    }

    // --- 2. Server Communication ---
    setState(() => _isLoading = true);

    // Using central config
    final String url = '${AppConfig.baseUrl}/register';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'name': username,
          'email': email,
          'password': password,
        }),
      );

      // --- 3. Handle Response ---
      if (response.statusCode == 201) {
        // Success
        showSnack('Registered successfully!');
        if (mounted) Navigator.pop(context); // Go back to login
      } else {
        // Error (e.g., User already exists)
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        showSnack(responseData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      showSnack('Connection Error: Is the server running?');
      print("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading spinner
        });
      }
    }
  }

  InputDecoration inputDecoration(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      suffixIcon: suffix,
    );
  }

  Widget passwordRule(bool valid, String text) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: valid ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: valid ? Colors.green : Colors.red)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String password = passwordController.text;

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'\d'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLen = password.length >= 8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false, // removes back arrow
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const SizedBox(height: 100),

                  TextField(
                    controller: usernameController,
                    decoration: inputDecoration('Username'),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration('Email'),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    onChanged: (_) => setState(() {}),
                    decoration: inputDecoration(
                      'Password',
                      suffix: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      passwordRule(hasMinLen, 'At least 8 characters'),
                      passwordRule(hasUpper, 'Uppercase letter'),
                      passwordRule(hasLower, 'Lowercase letter'),
                      passwordRule(hasDigit, 'Number'),
                      passwordRule(hasSpecial, 'Special character'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: inputDecoration(
                      'Confirm Password',
                      suffix: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : register, // Disable if loading
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isLoading 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Already registered? Login',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}