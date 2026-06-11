import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/Session/user_session.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Local state for toggles
  bool _pushNotifications = true;
  bool _emailUpdates = false;
  bool _darkMode = ThemeProvider().isDarkMode;
  bool _isLoading = false;

  // BASE URL for your backend
  final String baseUrl = AppConfig.baseUrl;
  String get userId => UserSession().userId ?? "1";

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Fetch settings on load
  }

  // --- FETCH SETTINGS FROM SERVER ---
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/Get_UserSettings');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final settings = data['data'];
          setState(() {
            _pushNotifications = settings['push_notifications'] ?? true;
            _emailUpdates = settings['email_updates'] ?? false;
          });
        }
      } else {
        _showSnackBar("Failed to load settings", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error connecting to server", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CONFIRM SAVE DIALOG ---
  void _confirmSave() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Update"),
        content: const Text("Do you want to save the changes to your settings?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateSettingsToServer();
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFF00A36C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- SAVE SETTINGS TO SERVER ---
  Future<void> _updateSettingsToServer() async {
    setState(() => _isLoading = true);
    final url = Uri.parse('$baseUrl/Update_UserSettings');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "push_notifications": _pushNotifications,
          "email_updates": _emailUpdates,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog();
        } else {
          _showSnackBar(data['message'] ?? "Update failed", isError: true);
        }
      } else {
        _showSnackBar("Server Error: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Connection Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SUCCESS DIALOG ---
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00A36C), size: 80),
            const SizedBox(height: 15),
            const Text("Settings Saved!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00A36C))),
            const Text("Your preferences have been updated.", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A36C)),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SNACKBAR HELPER ---
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: false,
        actions: [
          _isLoading
            ? const Center(child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ))
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

            // --- SECTION 1: NOTIFICATIONS ---
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

            // --- SECTION 3: PRIVACY & PREFERENCES ---
            _buildSectionHeader("Privacy & Preferences"),
            _buildSectionContainer([
              _buildSwitchTile(
                "Dark Mode",
                _darkMode,
                (v) {
                  setState(() => _darkMode = v);
                  ThemeProvider().toggleTheme(v);
                },
              ),
              _buildSettingTile(
                Icons.security,
                "Privacy Policy",
                onTap: () => context.push('/privacy-policy'),
              ),
              _buildSettingTile(
                Icons.delete_outline,
                "Delete Account",
                isDestructive: true,
                isLast: true,
                onTap: () => context.push('/delete-account'),
              ),
            ]),

            const SizedBox(height: 25),

            // --- SECTION 4: SUPPORT ---
            _buildSectionHeader("Support"),
            _buildSectionContainer([
              _buildSettingTile(
                Icons.help_outline,
                "Help Center",
                onTap: () => context.push('/help-center'),
              ),
              _buildSettingTile(
                Icons.info_outline,
                "About Q-Sports",
                isLast: true,
                onTap: () => context.push('/about'),
              ),
            ]),

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

  // --- REUSABLE COMPONENTS (Matches MorePage Style) ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title, {
    String? trailingText,
    bool isLast = false,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.grey[700],
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isDestructive ? Colors.red : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Text(trailingText, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 56),
      ],
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: const TextStyle(fontSize: 16)),
          activeColor: const Color(0xFF00A36C),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}
