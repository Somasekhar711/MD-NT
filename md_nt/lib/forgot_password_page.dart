import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:md_nt/config.dart';
import 'package:md_nt/theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final Color primaryColor = AppColors.primary;

  bool _isLoading = false;
  int _step = 1; // Step 1: Enter Email. Step 2: Answer & Reset.
  String _securityQuestion = "";
  bool _isPasswordVisible = false;

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- API Call 1: Get the Question ---
  Future<void> fetchQuestion() async {
    String email = emailController.text.trim();
    if (email.isEmpty) {
      showSnack('Please enter your email first');
      return;
    }

    setState(() => _isLoading = true);
    final String url = '${AppConfig.baseUrl}/get-security-question';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _securityQuestion = data['question'];
          _step = 2; // Move to the next step!
        });
      } else {
        showSnack('User not found. Check your email.');
      }
    } on TimeoutException {
      showSnack('Server timeout. Check your PC IP and network connection.');
    } catch (e) {
      showSnack('Connection Error. Is the server running?');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- API Call 2: Reset the Password ---
  Future<void> resetPassword() async {
    String email = emailController.text.trim();
    String answer = answerController.text.trim();
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (answer.isEmpty || newPassword.isEmpty) {
      showSnack('Please fill in all fields');
      return;
    }
    if (newPassword.length < 8) {
      showSnack('Password must be at least 8 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      showSnack('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    final String url = '${AppConfig.baseUrl}/reset-password';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'answer': answer,
          'newPassword': newPassword
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        showSnack('Password reset successfully! Please login.');
        if (mounted) Navigator.pop(context); // Go back to login screen
      } else {
        final data = jsonDecode(response.body);
        showSnack(data['message'] ?? 'Failed to reset password');
      }
    } on TimeoutException {
      showSnack('Server timeout. Check your PC IP and network connection.');
    } catch (e) {
      showSnack('Connection Error.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration inputDecoration(String label) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Recovery', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // --- STEP 1 UI ---
              TextField(
                controller: emailController,
                enabled: _step == 1, // Lock email field after step 1
                decoration: inputDecoration('Enter your Email Address'),
              ),
              const SizedBox(height: 20),

              if (_step == 1)
                ElevatedButton(
                  onPressed: _isLoading ? null : fetchQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Find Account', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),

              // --- STEP 2 UI ---
              if (_step == 2) ...[
                const Divider(height: 40, thickness: 2),
                Text(
                  'Security Question:\n$_securityQuestion',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: answerController,
                  decoration: inputDecoration('Your Secret Answer'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: newPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: inputDecoration('Confirm New Password'),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
