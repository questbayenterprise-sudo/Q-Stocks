import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../../../auth/Session/user_session.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isLoading = false;

  Future<void> _handleDeleteAccount() async {
    setState(() => _isLoading = true);
    final session = UserSession();
    final String? userId = session.userId;

    try {
      if (AppConfig.isCloudDb) {
        // --- 1. CLOUD DELETE ---
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}/Delete_Cususer'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
        if (response.statusCode != 200) throw Exception("Server failed to delete account");
      } else {
        // --- 2. LOCAL SQLITE DELETE ---
        final db = await DatabaseHelper.instance.database;
        
        // We do a "Soft Delete" so ledger history remains intact but user cannot login
        await db.update(
          'users',
          {'is_active': 0},
          where: 'id = ?',
          whereArgs: [userId],
        );
      }

      // --- 3. CLEAR LOCAL SESSION ---
      await session.clearSession();

      if (!mounted) return;
      
      // Success message and redirect to Login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account deactivated successfully")),
      );
      context.go('/'); // Go back to AuthEntryPage

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Final Confirmation"),
        content: const Text(
          "Are you absolutely sure? You will be logged out and your access to this shop will be revoked.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDeleteAccount();
            },
            child: const Text("YES, DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Account Settings"), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.warning_amber_rounded, size: 100, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              "Deactivate Account?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "By deactivating, you will no longer be able to manage inventory or view sales for this shop. All your existing records will be stored for audit purposes only.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const Spacer(),
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.red)
            else
              ElevatedButton(
                onPressed: () => _showConfirm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "DELETE MY ACCOUNT",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}