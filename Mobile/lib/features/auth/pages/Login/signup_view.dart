import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/auth_buttons.dart';

class SignUpView extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController mobileController;
  final TextEditingController usernameController; // 1. Add this
  final String? emailError;
  final bool isValid;
  final bool isLoading; // 2. Add this for the button spinner
  final List<String> countryCodes;
  final String selectedCountryCode;
  final Function(String) onCountryCodeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;
  final VoidCallback onLegacySignUp;

  const SignUpView({
    required this.emailController,
    required this.mobileController,
    required this.usernameController, // 3. Add to constructor
    required this.emailError,
    required this.isValid,
    this.isLoading = false, // 4. Add to constructor
    required this.countryCodes,
    required this.selectedCountryCode,
    required this.onCountryCodeChanged,
    required this.onSubmit,
    required this.onSwitchMode,
    required this.onLegacySignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Join Q-Sports",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        _buildTextFields(),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          text: "Create Account",
          isLoading: isLoading, // Pass loading state to button
          onPressed: isValid ? onSubmit : null,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text("or", style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(height: 24),
        AuthSecondaryButton(
          text: "Already have an account? Sign In",
          onPressed: onSwitchMode,
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        // 5. ADD THE USERNAME FIELD HERE
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: "Full Name / Username",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Email Address",
            errorText: emailError,
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: mobileController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            prefixIcon: CountryPicker(
              selectedCode: selectedCountryCode,
              codes: countryCodes,
              onChanged: onCountryCodeChanged,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
