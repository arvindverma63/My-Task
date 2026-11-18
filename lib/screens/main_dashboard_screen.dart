import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_management_screen.dart';
import 'ironing_dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'theme_settings_screen.dart';
import 'user_profile_screen.dart';
import 'onboarding_screen.dart';

import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../models/appliance_model.dart';
import '../utils/session_manager.dart';
import '../widgets/vector_illustrations.dart';
import '../widgets/app_ui.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const MainDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  bool _isGuest = false;
  int _guestDaysRemaining = 30;
  String? _userId;
  String _username = 'User';
  String? _profilePic;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
      // If user came from onboarding selecting a specific module > 0, direct them once
      if (widget.initialIndex == 1) {
        _navigateTo(const IroningDashboardScreen());
      } else if (widget.initialIndex == 2) {
        _navigateTo(const MaintenanceScreen());
      } else if (widget.initialIndex == 3) {
        _navigateTo(ThemeSettingsScreen(
          onStartTour: _showTourGuideDialog,
        ));
      }
    });
  }

  Future<void> _loadSession() async {
    final session = SessionManager();
    final type = await session.getUserType();
    final days = await session.getDaysRemaining();
    final uid = await session.getUserId();
    final uname = await session.getUsername();
    final pic = await session.getProfilePic();

    if (mounted) {
      setState(() {
        _isGuest = type == 'guest';
        _guestDaysRemaining = days;
        _userId = uid;
        _username = (uname != null && uname.isNotEmpty) ? uname : (_isGuest ? 'Guest User' : 'User');
        _profilePic = pic;
      });
    }

    if (uid != null && uid.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/get-profile?userId=$uid'),
          headers: {'X-User-Id': uid, 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            await session.saveSession(
              userId: uid,
              username: data['username'] ?? _username,
              userType: data['userType'] ?? (type ?? 'guest'),
              expiresAt: data['expiresAt'],
              profilePic: data['profilePic'],
            );
            final freshDays = await session.getDaysRemaining();
            if (mounted) {
              setState(() {
                _isGuest = ((data['userType'] ?? type ?? 'guest') == 'guest');
                _username = data['username'] ?? _username;
                _profilePic = data['profilePic'] ?? _profilePic;
                _guestDaysRemaining = freshDays;
              });
            }
          }
        }
      } catch (e) {
        // Fallback gracefully on network timeout
      }
    }
  }

  Future<void> _handleManualSync() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        context.read<EmployeeProvider>().refreshData(),
        context.read<ApplianceProvider>().loadAppliances(),
      ]);
      await _loadSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Data synchronized!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _navigateTo(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadSession());
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Welcome';
    }
  }

  Widget _buildGuestBanner() {
    if (!_isGuest) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Free guest trial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$_guestDaysRemaining days left • Upgrade to keep your data',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _showSubscriptionDialog,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFB45309),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog() {
    bool isSaving = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF78350F), const Color(0xFF92400E)]
                            : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A)],
                      ),
                      border: Border(
                        bottom: BorderSide(color: isDark ? const Color(0xFFD97706) : const Color(0xFFFCD34D)),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFD97706),
                          child: const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Upgrade to Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF78350F),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withAlpha(20),
                            padding: const EdgeInsets.all(4),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Unlock unlimited helper logs, ironing registries, appliance warranty trackers, and instant cloud sync across all your devices.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(isDark ? 30 : 15),
                            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(120), width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'LIFETIME PASS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B), letterSpacing: 0.8),
                                  ),
                                  Spacer(),
                                  Text(
                                    '₹999 One-Time',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay once, enjoy forever. No recurring charges or hidden fees.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withAlpha(isDark ? 25 : 12),
                            border: Border.all(color: const Color(0xFF0D9488).withAlpha(80), width: 1.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Color(0xFF0D9488), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'ANNUAL PASS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF0D9488), letterSpacing: 0.8),
                                  ),
                                  Spacer(),
                                  Text(
                                    '₹299 / Year',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Billed annually with automatic backup & priority support.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  setDlgState(() => isSaving = true);
                                  try {
                                    final uid = _userId ?? '';
                                    final response = await http.post(
                                      Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/update-subscription?userId=$uid'),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Accept': 'application/json',
                                        'X-User-Id': uid,
                                      },
                                      body: json.encode({'userId': uid}),
                                    );
                                    final data = json.decode(response.body);
                                    if (response.statusCode == 200 && data['success'] == true) {
                                      await SessionManager().saveSession(
                                        userId: uid,
                                        username: _username,
                                        userType: 'registered',
                                        expiresAt: null,
                                      );
                                      await _loadSession();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('🎉 You are now a Premium Member!'),
                                            backgroundColor: Color(0xFF059669),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(data['error'] ?? 'Subscription upgrade failed.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Network error. Check connection.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } finally {
                                    setDlgState(() => isSaving = false);
                                  }
                                },
                          child: isSaving
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Upgrade Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkFirstLaunch() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final applianceProvider = Provider.of<ApplianceProvider>(context, listen: false);

    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch_v2') ?? true;

    if (!mounted) return;

    if (isFirstLaunch &&
        employeeProvider.employees.isEmpty &&
        employeeProvider.ironingWorkers.isEmpty &&
        applianceProvider.appliances.isEmpty) {
      await _seedSampleData();
      await prefs.setBool('is_first_launch_v2', false);
    }
  }

  Future<void> _seedSampleData() async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final applianceProvider = Provider.of<ApplianceProvider>(context, listen: false);
      final userId = await SessionManager().getUserId() ?? 'user';
      final pfx = '${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Seed Employees
      final emp1 = Employee(
        id: '${pfx}_emp_1',
        name: 'Ramesh Kumar',
        contact: '9876543210',
        joiningDate: DateTime.now().subtract(const Duration(days: 45)),
        baseSalary: 450,
        salaryBasis: 'daily',
      );
      final emp2 = Employee(
        id: '${pfx}_emp_2',
        name: 'Sunita Sharma',
        contact: '9123456789',
        joiningDate: DateTime.now().subtract(const Duration(days: 60)),
        baseSalary: 15000,
        salaryBasis: 'monthly',
      );
      await employeeProvider.addEmployee(emp1);
      await employeeProvider.addEmployee(emp2);

      // Seed attendance for Ramesh
      final now = DateTime.now();
      for (int i = 1; i <= 5; i++) {
        final date = now.subtract(Duration(days: i));
        final status = i % 5 == 0 ? AttendanceStatus.absent : (i % 6 == 0 ? AttendanceStatus.late : AttendanceStatus.present);
        final attendance = AttendanceEntry(
          id: '${pfx}_att_1_$i',
          employeeId: emp1.id,
          date: date,
          status: status,
          checkInTime: status != AttendanceStatus.absent ? '09:00 AM' : null,
          checkOutTime: status != AttendanceStatus.absent ? '06:00 PM' : null,
          amountGiven: i == 3 ? 500 : 0,
          paymentDescription: i == 3 ? 'Advance for festival' : '',
        );
        await employeeProvider.markAttendance(attendance);
      }

      // 2. Seed Ironing Workers
      final worker1 = IroningWorker(
        id: '${pfx}_worker_1',
        name: 'Karan Singh',
        contact: '9988776655',
        joiningDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      await employeeProvider.addIroningWorker(worker1);

      // Seed specific rates for Karan Singh
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_big_rate', clothingType: 'Big Clothes', rate: 7.0, date: DateTime.now()));
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_small_rate', clothingType: 'Small Clothes', rate: 4.0, date: DateTime.now()));
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_sheets_rate', clothingType: 'Sheets', rate: 10.0, date: DateTime.now()));
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_others_rate', clothingType: 'Others', rate: 5.0, date: DateTime.now()));

      // 3. Seed Appliances & Home Services
      final appliance1 = Appliance(
        id: '${pfx}_app_1',
        name: 'Daikin AC 1.5 Ton',
        type: 'Air Conditioner',
        brand: 'Daikin',
        serialNumber: 'DK894028392',
        warrantyStart: DateTime.now().subtract(const Duration(days: 365)),
        warrantyEnd: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
      );
      final service1 = Appliance(
        id: '${pfx}_srv_1',
        name: 'Indane Gas Cylinder',
        type: 'Gas Cylinder Refill',
        brand: 'IndianOil / Indane',
        serialNumber: 'Consumer #98420194',
        warrantyStart: DateTime.now().subtract(const Duration(days: 15)),
        warrantyEnd: DateTime.now().add(const Duration(days: 25)),
        createdAt: DateTime.now(),
      );
      await applianceProvider.addAppliance(appliance1);
      await applianceProvider.addAppliance(service1);

      // Seed a refill log for Gas Cylinder
      final gasLog = ServiceRecord(
        id: '${pfx}_srv_log_1',
        applianceId: service1.id,
        serviceDate: DateTime.now().subtract(const Duration(days: 15)),
        price: 850.0,
        remarks: '14.2kg Domestic LPG Refill cylinder delivered',
        createdAt: DateTime.now(),
      );
      await applianceProvider.addServiceRecord(gasLog);
    } catch (e) {
      debugPrint('Sample data seeding error (non-fatal): $e');
    }
  }

  void _showTourGuideDialog() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<EmployeeProvider>().refreshData(),
      context.read<ApplianceProvider>().loadAppliances(),
    ]);
    await _loadSession();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employeeProvider = context.watch<EmployeeProvider>();
    final applianceProvider = context.watch<ApplianceProvider>();

    final helpersCount = employeeProvider.employees.length;
    final workersCount = employeeProvider.ironingWorkers.length;
    final appliancesCount = applianceProvider.appliances.length;
    final attention = _buildAttentionItems(applianceProvider.appliances);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildGuestBanner(),
            _buildHeader(isDark),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    const AppSectionLabel('Manage'),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final cardWidth = (constraints.maxWidth - spacing) / 2;
                        final cardHeight = (cardWidth * 0.84).clamp(128.0, 190.0);

                        Widget tile(Widget child) => SizedBox(width: cardWidth, height: cardHeight, child: child);

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            tile(_buildModuleTile(
                              title: 'Helper Attendance',
                              countBadge: '$helpersCount ${helpersCount == 1 ? "helper" : "helpers"}',
                              accentColor: const Color(0xFF10B981),
                              vectorArt: const AttendanceVectorArt(size: 68),
                              isDark: isDark,
                              onTap: () => _navigateTo(const EmployeeManagementScreen()),
                            )),
                            tile(_buildModuleTile(
                              title: 'Ironing & Laundry',
                              countBadge: '$workersCount ${workersCount == 1 ? "worker" : "workers"}',
                              accentColor: const Color(0xFF6366F1),
                              vectorArt: const IroningVectorArt(size: 68),
                              isDark: isDark,
                              onTap: () => _navigateTo(const IroningDashboardScreen()),
                            )),
                            tile(_buildModuleTile(
                              title: 'Appliances & Services',
                              countBadge: '$appliancesCount ${appliancesCount == 1 ? "item" : "items"}',
                              accentColor: const Color(0xFF0D9488),
                              vectorArt: const ApplianceVectorArt(size: 68),
                              isDark: isDark,
                              onTap: () => _navigateTo(const MaintenanceScreen()),
                            )),
                            tile(_buildModuleTile(
                              title: 'Reports & Settings',
                              countBadge: 'Settings & tour',
                              accentColor: const Color(0xFFF59E0B),
                              vectorArt: const ReportsSettingsVectorArt(size: 68),
                              isDark: isDark,
                              onTap: () => _navigateTo(ThemeSettingsScreen(
                                onStartTour: _showTourGuideDialog,
                              )),
                            )),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    AppSectionLabel(
                      'Needs attention',
                      trailing: attention.isEmpty
                          ? null
                          : Text(
                              '${attention.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.subtitle(isDark),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    _buildAttentionCard(attention, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final statusColor = _isGuest ? AppColors.warning : AppColors.success;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Homelly',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        height: 1.2,
                        color: AppColors.title(isDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(isDark ? 50 : 30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isGuest ? 'Guest trial' : 'Active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isGuest
                              ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                              : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  '${_getGreeting()}, $_username',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _isRefreshing
              ? const SizedBox(
                  width: 38,
                  height: 38,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : AppHeaderAction(
                  icon: Icons.sync_rounded,
                  tooltip: 'Sync data',
                  onPressed: _handleManualSync,
                ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Profile',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _navigateTo(const UserProfileScreen()),
              child: _buildAvatarCircle(radius: 19),
            ),
          ),
        ],
      ),
    );
  }

  /// Payments due within a week (or overdue) and warranty or validity ending within 30 days,
  /// most urgent first.
  List<_AttentionItem> _buildAttentionItems(List<Appliance> appliances) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items = <_AttentionItem>[];

    for (final a in appliances) {
      final status = a.dueStatus;
      if (status == 'overdue' || status == 'due_today' || status == 'due_soon') {
        final days = a.daysUntilDue ?? 0;
        final amount = (a.dueAmount ?? 0) > 0 ? ' • ₹${a.dueAmount!.toStringAsFixed(0)}' : '';
        final String when;
        if (days < 0) {
          when = 'Payment overdue by ${-days} ${days == -1 ? "day" : "days"}';
        } else if (days == 0) {
          when = 'Payment due today';
        } else {
          when = 'Payment due in $days ${days == 1 ? "day" : "days"}';
        }
        items.add(_AttentionItem(
          title: a.name,
          detail: '$when$amount',
          days: days,
          icon: days < 0 ? Icons.error_outline_rounded : Icons.event_repeat_rounded,
          color: days < 0 ? AppColors.danger : (days == 0 ? AppColors.warning : AppColors.brand),
        ));
      }

      final end = a.warrantyEnd;
      if (end != null) {
        final days = DateTime(end.year, end.month, end.day).difference(today).inDays;
        if (days >= 0 && days <= 30) {
          items.add(_AttentionItem(
            title: a.name,
            detail: days == 0 ? 'Validity ends today' : 'Validity ends in $days ${days == 1 ? "day" : "days"}',
            days: days,
            icon: Icons.verified_user_outlined,
            color: days <= 7 ? AppColors.warning : AppColors.info,
          ));
        }
      }
    }

    items.sort((x, y) => x.days.compareTo(y.days));
    return items;
  }

  Widget _buildAttentionCard(List<_AttentionItem> items, bool isDark) {
    final decoration = BoxDecoration(
      color: AppColors.surface(isDark),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border(isDark)),
    );

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: decoration,
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All caught up. No payments or renewals are due soon.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle(isDark),
                ),
              ),
            ),
          ],
        ),
      );
    }

    const maxRows = 4;
    final shown = items.take(maxRows).toList();
    final extra = items.length - shown.length;

    return Container(
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0) Divider(height: 1, indent: 50, color: AppColors.border(isDark)),
              InkWell(
                onTap: () => _navigateTo(const MaintenanceScreen()),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: shown[i].color.withAlpha(isDark ? 40 : 24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(shown[i].icon, size: 16, color: shown[i].color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shown[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.title(isDark),
                              ),
                            ),
                            Text(
                              shown[i].detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.subtitle(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.subtitle(isDark)),
                    ],
                  ),
                ),
              ),
            ],
            if (extra > 0) ...[
              Divider(height: 1, color: AppColors.border(isDark)),
              InkWell(
                onTap: () => _navigateTo(const MaintenanceScreen()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Center(
                    child: Text(
                      'View $extra more',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required String title,
    required String countBadge,
    required Color accentColor,
    required Widget vectorArt,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(16);

    return Material(
      color: AppColors.surface(isDark),
      elevation: isDark ? 0 : 1.5,
      shadowColor: Colors.black.withAlpha(16),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withAlpha(30),
        highlightColor: accentColor.withAlpha(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: vectorArt,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: AppColors.title(isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                child: Text(
                  countBadge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.subtitle(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle({double radius = 17}) {
    final hasPic = _profilePic != null && _profilePic!.trim().isNotEmpty;
    final picUrl = hasPic
        ? (_profilePic!.startsWith('http')
            ? _profilePic!
            : 'https://slateblue-guanaco-751834.hostingersite.com/${_profilePic!.startsWith('/') ? _profilePic!.substring(1) : _profilePic!}')
        : null;

    final isGeneric = _username.isEmpty || _username == 'Guest User' || _username == 'User';
    final initial = !isGeneric ? _username[0].toUpperCase() : '';

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.brand.withAlpha(34),
      child: ClipOval(
        child: picUrl != null
            ? Image.network(
                picUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(radius, initial),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _buildFallbackAvatar(radius, initial);
                },
              )
            : _buildFallbackAvatar(radius, initial),
      ),
    );
  }

  Widget _buildFallbackAvatar(double radius, String initial) {
    if (initial.isNotEmpty) {
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.8,
          ),
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      color: AppColors.brand,
      size: radius * 1.15,
    );
  }
}

class _AttentionItem {
  final String title;
  final String detail;
  final int days;
  final IconData icon;
  final Color color;

  const _AttentionItem({
    required this.title,
    required this.detail,
    required this.days,
    required this.icon,
    required this.color,
  });
}
