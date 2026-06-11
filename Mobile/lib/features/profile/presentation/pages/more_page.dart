import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 10),

              // First Grouped Section
              _buildSectionContainer(context, [
                // Update this specific tile inside your grouped section
                _buildMenuTile(
                  icon: Icons.receipt_long_outlined,
                  title: "My Bookings",
                  subtitle: "View Transactions & Receipts",
                  iconColor: const Color(0xFF00A36C),
                  onTap: () => context.push('/my-bookings'),
                ),
                _buildMenuTile(
                  icon: Icons.favorite_outlined,
                  title: UserSession().userType == UserType.admin ||
                          UserSession().userType == UserType.owner ||
                          UserSession().userType == UserType.vendor ||
                          UserSession().userType == UserType.manager
                      ? "Venue Likes"
                      : "My Favorites",
                  subtitle: UserSession().userType == UserType.admin ||
                          UserSession().userType == UserType.owner
                      ? "View all venue likes"
                      : "Your liked venues",
                  iconColor: Colors.red.shade400,
                  onTap: () => context.push('/liked-venues'),
                ),
                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  subtitle: "Privacy, Notifications, Theme",
                  iconColor: const Color(0xFF00A36C),
                  onTap: () => context.push('/settings'),
                  isLast: UserSession().userType != UserType.admin,
                ),
                if (UserSession().userType == UserType.admin)
                  _buildMenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: "General Settings",
                    subtitle: "OTP, Login, Payment configurations",
                    iconColor: Colors.deepPurple,
                    onTap: () => context.push('/admin-settings'),
                  ),
                if (UserSession().userType == UserType.admin)
                  _buildMenuTile(
                    icon: Icons.people_outlined,
                    title: "Manage Users",
                    subtitle: "View, edit roles, delete users",
                    iconColor: Colors.blue,
                    onTap: () => context.push('/admin-users'),
                  ),
                if (UserSession().userType == UserType.admin)
                  _buildMenuTile(
                    icon: Icons.link_outlined,
                    title: "Venue Mapping",
                    subtitle: "Assign venues to users",
                    iconColor: Colors.orange,
                    onTap: () => context.push('/venue-mapping'),
                    isLast: true,
                  ),
                // _buildMenuTile(
                //   icon: Icons.group_outlined,
                //   title: "Playpals",
                //   subtitle: "View & Manage Players",
                //   iconColor: const Color(0xFF00A36C),
                // ),
                // _buildMenuTile(
                //   icon: Icons.account_balance_wallet_outlined,
                //   title: "Passbook",
                //   subtitle: "Manage Karma, Playo credits, etc",
                //   iconColor: const Color(0xFF00A36C),
                // ),
                // _buildMenuTile(
                //   icon: Icons.shield_outlined,
                //   title: "Preference and Privacy",
                //   subtitle: "Sports, Locations, Notifications, etc",
                //   iconColor: const Color(0xFF00A36C),
                //   isLast: true,
                // ),
              ]),

              const SizedBox(height: 15),

              // Second Grouped Section
              _buildSectionContainer(context, [
                // _buildMenuTile(
                //   icon: Icons.percent_outlined,
                //   title: "Offers",
                //   isSimple: true,
                // ),
                // _buildMenuTile(
                //   icon: Icons.article_outlined,
                //   title: "Blogs",
                //   isSimple: true,
                // ),
                // _buildMenuTile(
                //   icon: Icons.card_giftcard_outlined,
                //   title: "Invite & Earn",
                //   badge: "EARN 50 KARMA",
                //   isSimple: true,
                // ),
                // _buildMenuTile(
                //   icon: Icons.support_outlined,
                //   title: "Help & Support",
                //   isSimple: true,
                // ),
                _buildMenuTile(
                  icon: Icons.logout,
                  title: "Logout",
                  iconColor: Colors.red,
                  isSimple: true,
                  isLast: true,
                  onTap: () async {
                    await UserSession().clearSession();
                    if (context.mounted) context.go('/');
                  },
                ),
              ]),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final displayName = UserSession().username ?? "User";
    final imageUrl = UserSession().imageUrl;
    return InkWell(
      onTap: () => context.push('/edit-profile'),
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF00A36C).withAlpha(25),
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A36C),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "View your full profile",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, List<Widget> children) {
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

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool isLast = false,
    bool isSimple = false,
    String? badge,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? Colors.grey.shade600),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              color: iconColor == Colors.red ? Colors.red : null,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              Icon(Icons.chevron_right, color: Colors.grey.shade300),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 70),
      ],
    );
  }

  // REMOVED: _buildBottomNav helper method has been deleted.
}
