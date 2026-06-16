import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/Session/user_session.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userType = UserSession().userType;
    final isAdminOrOwner = userType == UserType.admin || userType == UserType.owner || userType == UserType.vendor || userType == UserType.manager;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 10),

              // SECTION 1: CORE BUSINESS
              _buildSectionContainer(context, [
                _buildMenuTile(
                  icon: Icons.storefront_outlined,
                  title: "My Shops",
                  subtitle: "Manage shop branches and locations",
                  iconColor: Colors.brown,
                  onTap: () => context.push('/my-shops'),
                ),
                _buildMenuTile(
                  icon: Icons.shopping_basket_outlined,
                  title: "Products",
                  subtitle: "Chicken, Eggs & Inventory items",
                  iconColor: Colors.orange,
                  onTap: () => context.push('/products'),
                ),
                _buildMenuTile(
                  icon: Icons.groups_outlined,
                  title: "Customers",
                  subtitle: "Ledger notebook and balances",
                  iconColor: Colors.blue,
                  onTap: () => context.push('/customers'),
                ),
                // INVENTORY DROPDOWN
                _buildExpansionMenuTile(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  title: "Inventory",
                  iconColor: Colors.teal,
                  children: [
                    _buildSubMenuTile(
                      title: "Sales",
                      icon: Icons.point_of_sale_outlined,
                      onTap: () => context.push('/inventory/sales'),
                    ),
                    _buildSubMenuTile(
      title: "Income Entry",
      icon: Icons.add_card_outlined,
      onTap: () => context.push('/inventory/income'),
    ),
                    _buildSubMenuTile(
                      title: "Stocks",
                      icon: Icons.warehouse_outlined,
                      onTap: () => context.push('/inventory/stocks'),
                    ),
                    _buildSubMenuTile(
                      title: "Reports",
                      icon: Icons.analytics_outlined,
                      onTap: () => context.push('/inventory/reports'),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 15),

              // SECTION 2: ADMINISTRATION
              _buildSectionContainer(context, [
                _buildMenuTile(
                  icon: Icons.settings_outlined,
                  title: "App Settings",
                  subtitle: "Notifications and Theme",
                  iconColor: const Color(0xFF00A36C),
                  onTap: () => context.push('/settings'),
                ),
                if (UserSession().userType == UserType.admin) ...[
                  _buildMenuTile(
                    icon: Icons.admin_panel_settings_outlined,
                    title: "General Settings",
                    subtitle: "OTP & System Config",
                    iconColor: Colors.deepPurple,
                    onTap: () => context.push('/admin-settings'),
                  ),
                  _buildMenuTile(
                    icon: Icons.people_outlined,
                    title: "Manage Users",
                    subtitle: "Staff roles and access",
                    iconColor: Colors.indigo,
                    onTap: () => context.push('/admin-users'),
                    isLast: true,
                  ),
                ]
              ]),

              const SizedBox(height: 15),

              // SECTION 3: LOGOUT
              _buildSectionContainer(context, [
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

  // --- HELPER: Expansion Tile for Inventory ---
  Widget _buildExpansionMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        children: children,
      ),
    );
  }

  // --- HELPER: Sub-menu items for Inventory ---
  Widget _buildSubMenuTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.only(left: 70, right: 20),
      leading: Icon(icon, size: 20, color: Colors.grey),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
    );
  }

  // --- Standard Header (Keep yours) ---
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
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "U",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF00A36C)))
                  : null,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("View/Edit Shop Profile", style: TextStyle(color: Colors.grey, fontSize: 14)),
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
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
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
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)) : null,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
        if (!isLast) const Divider(height: 1, indent: 70),
      ],
    );
  }
}