import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SuccessCountdownDialog extends StatefulWidget {
  final VoidCallback onFinished;
  const SuccessCountdownDialog({super.key, required this.onFinished});

  @override
  State<SuccessCountdownDialog> createState() => _SuccessCountdownDialogState();
}

class _SuccessCountdownDialogState extends State<SuccessCountdownDialog> {
  int _counter = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_counter > 1) {
        setState(() => _counter--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 16),
          const Text("Payment Successful", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Booking Confirmed", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          // Countdown UI
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.green.withOpacity(0.1),
            child: Text("$_counter", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onFinished,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}