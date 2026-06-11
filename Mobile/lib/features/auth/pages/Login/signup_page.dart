import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Existing Mobile State
  final TextEditingController _mobileController = TextEditingController();
  String _selectedCountryCode = "+91";
  final List<String> _countryCodes = ["+91", "+1", "+44", "+971", "+61"];

  // New Email State
  final TextEditingController _emailController = TextEditingController();
  bool _showEmailField = false; // Toggles email view
  bool _isEmailValid = false;   // Validates button state

  // Email Validation Logic
  void _validateEmail(String val) {
    setState(() {
      _isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val);
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 80,
              errorBuilder: (c, e, s) => const Icon(Icons.sports_soccer, size: 60, color: Color(0xFF00A36C)),
            ),
            const SizedBox(height: 16),
            const Text("Create Account", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // --- SOCIAL BUTTONS ---
            OutlinedButton.icon(
              icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
              label: const Text("Continue with Google", style: TextStyle(color: Colors.black)),
              onPressed: () => context.go('/home'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.apple, size: 24),
              label: const Text("Continue with Apple"),
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            const SizedBox(height: 20),
            const Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // --- TOGGLE EMAIL BUTTON ---
            if (!_showEmailField)
              TextButton(
                onPressed: () => setState(() => _showEmailField = true),
                child: const Text("Use Email Instead", 
                  style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold, fontSize: 16)),
              ),

            // --- CONDITIONAL EMAIL FIELD ---
            if (_showEmailField) ...[
              const Align(alignment: Alignment.centerLeft, child: Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: _validateEmail,
                decoration: InputDecoration(
                  hintText: "Enter your email",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isEmailValid ? () => context.go('/home') : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A36C),
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Create Account", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _showEmailField = false;
                  _emailController.clear();
                }),
                child: const Text("Use Mobile Number instead", style: TextStyle(color: Colors.grey)),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              onChanged: (v) => setState(() => _selectedCountryCode = v!),
              items: _countryCodes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.grey.shade300),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}