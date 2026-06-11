import 'package:flutter/material.dart';

class TurfLoader extends StatelessWidget {
  final String message;
  const TurfLoader({super.key, this.message = "Publishing your Turf..."});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7), // Dims the background
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A nice green circular progress
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A36C)),
              strokeWidth: 5,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none, // Removes yellow underline
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Getting the ground ready ⚽",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}