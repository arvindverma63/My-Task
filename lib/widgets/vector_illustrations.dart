import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Module 1 Vector Art: Helper Attendance, Calendar & Wages
class AttendanceVectorArt extends StatelessWidget {
  final double size;
  const AttendanceVectorArt({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AttendancePainter(),
    );
  }
}

class _AttendancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Glow Orb
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF10B981).withAlpha(70),
          const Color(0xFF059669).withAlpha(15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.48));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, bgPaint);

    // Decorative floating dots
    final dotPaint = Paint()..color = const Color(0xFF34D399).withAlpha(120);
    canvas.drawCircle(Offset(w * 0.18, h * 0.25), w * 0.03, dotPaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.3), w * 0.022, dotPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.72), w * 0.028, dotPaint);

    // Calendar Card Body
    final calRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.45, h * 0.52), width: w * 0.62, height: h * 0.64),
      Radius.circular(w * 0.08),
    );
    final calShadow = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(calRect.shift(const Offset(0, 8)), calShadow);

    final calBgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFF0FDF4)],
      ).createShader(calRect.outerRect);
    canvas.drawRRect(calRect, calBgPaint);

    // Calendar Header
    final headerPath = Path();
    headerPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(calRect.left, calRect.top, calRect.width, calRect.height * 0.28),
      topLeft: Radius.circular(w * 0.08),
      topRight: Radius.circular(w * 0.08),
    ));
    final headerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ).createShader(calRect.outerRect);
    canvas.drawPath(headerPath, headerPaint);

    // Calendar Rings / Spiral Clips
    final ringPaint = Paint()
      ..color = const Color(0xFFD1FAE5)
      ..style = PaintingStyle.fill;
    final ringBorder = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final cx = calRect.left + (calRect.width * (0.25 + i * 0.25));
      final ringRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, calRect.top), width: w * 0.038, height: h * 0.08),
        Radius.circular(w * 0.02),
      );
      canvas.drawRRect(ringRRect, ringPaint);
      canvas.drawRRect(ringRRect, ringBorder);
    }

    // Grid Dates / Checkmarks on Calendar
    final gridCellPaint = Paint()..color = const Color(0xFFE2E8F0);
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final cx = calRect.left + calRect.width * (0.24 + col * 0.26);
        final cy = calRect.top + calRect.height * (0.46 + row * 0.24);
        if (row == 0 && col == 1) {
          // Highlighted Present Cell
          final activeCell = Paint()..color = const Color(0xFF10B981).withAlpha(40);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.12, height: h * 0.12), Radius.circular(w * 0.03)),
            activeCell,
          );
          // Green checkmark
          final checkPath = Path();
          checkPath.moveTo(cx - w * 0.035, cy);
          checkPath.lineTo(cx - w * 0.01, cy + w * 0.025);
          checkPath.lineTo(cx + w * 0.035, cy - w * 0.025);
          final checkPaint = Paint()
            ..color = const Color(0xFF059669)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = w * 0.018;
          canvas.drawPath(checkPath, checkPaint);
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: w * 0.11, height: h * 0.11), Radius.circular(w * 0.025)),
            gridCellPaint,
          );
        }
      }
    }

    // Helper Avatar Badge (Foreground Right)
    final avatarCenter = Offset(w * 0.74, h * 0.68);
    final avatarRadius = w * 0.22;

    // Avatar Shadow
    canvas.drawCircle(avatarCenter.translate(0, 6), avatarRadius, Paint()..color = Colors.black.withAlpha(45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Avatar Container Circle
    final avatarBg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF059669)],
      ).createShader(Rect.fromCircle(center: avatarCenter, radius: avatarRadius));
    canvas.drawCircle(avatarCenter, avatarRadius, avatarBg);

    // Avatar White Inner Border
    canvas.drawCircle(
      avatarCenter,
      avatarRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Head
    canvas.drawCircle(
      avatarCenter.translate(0, -avatarRadius * 0.22),
      avatarRadius * 0.36,
      Paint()..color = Colors.white,
    );
    // Body / Shoulders (Clipped inside avatar circle)
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: avatarCenter, radius: avatarRadius - 3)));
    final shoulderPath = Path();
    shoulderPath.addOval(Rect.fromCenter(
      center: avatarCenter.translate(0, avatarRadius * 0.7),
      width: avatarRadius * 1.5,
      height: avatarRadius * 1.1,
    ));
    canvas.drawPath(shoulderPath, Paint()..color = Colors.white.withAlpha(235));
    canvas.restore();

    // Floating Rupee / Wage Coin (Top Left)
    final coinCenter = Offset(w * 0.22, h * 0.32);
    final coinRadius = w * 0.13;
    canvas.drawCircle(coinCenter.translate(0, 4), coinRadius, Paint()..color = Colors.black.withAlpha(35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    final coinPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: coinCenter, radius: coinRadius));
    canvas.drawCircle(coinCenter, coinRadius, coinPaint);
    canvas.drawCircle(
      coinCenter,
      coinRadius,
      Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Rupee symbol (₹) on coin
    final textPainter = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(
          color: Colors.white,
          fontSize: coinRadius * 1.15,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, coinCenter.translate(-textPainter.width / 2, -textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Module 2 Vector Art: Ironing & Laundry Registry
class IroningVectorArt extends StatelessWidget {
  final double size;
  const IroningVectorArt({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _IroningPainter(),
    );
  }
}

class _IroningPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Glow Orb
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6366F1).withAlpha(70),
          const Color(0xFF4F46E5).withAlpha(15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.48));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, bgPaint);

    // Stacked Folded Clothes (Bottom Base)
    final clothesColors = [
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFFA78BFA), // Purple
      const Color(0xFFFB7185), // Coral Pink
    ];

    for (int i = 0; i < 3; i++) {
      final cy = h * 0.74 - (i * h * 0.09);
      final cWidth = w * (0.64 - (i * 0.04));
      final cHeight = h * 0.075;
      final clothRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.42, cy), width: cWidth, height: cHeight),
        Radius.circular(w * 0.035),
      );

      // Shadow
      canvas.drawRRect(clothRect.shift(const Offset(0, 4)), Paint()..color = Colors.black.withAlpha(25));
      // Cloth Fill
      canvas.drawRRect(clothRect, Paint()..color = clothesColors[i]);
      // Fold highlight
      canvas.drawLine(
        Offset(clothRect.left + 8, cy),
        Offset(clothRect.right - 8, cy),
        Paint()
          ..color = Colors.white.withAlpha(90)
          ..strokeWidth = 2,
      );
    }

    // Modern Steam Iron (Floating Above Clothes)
    final ironCenter = Offset(w * 0.58, h * 0.42);
    final ironWidth = w * 0.52;
    final ironHeight = h * 0.32;

    // Iron Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(ironCenter.dx, ironCenter.dy + ironHeight * 0.52), width: ironWidth * 0.9, height: ironHeight * 0.22),
      Paint()..color = Colors.black.withAlpha(40)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Iron Soleplate (Base metal)
    final solePath = Path();
    solePath.moveTo(ironCenter.dx - ironWidth * 0.45, ironCenter.dy + ironHeight * 0.25);
    solePath.lineTo(ironCenter.dx + ironWidth * 0.35, ironCenter.dy + ironHeight * 0.25);
    solePath.quadraticBezierTo(
      ironCenter.dx + ironWidth * 0.52,
      ironCenter.dy + ironHeight * 0.2,
      ironCenter.dx + ironWidth * 0.5,
      ironCenter.dy + ironHeight * 0.08,
    );
    solePath.lineTo(ironCenter.dx - ironWidth * 0.45, ironCenter.dy + ironHeight * 0.08);
    solePath.close();
    canvas.drawPath(solePath, Paint()..color = const Color(0xFFCBD5E1));

    // Iron Main Body (Indigo / Deep Blue gradient)
    final bodyPath = Path();
    bodyPath.moveTo(ironCenter.dx - ironWidth * 0.45, ironCenter.dy + ironHeight * 0.08);
    bodyPath.lineTo(ironCenter.dx + ironWidth * 0.35, ironCenter.dy + ironHeight * 0.08);
    bodyPath.quadraticBezierTo(
      ironCenter.dx + ironWidth * 0.54,
      ironCenter.dy + ironHeight * 0.05,
      ironCenter.dx + ironWidth * 0.48,
      ironCenter.dy - ironHeight * 0.12,
    );
    bodyPath.quadraticBezierTo(
      ironCenter.dx + ironWidth * 0.2,
      ironCenter.dy - ironHeight * 0.16,
      ironCenter.dx - ironWidth * 0.45,
      ironCenter.dy - ironHeight * 0.16,
    );
    bodyPath.close();

    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
      ).createShader(Rect.fromCenter(center: ironCenter, width: ironWidth, height: ironHeight));
    canvas.drawPath(bodyPath, bodyPaint);

    // Iron Handle
    final handlePath = Path();
    handlePath.moveTo(ironCenter.dx - ironWidth * 0.4, ironCenter.dy - ironHeight * 0.16);
    handlePath.quadraticBezierTo(
      ironCenter.dx - ironWidth * 0.4,
      ironCenter.dy - ironHeight * 0.46,
      ironCenter.dx - ironWidth * 0.1,
      ironCenter.dy - ironHeight * 0.46,
    );
    handlePath.lineTo(ironCenter.dx + ironWidth * 0.25, ironCenter.dy - ironHeight * 0.46);
    handlePath.quadraticBezierTo(
      ironCenter.dx + ironWidth * 0.42,
      ironCenter.dy - ironHeight * 0.46,
      ironCenter.dx + ironWidth * 0.35,
      ironCenter.dy - ironHeight * 0.16,
    );
    handlePath.lineTo(ironCenter.dx + ironWidth * 0.24, ironCenter.dy - ironHeight * 0.16);
    handlePath.quadraticBezierTo(
      ironCenter.dx + ironWidth * 0.28,
      ironCenter.dy - ironHeight * 0.34,
      ironCenter.dx + ironWidth * 0.15,
      ironCenter.dy - ironHeight * 0.34,
    );
    handlePath.lineTo(ironCenter.dx - ironWidth * 0.22, ironCenter.dy - ironHeight * 0.34);
    handlePath.quadraticBezierTo(
      ironCenter.dx - ironWidth * 0.3,
      ironCenter.dy - ironHeight * 0.34,
      ironCenter.dx - ironWidth * 0.3,
      ironCenter.dy - ironHeight * 0.16,
    );
    handlePath.close();

    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF312E81)],
      ).createShader(Rect.fromCenter(center: ironCenter, width: ironWidth, height: ironHeight));
    canvas.drawPath(handlePath, handlePaint);

    // Steam Vapor Puffs (Left Side)
    final steamPaint = Paint()
      ..color = Colors.white.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    final sPath1 = Path();
    sPath1.moveTo(w * 0.18, h * 0.42);
    sPath1.quadraticBezierTo(w * 0.12, h * 0.38, w * 0.16, h * 0.32);
    canvas.drawPath(sPath1, steamPaint);

    final sPath2 = Path();
    sPath2.moveTo(w * 0.22, h * 0.48);
    sPath2.quadraticBezierTo(w * 0.15, h * 0.45, w * 0.20, h * 0.38);
    canvas.drawPath(sPath2, steamPaint);

    // Rate Tag Badge (Top Right)
    final tagCenter = Offset(w * 0.78, h * 0.22);
    final tagRadius = w * 0.14;
    canvas.drawCircle(tagCenter.translate(0, 4), tagRadius, Paint()..color = Colors.black.withAlpha(30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    final tagPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
      ).createShader(Rect.fromCircle(center: tagCenter, radius: tagRadius));
    canvas.drawCircle(tagCenter, tagRadius, tagPaint);
    canvas.drawCircle(
      tagCenter,
      tagRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Rate Tag Text (e.g. S, M, L)
    final tagText = TextPainter(
      text: const TextSpan(
        text: 'S/M/L',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tagText.layout();
    tagText.paint(canvas, tagCenter.translate(-tagText.width / 2, -tagText.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Module 3 Vector Art: Appliances, LPG Gas Cylinder & Warranties
class ApplianceVectorArt extends StatelessWidget {
  final double size;
  const ApplianceVectorArt({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AppliancePainter(),
    );
  }
}

class _AppliancePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Glow Orb
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF0D9488).withAlpha(70),
          const Color(0xFF0F766E).withAlpha(15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.48));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, bgPaint);

    // Modern Air Conditioner Unit (Top Left to Center)
    final acRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.42, h * 0.38), width: w * 0.58, height: h * 0.24),
      Radius.circular(w * 0.04),
    );
    // AC Shadow
    canvas.drawRRect(acRect.shift(const Offset(0, 6)), Paint()..color = Colors.black.withAlpha(30)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // AC Body
    final acPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
      ).createShader(acRect.outerRect);
    canvas.drawRRect(acRect, acPaint);
    canvas.drawRRect(acRect, Paint()..color = const Color(0xFF0D9488)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // AC Display LED Screen
    final ledRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(acRect.right - w * 0.11, acRect.top + h * 0.07), width: w * 0.12, height: h * 0.05),
      Radius.circular(w * 0.015),
    );
    canvas.drawRRect(ledRect, Paint()..color = const Color(0xFF0F172A));
    // LED 24°C text
    final ledText = TextPainter(
      text: const TextSpan(
        text: '24°',
        style: TextStyle(
          color: Color(0xFF2DD4BF),
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    ledText.layout();
    ledText.paint(canvas, Offset(ledRect.left + (ledRect.width - ledText.width) / 2, ledRect.top + (ledRect.height - ledText.height) / 2));

    // AC Air Louver Vents (Bottom of AC)
    final ventLine = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(acRect.left + w * 0.06, acRect.bottom - h * 0.04),
      Offset(acRect.right - w * 0.06, acRect.bottom - h * 0.04),
      ventLine,
    );

    // Cool Air Breeze Lines
    final breezePaint = Paint()
      ..color = const Color(0xFF38BDF8).withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < 3; i++) {
      final startX = acRect.left + w * (0.12 + i * 0.16);
      final startY = acRect.bottom - 2;
      final breezePath = Path();
      breezePath.moveTo(startX, startY);
      breezePath.quadraticBezierTo(startX - w * 0.04, startY + h * 0.1, startX - w * 0.08, startY + h * 0.16);
      canvas.drawPath(breezePath, breezePaint);
    }

    // LPG Gas Cylinder (Bottom Right Foreground)
    final cylCenter = Offset(w * 0.72, h * 0.68);
    final cylW = w * 0.30;
    final cylH = h * 0.44;

    // Cylinder Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cylCenter.dx, cylCenter.dy + cylH * 0.48), width: cylW * 0.9, height: cylH * 0.18),
      Paint()..color = Colors.black.withAlpha(40)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Cylinder Body
    final cylRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: cylCenter, width: cylW, height: cylH * 0.75),
      Radius.circular(cylW * 0.28),
    );

    final cylPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
      ).createShader(cylRect.outerRect);
    canvas.drawRRect(cylRect, cylPaint);

    // Cylinder Top Neck / Collar
    final collarRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cylCenter.dx, cylCenter.dy - cylH * 0.40), width: cylW * 0.55, height: cylH * 0.18),
      Radius.circular(cylW * 0.1),
    );
    canvas.drawRRect(collarRect, Paint()..color = const Color(0xFF991B1B));
    canvas.drawRRect(
      collarRect,
      Paint()
        ..color = Colors.white.withAlpha(120)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Cylinder Center Band Line
    canvas.drawLine(
      Offset(cylRect.left + 4, cylCenter.dy),
      Offset(cylRect.right - 4, cylCenter.dy),
      Paint()
        ..color = Colors.white.withAlpha(90)
        ..strokeWidth = 2,
    );

    // Warranty Shield Badge (Floating Top Right / Center)
    final shieldCenter = Offset(w * 0.24, h * 0.72);
    final shieldSize = w * 0.24;

    // Shield Shadow
    canvas.drawCircle(shieldCenter.translate(0, 4), shieldSize * 0.45, Paint()..color = Colors.black.withAlpha(35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    final shieldPath = Path();
    shieldPath.moveTo(shieldCenter.dx, shieldCenter.dy - shieldSize * 0.45);
    shieldPath.lineTo(shieldCenter.dx + shieldSize * 0.4, shieldCenter.dy - shieldSize * 0.25);
    shieldPath.quadraticBezierTo(
      shieldCenter.dx + shieldSize * 0.35,
      shieldCenter.dy + shieldSize * 0.3,
      shieldCenter.dx,
      shieldCenter.dy + shieldSize * 0.48,
    );
    shieldPath.quadraticBezierTo(
      shieldCenter.dx - shieldSize * 0.35,
      shieldCenter.dy + shieldSize * 0.3,
      shieldCenter.dx - shieldSize * 0.4,
      shieldCenter.dy - shieldSize * 0.25,
    );
    shieldPath.close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
      ).createShader(Rect.fromCircle(center: shieldCenter, radius: shieldSize * 0.5));
    canvas.drawPath(shieldPath, shieldPaint);

    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Shield Checkmark
    final checkPath = Path();
    checkPath.moveTo(shieldCenter.dx - shieldSize * 0.16, shieldCenter.dy + shieldSize * 0.02);
    checkPath.lineTo(shieldCenter.dx - shieldSize * 0.03, shieldCenter.dy + shieldSize * 0.14);
    checkPath.lineTo(shieldCenter.dx + shieldSize * 0.18, shieldCenter.dy - shieldSize * 0.1);
    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Module 4 Vector Art: Reports, Analytics & Cloud Settings
class ReportsSettingsVectorArt extends StatelessWidget {
  final double size;
  const ReportsSettingsVectorArt({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ReportsSettingsPainter(),
    );
  }
}

class _ReportsSettingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Glow Orb
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF59E0B).withAlpha(70),
          const Color(0xFFD97706).withAlpha(15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.5), radius: w * 0.48));
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.48, bgPaint);

    // Floating Report Document
    final docRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.44, h * 0.48), width: w * 0.54, height: h * 0.62),
      Radius.circular(w * 0.05),
    );
    // Shadow
    canvas.drawRRect(docRect.shift(const Offset(0, 8)), Paint()..color = Colors.black.withAlpha(35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));

    // White Document Body
    final docPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFFEF3C7)],
      ).createShader(docRect.outerRect);
    canvas.drawRRect(docRect, docPaint);
    canvas.drawRRect(docRect, Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Document Header Banner (PDF / Analytics badge)
    final docHeader = RRect.fromRectAndRadius(
      Rect.fromLTWH(docRect.left + w * 0.05, docRect.top + h * 0.05, docRect.width * 0.4, h * 0.07),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(docHeader, Paint()..color = const Color(0xFFEF4444));
    final pdfText = TextPainter(
      text: const TextSpan(
        text: 'PDF',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pdfText.layout();
    pdfText.paint(canvas, Offset(docHeader.left + (docHeader.width - pdfText.width) / 2, docHeader.top + (docHeader.height - pdfText.height) / 2));

    // Document Lines
    final linePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(docRect.left + w * 0.05, docRect.top + h * 0.16), Offset(docRect.right - w * 0.05, docRect.top + h * 0.16), linePaint);
    canvas.drawLine(Offset(docRect.left + w * 0.05, docRect.top + h * 0.22), Offset(docRect.right - w * 0.12, docRect.top + h * 0.22), linePaint);

    // Bar Chart inside document
    final barColors = [const Color(0xFF38BDF8), const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFF6366F1)];
    final barHeights = [0.12, 0.18, 0.14, 0.22];
    for (int i = 0; i < 4; i++) {
      final bx = docRect.left + w * (0.07 + i * 0.10);
      final bHeight = h * barHeights[i];
      final by = docRect.bottom - h * 0.06;
      final barRRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(bx, by - bHeight, w * 0.065, bHeight),
        topLeft: Radius.circular(w * 0.015),
        topRight: Radius.circular(w * 0.015),
      );
      canvas.drawRRect(barRRect, Paint()..color = barColors[i]);
    }

    // Floating Cloud Sync Badge (Bottom Right)
    final cloudCenter = Offset(w * 0.74, h * 0.68);
    final cloudRadius = w * 0.20;

    // Cloud Shadow
    canvas.drawCircle(cloudCenter.translate(0, 5), cloudRadius, Paint()..color = Colors.black.withAlpha(35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    final cloudPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: cloudCenter, radius: cloudRadius));
    canvas.drawCircle(cloudCenter, cloudRadius, cloudPaint);
    canvas.drawCircle(
      cloudCenter,
      cloudRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Settings Cog / Sync Icon inside badge
    final cogPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw central circular ring
    canvas.drawCircle(cloudCenter, cloudRadius * 0.38, cogPaint);

    // Draw 6 cog teeth around
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final p1 = Offset(
        cloudCenter.dx + (cloudRadius * 0.42) * math.cos(angle),
        cloudCenter.dy + (cloudRadius * 0.42) * math.sin(angle),
      );
      final p2 = Offset(
        cloudCenter.dx + (cloudRadius * 0.62) * math.cos(angle),
        cloudCenter.dy + (cloudRadius * 0.62) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, cogPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
