import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/session_manager.dart';
import '../widgets/vector_illustrations.dart';
import 'auth_screen.dart';
import 'main_dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isNavigating = false;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Helper Attendance & Salary',
      hindiTitle: 'कामवाली / हेल्पर अटेंडेंस व पगार',
      subtitle: '1-tap Present / Absent tracking with auto-computed salary & advance balances.',
      accentColor: Color(0xFF10B981),
      icon: Icons.people_alt_rounded,
      navLabel: 'Attendance',
      highlights: [
        'Default Present architecture with 1-tap Absent toggle',
        'Tracks daily & monthly helper cash advances',
        'Auto-computed working days & wage balances',
      ],
      vectorWidget: AttendanceVectorArt(size: 190),
    ),
    _OnboardingItem(
      title: 'Ironing & Dhobi Tracker',
      hindiTitle: 'धोबी / इस्त्री का हिसाब व रेट कार्ड',
      subtitle: 'Batch cloth tallying by sizes with dynamic rate cards and vendor settlements.',
      accentColor: Color(0xFF6366F1),
      icon: Icons.iron_rounded,
      navLabel: 'Ironing',
      highlights: [
        'Stepper counter for Small, Medium, Large & XL garments',
        'Customizable rate card matrix per vendor',
        'Cumulative wage earnings vs payments ledger',
      ],
      vectorWidget: IroningVectorArt(size: 190),
    ),
    _OnboardingItem(
      title: 'Appliances & Home Services',
      hindiTitle: 'घरेलू उपकरण, गैस सिलिंडर व सर्विस',
      subtitle: 'Track LPG gas refills, drinking water delivery, AC service and asset warranties.',
      accentColor: Color(0xFF0D9488),
      icon: Icons.devices_other_rounded,
      navLabel: 'Services & Assets',
      highlights: [
        'LPG cylinder & water can refill countdowns',
        'Warranty expiry alarms & digital invoice safe-keep',
        'Chronological service & repair history logs',
      ],
      vectorWidget: ApplianceVectorArt(size: 190),
    ),
    _OnboardingItem(
      title: 'PDF Reports & Settings',
      hindiTitle: 'रिपोर्ट्स, बैकअप व एकाउंट सेटिंग्स',
      subtitle: '1-click executive PDF statement exports, secure cloud sync and custom themes.',
      accentColor: Color(0xFFF59E0B),
      icon: Icons.settings_rounded,
      navLabel: 'Settings',
      highlights: [
        'Professional PDF attendance & wage salary slips',
        'Cloud sync & 30-day frictionless guest trial',
        'Sleek Dark / Light theme options',
      ],
      vectorWidget: ReportsSettingsVectorArt(size: 190),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding([int targetTab = 0]) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding_v2', true);

    final session = SessionManager();
    final uid = await session.getUserId();
    if (uid == null) {
      try {
        final response = await http.post(
          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/register-guest'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            await session.saveSession(
              userId: data['userId'],
              username: data['username'],
              userType: data['userType'],
              expiresAt: data['expiresAt'],
            );
          }
        }
      } catch (_) {
        // Fallback local guest session
        await session.saveSession(
          userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          username: 'Guest User',
          userType: 'guest',
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MainDashboardScreen(initialIndex: targetTab),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  void _onOptionTapped(int index) {
    HapticFeedback.selectionClick();
    if (_currentPage != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentItem = _items[_currentPage];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: App Branding & Navigation Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: currentItem.accentColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: currentItem.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'My-Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.tonal(
                    onPressed: _isNavigating ? null : () => _completeOnboarding(0),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Carousel: Vector Graphic + Details Card
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Vector Graphic Hero
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: item.vectorWidget,
                        ),

                        // Bilingual Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.accentColor.withAlpha(isDark ? 45 : 25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.accentColor.withAlpha(60),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.hindiTitle,
                            style: TextStyle(
                              color: item.accentColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Main Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Subtitle
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Highlights List
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: item.highlights.map((h) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3.5),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 15,
                                      color: item.accentColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        h,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom 4-Option Interactive Vector / Icon Selector (Place of Bottom Navigation)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 60 : 10),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 4 Options Grid/Bar (Interactive bottom selector)
                  Row(
                    children: List.generate(_items.length, (index) {
                      final item = _items[index];
                      final isSelected = _currentPage == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onOptionTapped(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? item.accentColor.withAlpha(isDark ? 40 : 25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? item.accentColor
                                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isSelected
                                      ? item.accentColor
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.navLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? item.accentColor
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),

                  // Navigation Dots & Action Buttons
                  Row(
                    children: [
                      // Dots Indicator
                      Row(
                        children: List.generate(_items.length, (index) {
                          final isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 5),
                            height: 6,
                            width: isSelected ? 18 : 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? currentItem.accentColor
                                  : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),

                      // Action Button
                      FilledButton(
                        onPressed: _isNavigating
                            ? null
                            : () {
                                if (_currentPage < _items.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                  );
                                } else {
                                  _completeOnboarding(_currentPage);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: currentItem.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isNavigating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currentPage == _items.length - 1
                                        ? 'Open ${currentItem.navLabel}'
                                        : 'Next: ${_items[_currentPage + 1].navLabel}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _currentPage == _items.length - 1
                                        ? Icons.arrow_forward_rounded
                                        : Icons.chevron_right_rounded,
                                    size: 16,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String hindiTitle;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String navLabel;
  final List<String> highlights;
  final Widget vectorWidget;

  const _OnboardingItem({
    required this.title,
    required this.hindiTitle,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.navLabel,
    required this.highlights,
    required this.vectorWidget,
  });
}
