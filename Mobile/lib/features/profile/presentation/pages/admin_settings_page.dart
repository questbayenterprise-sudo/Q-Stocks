import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final String baseUrl = AppConfig.baseUrl;

  bool _enableVerifyOtp = true;
  bool _enableSkipLogin = true;
  int _retryCountLimit = 5;
  bool _enablePayment = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Get_AdminSettings'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final settings = data['data'];
          setState(() {
            _enableVerifyOtp = settings['enable_verify_otp'] ?? true;
            _enableSkipLogin = settings['enable_skip_login'] ?? true;
            _retryCountLimit = settings['retry_count_limit'] ?? 5;
            _enablePayment = settings['enable_payment'] ?? false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load settings: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(Map<String, dynamic> update) async {
    setState(() => _isSaving = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Update_AdminSettings'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(update),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Settings updated"),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "General Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Authentication"),
                  const SizedBox(height: 8),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      icon: Icons.verified_user_outlined,
                      iconColor: const Color(0xFF00A36C),
                      title: "OTP Verification",
                      subtitle: "Require OTP verification during login & signup",
                      value: _enableVerifyOtp,
                      onChanged: (val) {
                        setState(() => _enableVerifyOtp = val);
                        _updateSetting({"enable_verify_otp": val});
                      },
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildSwitchTile(
                      icon: Icons.login_outlined,
                      iconColor: Colors.blue,
                      title: "Skip Login",
                      subtitle: "Allow users to browse without logging in",
                      value: _enableSkipLogin,
                      onChanged: (val) {
                        setState(() => _enableSkipLogin = val);
                        _updateSetting({"enable_skip_login": val});
                      },
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildRetryLimitTile(isDark),
                  ]),

                  const SizedBox(height: 24),

                  _buildSectionHeader("Payments"),
                  const SizedBox(height: 8),
                  _buildSettingsCard(isDark, [
                    _buildSwitchTile(
                      icon: Icons.payment_outlined,
                      iconColor: Colors.orange,
                      title: "Enable Payment",
                      subtitle: "Enable online payment for bookings",
                      value: _enablePayment,
                      onChanged: (val) {
                        setState(() => _enablePayment = val);
                        _updateSetting({"enable_payment": val});
                      },
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Container(
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

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF00A36C),
            ),
    );
  }

  Widget _buildRetryLimitTile(bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.refresh, color: Colors.purple, size: 22),
      ),
      title: const Text(
        "OTP Retry Limit",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: Text(
        "Max OTP attempts before cooldown",
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: _retryCountLimit > 1
                  ? () {
                      setState(() => _retryCountLimit--);
                      _updateSetting({"retry_count_limit": _retryCountLimit});
                    }
                  : null,
            ),
            Text(
              "$_retryCountLimit",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: _retryCountLimit < 10
                  ? () {
                      setState(() => _retryCountLimit++);
                      _updateSetting({"retry_count_limit": _retryCountLimit});
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
