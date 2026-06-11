import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OwnerOnboardingPage extends StatelessWidget {
  const OwnerOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pending_actions, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                "Our team will verify your details and proceed to the next step.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text("Back to Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}