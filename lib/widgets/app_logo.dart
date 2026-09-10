import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;
  final String? subtitle;
  final String heroTag;

  const AppLogo({
    super.key,
    this.size = 72,
    this.showText = true,
    this.isDark = false,
    this.subtitle,
    this.heroTag = 'app_logo_hero',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: heroTag,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1), // Indigo
                  Color(0xFF4F46E5), // Deep Indigo
                  Color(0xFF0D9488), // Teal
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withAlpha(isDark ? 90 : 70),
                  blurRadius: size * 0.35,
                  offset: Offset(0, size * 0.12),
                ),
                BoxShadow(
                  color: const Color(0xFF0D9488).withAlpha(isDark ? 60 : 40),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle decorative background grid/concentric glow
                Positioned.fill(
                  child: CustomPaint(
                    painter: _LogoGlowPainter(size: size),
                  ),
                ),
                // Core Emblem
                Icon(
                  Icons.task_alt_rounded,
                  size: size * 0.54,
                  color: Colors.white,
                ),
                // Sparkle indicator on top right
                Positioned(
                  top: size * 0.15,
                  right: size * 0.15,
                  child: Container(
                    width: size * 0.18,
                    height: size * 0.18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE047), // Amber/Yellow
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFDE047).withAlpha(120),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded, size: 8, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Task',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4F46E5),
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 3, top: 4),
                width: size * 0.08,
                height: size * 0.08,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: size * 0.16,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }
}

class _LogoGlowPainter extends CustomPainter {
  final double size;
  _LogoGlowPainter({required this.size});

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withAlpha(50),
          Colors.white.withAlpha(0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size * 0.3, size * 0.3),
        radius: size * 0.45,
      ));

    canvas.drawCircle(Offset(size * 0.3, size * 0.3), size * 0.45, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
