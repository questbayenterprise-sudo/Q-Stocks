import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/Session/user_session.dart';
import '../../features/qr_scan/presentation/pages/qr_scanner_page.dart';

const _kGreen = Color(0xFF00A36C);
const _kGreenLight = Color(0xFF00D28D);

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final userType = UserSession().userType;
    if (userType == UserType.guest) return const _GuestNav();
    if (userType == UserType.owner ||
        userType == UserType.vendor ||
        userType == UserType.manager) return const _OwnerNav();
    return _DefaultNav(isAdmin: userType == UserType.admin);
  }
}

// ═══════════════════════════════════════════
// NAV ITEM — Glow dot + bounce icon
// ═══════════════════════════════════════════

class _TabItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() async {
    HapticFeedback.lightImpact();
    _ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: widget.isActive ? 6 : 0,
                height: widget.isActive ? 6 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                  boxShadow: widget.isActive
                      ? [BoxShadow(color: _kGreen.withAlpha(120), blurRadius: 8, spreadRadius: 1)]
                      : [],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? (isDark ? _kGreen.withAlpha(25) : _kGreen.withAlpha(12))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isActive ? widget.activeIcon : widget.icon,
                  color: widget.isActive ? _kGreen : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                  size: 23,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: widget.isActive ? _kGreen : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                  fontSize: 10,
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// GUEST NAV
// ═══════════════════════════════════════════

class _GuestNav extends StatelessWidget {
  const _GuestNav();

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final idx = path.startsWith('/more') ? 1 : 0;
    return _buildBar(context, 64, Row(
      children: [
        _TabItem(
          icon: Icons.storefront_outlined, 
          activeIcon: Icons.storefront, 
          label: "Shop", 
          isActive: idx == 0, 
          onTap: () => context.go('/shops')
        ),
        _TabItem(
          icon: Icons.menu_rounded, 
          activeIcon: Icons.menu_rounded, 
          label: "More", 
          isActive: idx == 1, 
          onTap: () => context.go('/more')
        ),
      ],
    ));
  }
}

// ═══════════════════════════════════════════
// DEFAULT NAV — Admin & User
// ═══════════════════════════════════════════

class _DefaultNav extends StatelessWidget {
  final bool isAdmin;
  const _DefaultNav({required this.isAdmin});

  int _idx(BuildContext context) {
    final p = GoRouterState.of(context).uri.path;
    if (p.startsWith('/home')) return 0;
    if (p.startsWith('/shops') || p.startsWith('/my-shops') || p.startsWith('/add-shop') || p.startsWith('/my-add-shop')) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _idx(context);
    return _buildBar(context, 68, Row(
      children: [
        _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: "Home", isActive: idx == 0, onTap: () => context.go('/home')),
        _TabItem(
          icon: Icons.shopping_basket_outlined, 
          activeIcon: Icons.shopping_basket, 
          label: isAdmin ? "Shops" : "Shop", 
          isActive: idx == 1, 
          onTap: () => context.go(isAdmin ? '/my-shops' : '/shops')
        ),
        _TabItem(icon: Icons.menu_rounded, activeIcon: Icons.menu_rounded, label: "More", isActive: idx == 2, onTap: () => context.go('/more')),
      ],
    ));
  }
}

// ═══════════════════════════════════════════
// OWNER NAV — with floating scan
// ═══════════════════════════════════════════

class _OwnerNav extends StatelessWidget {
  const _OwnerNav();

  int _idx(BuildContext context) {
    final p = GoRouterState.of(context).uri.path;
    if (p.startsWith('/home')) return 0;
    if (p.startsWith('/my-shops') || p.startsWith('/my-add-shop')) return 1;
    if (p.startsWith('/sales') || p.startsWith('/inventory')) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _idx(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 90 + pad,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 12,
            right: 12,
            bottom: pad + 8,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(isDark ? 60 : 18), blurRadius: 28, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: "Home", isActive: idx == 0, onTap: () => context.go('/home')),
                  _TabItem(
                    icon: Icons.storefront_outlined, 
                    activeIcon: Icons.storefront, 
                    label: "My Shops", 
                    isActive: idx == 1, 
                    onTap: () => context.go('/my-shops')
                  ),
                  const SizedBox(width: 76),
                  _TabItem(
                    icon: Icons.receipt_long_outlined, 
                    activeIcon: Icons.receipt_long, 
                    label: "Sales", 
                    isActive: idx == 3, 
                    onTap: () => context.go('/inventory/sales')
                  ),
                  _TabItem(icon: Icons.menu_rounded, activeIcon: Icons.menu_rounded, label: "More", isActive: idx == 4, onTap: () => context.go('/more')),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: pad + 28,
            left: 0,
            right: 0,
            child: Center(child: _ScanFab(isDark: isDark)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// SCAN FAB (Invoices / QR Sales)
// ═══════════════════════════════════════════

class _ScanFab extends StatefulWidget {
  final bool isDark;
  const _ScanFab({required this.isDark});

  @override
  State<_ScanFab> createState() => _ScanFabState();
}

class _ScanFabState extends State<_ScanFab> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (c, a, b) => const QrScannerPage(),
          transitionsBuilder: (c, anim, b, child) => FadeTransition(opacity: anim, child: child),
        ));
      },
      child: AnimatedBuilder(
        listenable: _glowAnim,
        builder: (context, child) {
          return Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_kGreenLight, _kGreen, Color(0xFF008F5D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              border: Border.all(color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white, width: 4),
              boxShadow: [
                BoxShadow(color: _kGreen.withAlpha((_glowAnim.value * 120).toInt()), blurRadius: 20, spreadRadius: 4),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 22),
                SizedBox(height: 1),
                Text("SCAN", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildBar(BuildContext context, double h, Widget child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: EdgeInsets.only(left: 12, right: 12, bottom: MediaQuery.of(context).padding.bottom + 8),
    child: Container(
      height: h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(isDark ? 60 : 18), blurRadius: 28, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: child),
    ),
  );
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;
  const AnimatedBuilder({super.key, required super.listenable, required this.builder, this.child});
  @override
  Widget build(BuildContext context) => builder(context, child);
}