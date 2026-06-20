import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/Session/user_session.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Active settings state
  bool _darkMode = ThemeProvider().isDarkMode;
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _isLoading = false;

  final String baseUrl = AppConfig.baseUrl;
  String get userId => UserSession().userId ?? "0";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // --- HYBRID LOAD LOGIC ---
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    if (AppConfig.isCloudDb) {
      try {
        final url = Uri.parse('$baseUrl/Get_UserSettings');
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"user_id": userId}),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final s = data['data'];
            setState(() {
              _pushNotifications = s['push_notifications'] ?? true;
              _emailUpdates = s['email_updates'] ?? false;
            });
          }
        }
      } catch (_) {}
    } else {
      // LOCAL SQLITE FETCH
      try {
        final db = await DatabaseHelper.instance.database;
        final List<Map<String, dynamic>> res = await db.query(
          'user_settings',
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (res.isNotEmpty) {
          final s = res.first;
          setState(() {
            _pushNotifications = s['push_notify'] == 1;
            _emailUpdates = s['mail_upd'] == 1;
            _darkMode = s['themes'] == 'dark';
          });
        }
      } catch (e) {
        debugPrint("Local Settings Error: $e");
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // --- HYBRID SAVE LOGIC ---
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    if (AppConfig.isCloudDb) {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/Update_UserSettings'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "user_id": userId,
            "push_notifications": _pushNotifications,
            "email_updates": _emailUpdates,
          }),
        );
        if (response.statusCode == 200 && jsonDecode(response.body)['success'] == true) {
          _showSuccessDialog();
        }
      } catch (e) {
        _showSnackBar("Cloud sync failed", isError: true);
      }
    } else {
      // LOCAL SQLITE SAVE
      try {
        final db = await DatabaseHelper.instance.database;
        await db.insert(
          'user_settings',
          {
            'user_id': userId,
            'push_notify': _pushNotifications ? 1 : 0,
            'mail_upd': _emailUpdates ? 1 : 0,
            'themes': _darkMode ? 'dark' : 'light',
            'language_type': 'en',
            'region': 'IN',
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        _showSuccessDialog();
      } catch (e) {
        _showSnackBar("Local save failed: $e", isError: true);
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _confirmSave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Update"),
        content: const Text("Save changes to your preferences?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSettings();
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        actions: [
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(
                  onPressed: _confirmSave,
                  child: const Text("Save", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            /* 
            --- COMMENTED SECTION 1: NOTIFICATIONS ---
            _buildSectionHeader("Notifications"),
            _buildSectionContainer([
              _buildSwitchTile(
                "Push Notifications",
                _pushNotifications,
                (v) => setState(() => _pushNotifications = v),
              ),
              _buildSwitchTile(
                "Email Updates",
                _emailUpdates,
                (v) => setState(() => _emailUpdates = v),
              ),
            ]),
            const SizedBox(height: 25),
            */

            // --- SECTION 3: PRIVACY & PREFERENCES ---
            _buildSectionContainer([
              _buildSwitchTile(
                "Dark Mode",
                _darkMode,
                (v) {
                  setState(() => _darkMode = v);
                  ThemeProvider().toggleTheme(v);
                },
                isLast: false, // Set to false because Delete Account follows
              ),
              /*
              _buildSettingTile(
                Icons.security,
                "Privacy Policy",
                onTap: () => context.push('/privacy-policy'),
              ),
              */
              _buildSettingTile(
                Icons.delete_outline,
                "Delete Account",
                isDestructive: true,
                isLast: true,
                onTap: () => context.push('/delete-account'),
              ),
            ]),

            /* 
            --- COMMENTED SECTION 4: SUPPORT ---
            const SizedBox(height: 25),
            _buildSectionHeader("Support"),
            _buildSectionContainer([
              _buildSettingTile(
                Icons.help_outline,
                "Help Center",
                onTap: () => context.push('/help-center'),
              ),
              _buildSettingTile(
                Icons.info_outline,
                "About Manager App",
                isLast: true,
                onTap: () => context.push('/about'),
              ),
            ]),
            */

            const SizedBox(height: 40),
            const Text(
              "Version 1.0.2 (Build 44)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI HELPERS (KEEPING YOUR MOREPAGE STYLE)
  // ============================================================

  Widget _buildSectionContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged, {bool isLast = false}) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: const TextStyle(fontSize: 16)),
          activeColor: const Color(0xFF00A36C),
        ),
        if (!isLast) const Divider(height: 1, indent: 16),
      ],
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {bool isLast = false, bool isDestructive = false, VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700]),
          title: Text(title, style: TextStyle(fontSize: 16, color: isDestructive ? Colors.red : null)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ),
        if (!isLast) const Divider(height: 1, indent: 56),
      ],
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00A36C), size: 60),
            const SizedBox(height: 15),
            const Text("Settings Saved", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Your preferences have been updated.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }
}