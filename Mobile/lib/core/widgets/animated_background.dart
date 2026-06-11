import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/theme_provider.dart';

/// Global animated background wrapper.
/// Wraps any page with a subtle animated gradient + floating particles.
/// No external assets required — pure Flutter animation.
///
/// Usage:
///   AnimatedBackground(child: YourPageContent())
///
/// Configure globally via [AnimatedBackgroundConfig].
class AnimatedBackgroundConfig {
  AnimatedBackgroundConfig._();
  static final AnimatedBackgroundConfig _instance =
      AnimatedBackgroundConfig._();
  factory AnimatedBackgroundConfig() => _instance;

  /// Master toggle — set false to disable everywhere
  bool enabled = true;

  /// Show floating particles
  bool showParticles = true;

  /// Overlay opacity (0.0 = none, 1.0 = fully opaque)
  double overlayOpacity = 0.7;

  /// Animation speed multiplier (1.0 = normal)
  double speedMultiplier = 1.0;
}

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  /// Override to disable for specific pages
  final bool? enabled;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.enabled,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final speed = AnimatedBackgroundConfig().speedMultiplier;

    _gradientController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (8000 / speed).round()),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (12000 / speed).round()),
    )..repeat();

    _particles = List.generate(6, (_) => _Particle.random());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause animation when app is in background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _gradientController.stop();
      _particleController.stop();
    } else if (state == AppLifecycleState.resumed) {
      if (_isEnabled) {
        _gradientController.repeat(reverse: true);
        _particleController.repeat();
      }
    }
  }

  bool get _isEnabled =>
      (widget.enabled ?? AnimatedBackgroundConfig().enabled);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) return widget.child;

    final isDark = context.isDark;
    final config = AnimatedBackgroundConfig();

    return Stack(
      children: [
        // ── Animated gradient background ──
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, _) {
            final t = _gradientController.value;

            final colors = isDark
                ? [
                    Color.lerp(
                        const Color(0xFF0A1628), const Color(0xFF0F2027), t)!,
                    Color.lerp(
                        const Color(0xFF121212), const Color(0xFF1A1A2E), t)!,
                    Color.lerp(
                        const Color(0xFF0D1B2A), const Color(0xFF16213E), t)!,
                  ]
                : [
                    Color.lerp(
                        const Color(0xFFF0FFF0), const Color(0xFFE8F5E9), t)!,
                    Color.lerp(
                        const Color(0xFFF5F5F5), const Color(0xFFE3F2FD), t)!,
                    Color.lerp(
                        const Color(0xFFFFF8E1), const Color(0xFFF3E5F5), t)!,
                  ];

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    -1.0 + t * 0.5,
                    -1.0 + t * 0.3,
                  ),
                  end: Alignment(
                    1.0 - t * 0.5,
                    1.0 - t * 0.3,
                  ),
                  colors: colors,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            );
          },
        ),

        // ── Floating particles ──
        if (config.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  isDark: isDark,
                ),
              );
            },
          ),

        // ── Semi-transparent overlay for readability ──
        Container(
          color: isDark
              ? Colors.black.withValues(alpha: config.overlayOpacity * 0.4)
              : Colors.white.withValues(alpha: config.overlayOpacity),
        ),

        // ── Foreground content ──
        widget.child,
      ],
    );
  }
}

// ── Particle data ──

class _Particle {
  final double x; // 0..1 horizontal position
  final double y; // 0..1 start vertical
  final double size;
  final double speed; // 0..1
  final double opacity;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  factory _Particle.random() {
    final r = math.Random();
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: 3.0 + r.nextDouble() * 6.0,
      speed: 0.3 + r.nextDouble() * 0.7,
      opacity: 0.08 + r.nextDouble() * 0.15,
    );
  }
}

// ── Particle painter ──

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool isDark;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final yOffset = (p.y + progress * p.speed) % 1.2 - 0.1;
      final xWobble = math.sin(progress * math.pi * 2 * p.speed) * 0.02;

      final center = Offset(
        (p.x + xWobble) * size.width,
        yOffset * size.height,
      );

      final paint = Paint()
        ..color = isDark
            ? const Color(0xFF00A36C).withValues(alpha: p.opacity)
            : const Color(0xFF00A36C).withValues(alpha: p.opacity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8);

      canvas.drawCircle(center, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
