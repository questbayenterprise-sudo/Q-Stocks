import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/services/fcm_service.dart';
import '../../Session/user_session.dart';

class OtpPage extends StatefulWidget {
  final String email;
  final String phoneNumber;

  const OtpPage({super.key, required this.email, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  final String baseUrl = AppConfig.baseUrl;

  Future<void> _verifyOtp() async {
    final String otpCode = _otpController.text.trim();

    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the full 6-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse("$baseUrl/Verify_OTP");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "otp": otpCode}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final userData = data['data'];

          if (userData == null) {
            throw Exception("User data missing from server response");
          }

          // Save session
          await UserSession().saveSession(
            userData['id'].toString(),
            userData['username'] ?? "",
            userData['usertype'] ?? "",
          );

          // Save FCM token after login
          await FcmService.init();

          if (!mounted) return;

          context.go('/home');
        } else {
          throw Exception(data['message'] ?? "Invalid OTP code");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    }
  }

  // --- API Method: Resend OTP ---
  Future<void> _resendOtp() async {
    // Implement your resend logic similar to SignIn/Register
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("OTP Resent successfully")));
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Helper to check if phone was actually provided
    final bool hasPhone =
        widget.phoneNumber.trim().isNotEmpty && widget.phoneNumber != "+91";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/logo.png',
              height: 60,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.lock_outline, size: 60),
            ),
            const SizedBox(height: 32),
            const Text(
              "Verify Identity",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Modified Info Section
            Text(
              hasPhone ? "Code sent to:" : "Code sent to your email:",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Email is always shown
            Text(
              widget.email,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            // Phone is only shown if it exists
            if (hasPhone) ...[
              const SizedBox(height: 4),
              Text(
                widget.phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],

            const SizedBox(height: 48),

            // OTP Input
            TextField(
              controller: _otpController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 20,
              ),
              decoration: InputDecoration(
                hintText: "000000",
                hintStyle: TextStyle(
                  color: Colors.grey.shade200,
                  letterSpacing: 20,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00A36C), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A36C),
                disabledBackgroundColor: Colors.grey.shade400,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Verify OTP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    "Change details",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Add Resend logic here
                  },
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Color(0xFF00A36C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
