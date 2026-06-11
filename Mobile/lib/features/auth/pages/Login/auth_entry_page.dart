import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/fcm_service.dart';
import '../../Session/user_session.dart';
import '../../widgets/auth_buttons.dart';
import 'auth_header.dart';
import 'signin_view.dart';
import 'signup_view.dart';

class AuthEntryPage extends StatefulWidget {
  const AuthEntryPage({super.key});

  @override
  State<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<AuthEntryPage> {
  bool _isSignIn = true;
  final String baseUrl = AppConfig.baseUrl;

  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  String _selectedCountryCode = "+91";
  bool _isValid = false;
  final List<String> _countryCodes = ["+91", "+1", "+44", "+971", "+61"];

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_validateInput);
    _emailController.addListener(_validateInput);
  }
Future<void> _registerUser() async {
  final registerUrl = Uri.parse("$baseUrl/Create_Cususer");
  final otpUrl = Uri.parse("$baseUrl/Send_OTP");

  try {
    var request = http.MultipartRequest('POST', registerUrl);

    final email = _emailController.text.trim();
    final phone =
        "$_selectedCountryCode${_mobileController.text.trim()}";
    final username = _usernameController.text.trim().isEmpty
        ? email.split('@')[0]
        : _usernameController.text.trim();

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

    // =========================
    // CALL SEND OTP API
    // =========================
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

    // Check if OTP was skipped (verification disabled)
    if (otpData['otp_skipped'] == true) {
      final userData = otpData['data'];
      await UserSession().saveSession(
        userData['id'].toString(),
        userData['username']?.toString(),
        userData['usertype']?.toString(),
      );
      await FcmService.init();
      if (mounted) context.go('/home');
      return;
    }

    // =========================
    // Navigate to OTP screen
    // =========================
    context.push(
      '/otp',
      extra: {
        'email': email,
        'phone': phone,
        'isSignIn': false,
      },
    );
  } catch (e) {
    rethrow;
  }
}

  void _validateInput() {
    setState(() {
      final bool isEmailValid = _emailRegex.hasMatch(_emailController.text);
      final bool isMobileValid = _mobileController.text.length == 10;

      if (_isSignIn) {
        _isValid = isEmailValid;
      } else {
        _isValid = isEmailValid && isMobileValid;
      }
    });
  }
/// Returns null if OTP was sent normally, or a Map with user data if OTP was skipped.
Future<Map<String, dynamic>?> _sendOTP() async {
  final url = Uri.parse("$baseUrl/Send_OTP");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": _emailController.text.trim(),
        "password": "OTP_FLOW",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (data['otp_skipped'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
        return null; // OTP sent normally
      }
    }

    throw Exception("Failed to send OTP");
  } catch (e) {
    rethrow;
  }
}

  void _handleAuthSubmit() async {
    if (_isValid) {
      if (_isSignIn) {
        setState(() => _isLoading = true);
        try {
          final otpResult = await _sendOTP();
          if (!mounted) return;
          if (otpResult != null) {
            // OTP skipped — auto-login with returned user data
            await UserSession().saveSession(
              otpResult['id'].toString(),
              otpResult['username']?.toString(),
              otpResult['usertype']?.toString(),
            );
            await FcmService.init();
            if (mounted) context.go('/home');
          } else {
            // OTP sent normally — navigate to OTP page
            context.push(
              '/otp',
              extra: {
                'email': _emailController.text.trim(),
                'phone': "",
                'isSignIn': true,
              },
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        // Logic for Create Account
        setState(() => _isLoading = true);
        try {
          await _registerUser();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created successfully!")),
          );

          // After successful DB creation, proceed to OTP
          context.push(
            '/otp',
            extra: {
              'email': _emailController.text.trim(),
              'phone': "$_selectedCountryCode${_mobileController.text.trim()}",
              'isSignIn': false,
            },
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String? get _emailError {
    final text = _emailController.text;
    if (text.isEmpty) return null;
    if (!_emailRegex.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AuthHeader(),
                  const SizedBox(height: 40),

                  AuthSegmentedToggle(
                    isSignIn: _isSignIn,
                    onChanged: (val) {
                      setState(() => _isSignIn = val);
                      _validateInput();
                    },
                  ),

                  const SizedBox(height: 40),

                  _isSignIn
                      ? SignInView(
                          emailController: _emailController,
                          usernameController: _usernameController,
                          mobileController: _mobileController,
                          isLoading: _isLoading,
                          emailError: _emailError,
                          isValid: _isValid,
                          countryCodes: _countryCodes,
                          selectedCountryCode: _selectedCountryCode,
                          onCountryCodeChanged: (val) =>
                              setState(() => _selectedCountryCode = val),
                          onSubmit: _handleAuthSubmit,
                          onSwitchMode: () {
                            setState(() => _isSignIn = false);
                            _validateInput();
                          },
                        )
                      : SignUpView(
                          usernameController:
                              _usernameController, // PASS IT HERE
                          emailController: _emailController,
                          mobileController: _mobileController,
                          isLoading: _isLoading, // PASS LOADING STATE
                          emailError: _emailError,
                          isValid: _isValid,
                          countryCodes: _countryCodes,
                          selectedCountryCode: _selectedCountryCode,
                          onCountryCodeChanged: (val) =>
                              setState(() => _selectedCountryCode = val),
                          onSubmit: _handleAuthSubmit,
                          onSwitchMode: () {
                            setState(() => _isSignIn = true);
                            _validateInput();
                          },
                          onLegacySignUp: () => context.push('/signup'),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // --- Skip Button Component ---
            Positioned(
              top: 10,
              right: 16,
              child: TextButton(
                onPressed: () async {
                  await UserSession().saveSession('', 'Guest', 'guest');
                  if (context.mounted) context.go('/venues');
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Component 2: Toggle Switch ---
