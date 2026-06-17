import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/services/fcm_service.dart';
import '../../Session/user_session.dart';
import 'auth_header.dart';
import 'signin_view.dart';
import '../../data/repositories/auth_repository.dart';

class AuthEntryPage extends StatefulWidget {
  const AuthEntryPage({super.key});

  @override
  State<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<AuthEntryPage> {
  final AuthRepository _authRepo = AuthRepository();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  bool _isLoading = false;
  bool _isValid = false;

  final RegExp _emailRegex = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  String _selectedCountryCode = "+91";
  final List<String> _countryCodes = ["+91", "+1", "+44", "+971", "+61"];

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateInput);
  }

  void _validateInput() {
    setState(() {
      _isValid = _emailRegex.hasMatch(_emailController.text.trim());
    });
  }

  void _handleAuthSubmit() async {
    if (!_isValid) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final phone = "$_selectedCountryCode${_mobileController.text.trim()}";

    try {
      // 1. Call the signIn method which checks tbl_general_settings
      final result = await _authRepo.signIn(email);
      
      // 2. Pass the result to _processAuthResult
      await _processAuthResult(result, email, phone);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", "")))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processAuthResult(Map<String, dynamic>? result, String email, String phone) async {
    if (result == null) return;

    // If OTP is disabled (local mode) or skipped by server
    if (result['otp_skipped'] == true || !AppConfig.isCloudDb) {
      final userData = result['data'];
      await UserSession().saveSession(
        userData['id'].toString(),
        userData['username']?.toString(),
        userData['usertype']?.toString() ?? 'Customer',
      );
      
      if (AppConfig.isCloudDb) await FcmService.init();
      
      if (mounted) context.go('/home');
    } else {
      // Proceed to OTP screen
      if (mounted) {
        context.push('/otp', extra: {
          'email': email,
          'phone': phone,
          'isSignIn': true,
        });
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
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const AuthHeader(),
              const SizedBox(height: 60),

              // Only SignInView is rendered now
              SignInView(
                emailController: _emailController,
                usernameController: _usernameController,
                mobileController: _mobileController,
                isLoading: _isLoading,
                emailError: _emailError,
                isValid: _isValid,
                countryCodes: _countryCodes,
                selectedCountryCode: _selectedCountryCode,
                onCountryCodeChanged: (val) => setState(() => _selectedCountryCode = val),
                onSubmit: _handleAuthSubmit,
                onSwitchMode: () {
                  // This button is usually at the bottom of SignInView. 
                  // We can either disable it or show an info message.
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}