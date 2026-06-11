import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import 'auth_buttons.dart';

class GuestRegistrationSheet extends StatefulWidget {
  final VoidCallback onRegistrationSuccess;

  const GuestRegistrationSheet({
    super.key,
    required this.onRegistrationSuccess,
  });

  @override
  State<GuestRegistrationSheet> createState() => _GuestRegistrationSheetState();
}

class _GuestRegistrationSheetState extends State<GuestRegistrationSheet> {
  final String baseUrl = AppConfig.baseUrl;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isLoading = false;
  bool _isValid = false;
  String _selectedCountryCode = "+91";
  final List<String> _countryCodes = ["+91", "+1", "+44", "+971", "+61"];

  final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInput);
    _mobileController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _validateInput() {
    setState(() {
      final bool isEmailValid = _emailRegex.hasMatch(_emailController.text);
      final bool isMobileValid = _mobileController.text.length == 10;
      _isValid = isEmailValid && isMobileValid;
    });
  }

  String? get _emailError {
    final text = _emailController.text;
    if (text.isEmpty) return null;
    if (!_emailRegex.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_isValid) return;

    setState(() => _isLoading = true);

    final registerUrl = Uri.parse("$baseUrl/Create_Cususer");
    final otpUrl = Uri.parse("$baseUrl/Send_OTP");

    try {
      final email = _emailController.text.trim();
      final phone = "$_selectedCountryCode${_mobileController.text.trim()}";
      final username = _usernameController.text.trim().isEmpty
          ? email.split('@')[0]
          : _usernameController.text.trim();

      var request = http.MultipartRequest('POST', registerUrl);
      request.fields['email'] = email;
      request.fields['phoneno'] = phone;
      request.fields['username'] = username;
      request.fields['usertype'] = "Customer";
      request.fields['acccode'] = "CUST_DEFAULT";

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception("Server Error: ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['message'] ?? "Registration failed");
      }

      // Send OTP
      final otpResponse = await http.post(
        otpUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (otpResponse.statusCode != 200) {
        throw Exception("Failed to send OTP");
      }

      final otpData = jsonDecode(otpResponse.body);
      if (otpData['success'] != true) {
        throw Exception(otpData['message'] ?? "OTP sending failed");
      }

      if (!mounted) return;

      // Close the registration sheet
      Navigator.pop(context);

      // Navigate to OTP verification
      context.push(
        '/otp',
        extra: {
          'email': email,
          'phone': phone,
          'isSignIn': false,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Register to Book",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Create an account to proceed with your booking",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Username field
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: "Full Name / Username",
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                errorText: _emailError,
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone field
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                prefixIcon: CountryPicker(
                  selectedCode: _selectedCountryCode,
                  codes: _countryCodes,
                  onChanged: (val) =>
                      setState(() => _selectedCountryCode = val),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isValid && !_isLoading ? _handleRegister : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "CREATE ACCOUNT",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Sign in link
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/');
                },
                child: Text(
                  "Already have an account? Sign In",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
