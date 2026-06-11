import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        const Text(
          "Welcome Back!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        _buildTextFieldssignin(),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          text: "Sign In",
          isLoading: isLoading,
          onPressed: isValid && !isLoading ? onSubmit : null,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text("or", style: TextStyle(color: Colors.grey.shade600)),
        ),
        const SizedBox(height: 24),
        AuthSecondaryButton(
          text: "New here? Create Account",
          onPressed: onSwitchMode,
        ),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      children: [
        TextFormField(
          controller: usernameController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: "Username",
            hintText: "Enter your Username",
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email Address",
            hintText: "example@mail.com",
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: "00000 00000",
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

  Widget _buildTextFieldssignin() {
    return Column(
      children: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email Address",
            hintText: "example@mail.com",
            errorText: emailError,
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        // TextFormField(
        //   controller: mobileController,
        //   keyboardType: TextInputType.phone,
        //   inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        //   decoration: InputDecoration(
        //     hintText: "00000 00000",
        //     prefixIcon: _CountryPicker(
        //       selectedCode: selectedCountryCode,
        //       codes: countryCodes,
        //       onChanged: onCountryCodeChanged,
        //     ),
        //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        //   ),
        // ),
      ],
    );
  }
}