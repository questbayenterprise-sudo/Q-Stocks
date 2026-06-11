import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Sports available on Q-Sports platform
  static const List<Map<String, dynamic>> _sports = [
    {"name": "Football", "icon": Icons.sports_soccer},
    {"name": "Cricket", "icon": Icons.sports_cricket},
    {"name": "Badminton", "icon": Icons.sports_tennis},
    {"name": "Tennis", "icon": Icons.sports_tennis},
    {"name": "Basketball", "icon": Icons.sports_basketball},
    {"name": "Volleyball", "icon": Icons.sports_volleyball},
    {"name": "Hockey", "icon": Icons.sports_hockey},
    {"name": "Table Tennis", "icon": Icons.sports_tennis},
    {"name": "Swimming", "icon": Icons.pool},
    {"name": "Squash", "icon": Icons.sports_tennis},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("About Q-Sports")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- LOGO & BRANDING ---
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 50,
                color: Color(0xFF00A36C),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Q-Sports",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A36C).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "v1.0.2 (Build 44)",
                style: TextStyle(
                  color: Color(0xFF00A36C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "The ultimate platform for sports enthusiasts to find, book, and play on premium turfs across the city.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 30),

            // --- SPORTS WE SUPPORT ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SPORTS WE SUPPORT",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _sports.length,
              itemBuilder: (context, index) {
                final sport = _sports[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        sport["icon"] as IconData,
                        size: 28,
                        color: const Color(0xFF00A36C),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sport["name"] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // --- QUICK LINKS ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "QUICK LINKS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildLinkTile(
                    icon: Icons.description_outlined,
                    title: "Terms & Conditions",
                    isDark: isDark,
                    onTap: () {},
                  ),
                  Divider(
                    height: 1,
                    indent: 56,
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _buildLinkTile(
                    icon: Icons.language,
                    title: "Website",
                    isDark: isDark,
                    isLast: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              "Made with love for sports",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required bool isDark,
    bool isLast = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00A36C).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF00A36C)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
    );
  }
}
