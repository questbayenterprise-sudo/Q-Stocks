import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/services/fcm_service.dart';
import '../../Session/user_session.dart';
import '../../data/repositories/auth_repository.dart';

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
  final AuthRepository _authRepo = AuthRepository(); // Instantiate Repo

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
      // Call Repository instead of direct HTTP
      final result = await _authRepo.verifyOtp(widget.email, otpCode);

      if (result['success'] == true) {
        final userData = result['data'];

        // Save Session
        await UserSession().saveSession(
          userData['id'].toString(),
          userData['username'] ?? "",
          userData['usertype'] ?? "Customer",
        );

        // Only init FCM if in Cloud mode
        if (AppConfig.isCloudDb) await FcmService.init();

        if (!mounted) return;
        context.go('/home');
      } else {
        throw Exception(result['message'] ?? "Invalid OTP code");
      }
    } catch (e) {
      // _showSnackBar(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await _authRepo.resendOtp(widget.email);
      _showSnackBar("OTP Resent successfully");
    } catch (e) {
      _showSnackBar("Failed to resend: ${e.toString()}");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

   @override
  Widget build(BuildContext context) {
    final bool hasPhone = widget.phoneNumber.trim().isNotEmpty && widget.phoneNumber != "+91";

    return Scaffold(
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Brand Logo for Broiler Shop
            const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFF00A36C)),
            const SizedBox(height: 32),
            const Text(
              "Verify Identity",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              hasPhone ? "Code sent to:" : "Code sent to your email:",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(widget.email, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (hasPhone) Text(widget.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 48),

            // OTP Input Field
            TextField(
              controller: _otpController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 20),
              decoration: InputDecoration(
                hintText: "000000",
                hintStyle: TextStyle(color: Colors.grey.shade200, letterSpacing: 20),
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
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify OTP", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Change details", style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: _resendOtp,
                  child: const Text("Resend OTP", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
