import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Last Updated: March 2026",
                style: TextStyle(
                  color: Color(0xFF00A36C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildPolicySection(
              context,
              icon: Icons.storage_outlined,
              title: "1. Data Collection",
              content:
                  "We collect personal information that you provide when creating your account, including your name, email address, phone number, and profile details. We also collect booking history and usage data to improve our services.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.analytics_outlined,
              title: "2. How We Use Your Data",
              content:
                  "Your data is used to process bookings, manage your account, send booking confirmations and reminders, and improve the Q-Sports experience. We do not sell your personal data to third parties.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.share_outlined,
              title: "3. Data Sharing",
              content:
                  "We may share your information with venue owners solely for the purpose of fulfilling your bookings. We may also share data with service providers who assist us in operating the app, subject to confidentiality agreements.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.shield_outlined,
              title: "4. Data Security",
              content:
                  "We implement industry-standard security measures to protect your personal information from unauthorized access, alteration, or disclosure. Your data is encrypted in transit and at rest.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.cookie_outlined,
              title: "5. Cookies & Tracking",
              content:
                  "We use minimal tracking to understand app usage patterns and improve performance. No third-party advertising trackers are used within the app.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.manage_accounts_outlined,
              title: "6. Your Rights",
              content:
                  "You have the right to access, update, or delete your personal data at any time through your account settings. You may also request a copy of your data or opt out of non-essential communications.",
              isDark: isDark,
            ),
            _buildPolicySection(
              context,
              icon: Icons.update_outlined,
              title: "7. Policy Updates",
              content:
                  "We may update this Privacy Policy from time to time. Any changes will be reflected on this page with an updated revision date. Continued use of the app after changes constitutes acceptance.",
              isDark: isDark,
              isLast: true,
            ),

            const SizedBox(height: 24),

            // Contact card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mail_outline, color: Color(0xFF00A36C)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Questions about your privacy?",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "privacy@qsports.com",
                          style: TextStyle(color: Color(0xFF00A36C), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF00A36C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
