import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Help Center")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- HOW TO BOOK A TURF ---
          _buildSectionHeader("How do I book a turf?"),
          const SizedBox(height: 12),
          _buildStep(
            context,
            stepNumber: "1",
            icon: Icons.search,
            title: "Browse Venues",
            description: "Open the Venues tab and explore available turfs near you.",
            isDark: isDark,
          ),
          _buildStepConnector(isDark),
          _buildStep(
            context,
            stepNumber: "2",
            icon: Icons.sports_soccer,
            title: "Select a Turf",
            description: "Tap on a venue to view details, courts, and pricing.",
            isDark: isDark,
          ),
          _buildStepConnector(isDark),
          _buildStep(
            context,
            stepNumber: "3",
            icon: Icons.calendar_today,
            title: "Pick a Slot",
            description: "Choose your preferred date and available time slot.",
            isDark: isDark,
          ),
          _buildStepConnector(isDark),
          _buildStep(
            context,
            stepNumber: "4",
            icon: Icons.check_circle_outline,
            title: "Confirm Booking",
            description: "Review your selection and confirm to reserve your spot.",
            isDark: isDark,
          ),

          const SizedBox(height: 30),

          // --- CONTACT SUPPORT ---
          ListTile(
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            leading: const Icon(Icons.mail_outline, color: Color(0xFF00A36C)),
            title: const Text("Contact Support"),
            subtitle: const Text("support@qsports.com"),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, {
    required String stepNumber,
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF00A36C),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: const Color(0xFF00A36C)),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: Container(
        width: 2,
        height: 20,
        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
    );
  }
}
