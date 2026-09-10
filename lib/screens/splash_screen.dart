import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../utils/session_manager.dart';
import '../widgets/app_logo.dart';
import 'auth_screen.dart';
import 'main_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;

  late AnimationController _textAnimController;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Logo Pop Animation
    _logoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _logoAnimController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoAnimController,
      curve: Curves.easeIn,
    );

    // 2. Subtle Glow Pulse Animation
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    // 3. Staggered Text Slide & Fade
    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textAnimController, curve: Curves.easeOutCubic));

    _textFadeAnimation = CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeIn,
    );

    // Start Animations
    _logoAnimController.forward().then((_) {
      _textAnimController.forward();
    });

    // Execute Startup Sequence & Routing
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimController.dispose();
    _pulseAnimController.dispose();
    _textAnimController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // 1. Check Session & Credentials
    final session = SessionManager();
    final userId = await session.getUserId();
    bool isExpired = false;

    if (userId != null) {
      isExpired = await session.isExpired();
      if (!isExpired && mounted) {
        // Prefetch data in background
        try {
          context.read<EmployeeProvider>().refreshData();
          context.read<ApplianceProvider>().loadAppliances();
        } catch (_) {}
      }
    }

    // 2. Ensure Minimum Splash Duration for smooth visual branding
    final elapsedTime = DateTime.now().difference(startTime).inMilliseconds;
    const minSplashDuration = 1900;
    if (elapsedTime < minSplashDuration) {
      await Future.delayed(Duration(milliseconds: minSplashDuration - elapsedTime));
    }

    if (!mounted) return;

    // 3. Route to destination
    Widget destination;
    if (userId == null) {
      destination = const AuthScreen();
    } else if (isExpired) {
      await session.clearSession();
      destination = const AuthScreen(
        expirationMessage: 'Your 30-day guest period has expired. Please log in or create an account.',
      );
    } else {
      destination = const MainDashboardScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            right: -80,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6366F1).withAlpha(isDark ? 35 : 20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF0D9488).withAlpha(isDark ? 35 : 20),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo with Glow
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: const AppLogo(
                          size: 96,
                          showText: false,
                          heroTag: 'app_splash_logo',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Animated Brand Title & Tagline
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'Task',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F46E5),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 4, top: 8),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Household & Staff Registry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Loading & Security Footer
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Subtle Pill Progress Bar
                  SizedBox(
                    width: 48,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0x204F46E5),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_done_rounded, size: 13, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'Cloud Sync • End-to-End Encrypted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
