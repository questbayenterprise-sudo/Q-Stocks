import 'package:flutter/material.dart';
import '../../widgets/auth_buttons.dart';

class SignInView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController usernameController;
  final String? emailError;
  final bool isValid;
  final bool isLoading;
  final List<String> countryCodes;
  final String selectedCountryCode;
  final Function(String) onCountryCodeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;

  const SignInView({
    super.key,
    required this.emailController,
    required this.usernameController,
    required this.mobileController,
    required this.emailError,
    required this.isValid,
    this.isLoading = false,
    required this.countryCodes,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    required this.onSubmit,
    required this.onSwitchMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Header Section ---
        const Text(
          "Welcome Back!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Sign in to manage your shop inventory, track daily sales, and update customer ledgers.",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 36),

        // --- Input Fields ---
        _buildSignInFields(),

        const SizedBox(height: 32),

        // --- Action Buttons ---
        AuthPrimaryButton(
          text: "Sign In",
          isLoading: isLoading,
          // Disables button if input is invalid or currently processing
          onPressed: isValid && !isLoading ? onSubmit : null,
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "OR",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),

        const SizedBox(height: 24),

        AuthSecondaryButton(
          text: "New Shop? Create Account",
          onPressed: isLoading ? null : onSwitchMode,
        ),
        
        const SizedBox(height: 12),
        
        // Optional: Forgot Password placeholder if you add that logic later
        Center(
          child: TextButton(
            onPressed: () {
              // Implementation for forgot password
            },
            child: Text(
              "Forgot Credentials?",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInFields() {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => isValid ? onSubmit() : null,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            labelText: "Email Address",
            labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            hintText: "E.g. shopowner@example.com",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
            errorText: emailError,
            prefixIcon: const Icon(
              Icons.email_outlined, 
              color: Color(0xFF00A36C), // Professional Green
              size: 22,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00A36C), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}