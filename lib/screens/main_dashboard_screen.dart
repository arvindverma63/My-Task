import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_management_screen.dart';
import 'ironing_dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'theme_settings_screen.dart';
import 'employee_report_screen.dart';
import 'user_profile_screen.dart';
import 'onboarding_screen.dart';

import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../models/appliance_model.dart';
import '../utils/session_manager.dart';
import '../widgets/vector_illustrations.dart';
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
          onRenewApp: _showRenewVerificationStep1,
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
  }

  void _navigateTo(Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadSession());
  }

  Widget _buildGuestBanner() {
    if (!_isGuest) return const SizedBox.shrink();

    return Container(
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Guest Mode: $_guestDaysRemaining days left on trial',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              onPressed: _showUpgradeAccountDialog,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.orange.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeAccountDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          title: const Row(
            children: [
              Icon(Icons.upgrade_rounded, color: Colors.orange, size: 22),
              SizedBox(width: 8),
              Text('Convert to Member', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Upgrade your account to save helper, ironing, and appliance logs permanently in the cloud.',
                    style: TextStyle(fontSize: 12, height: 1.3),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter username';
                      }
                      if (value.trim().length < 4) {
                        return 'Username must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlgState(() => isSaving = true);

                      try {
                        final response = await http.post(
                          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/convert-guest'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'userId': _userId,
                            'username': usernameController.text.trim(),
                            'password': passwordController.text,
                          }),
                        );

                        final data = json.decode(response.body);

                        if (response.statusCode == 200 && data['success'] == true) {
                          await SessionManager().saveSession(
                            userId: data['userId'],
                            username: data['username'],
                            userType: data['userType'],
                            expiresAt: data['expiresAt'],
                          );
                          await _loadSession();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account upgraded successfully! Welcome aboard.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(data['error'] ?? 'Conversion failed.'),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Upgrade'),
            ),
          ],
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
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_small_rate', clothingType: 'Small Clothes', rate: 4.0, date: DateTime.now()));
      await employeeProvider.saveIronRate(worker1.id, IronRate(id: '${pfx}_large_rate', clothingType: 'Large Clothes', rate: 7.0, date: DateTime.now()));

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

  void _showRenewVerificationStep1() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Reset & Renew App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will permanently delete all your domestic helpers, ironing logs, payments, and appliance data, and reload the fresh sample data.',
          style: TextStyle(fontSize: 12.5, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showRenewVerificationStep2();
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showRenewVerificationStep2() {
    final colorScheme = Theme.of(context).colorScheme;
    final verifyController = TextEditingController();
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          title: Row(
            children: [
              Icon(Icons.lock_person_rounded, color: colorScheme.primary, size: 22),
              SizedBox(width: 8),
              const Text('Verify Reset', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type "RENEW" to confirm reset:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: verifyController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Type RENEW',
                  hintText: 'RENEW',
                ),
                onChanged: (val) {
                  setDlgState(() {
                    isButtonEnabled = val.trim().toUpperCase() == 'RENEW';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isButtonEnabled
                  ? () async {
                      Navigator.pop(context);
                      await _renewAppAndShowTour();
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: isButtonEnabled ? colorScheme.error : Colors.grey,
              ),
              child: const Text('Confirm Renewal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renewAppAndShowTour() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final applianceProvider = Provider.of<ApplianceProvider>(context, listen: false);

    // 1. Clear all data
    await employeeProvider.clearAllData();
    final appliances = List<Appliance>.from(applianceProvider.appliances);
    for (final app in appliances) {
      await applianceProvider.deleteAppliance(app.id);
    }

    // 2. Re-seed sample data
    await _seedSampleData();

    // 3. Mark first launch completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch_v2', false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App renewed successfully! Sample data has been re-seeded.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final employeeProvider = context.watch<EmployeeProvider>();
    final applianceProvider = context.watch<ApplianceProvider>();

    final helpersCount = employeeProvider.employees.length;
    final workersCount = employeeProvider.ironingWorkers.length;
    final appliancesCount = applianceProvider.appliances.length;

    // Active warranties count
    final now = DateTime.now();
    final activeWarranties = applianceProvider.appliances.where((a) {
      return a.warrantyEnd != null && a.warrantyEnd!.isAfter(now);
    }).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildGuestBanner(),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF10B981),
              onRefresh: () async {
                await Future.wait([
                  context.read<EmployeeProvider>().refreshData(),
                  context.read<ApplianceProvider>().loadAppliances(),
                ]);
                await _loadSession();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. Executive Top Bar Header
                  SliverToBoxAdapter(
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            // App Logo Badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withAlpha(80),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'My-Task',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: _isGuest
                                              ? Colors.amber.withAlpha(isDark ? 40 : 25)
                                              : const Color(0xFF10B981).withAlpha(isDark ? 40 : 25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _isGuest ? Colors.amber.shade700 : const Color(0xFF10B981),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          _isGuest ? 'Guest Trial' : 'Active',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: _isGuest
                                                ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900)
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Household Management Hub',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // User Profile Avatar Shortcut
                            GestureDetector(
                              onTap: () => _navigateTo(const UserProfileScreen()),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF10B981).withAlpha(120),
                                    width: 1.8,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFF10B981).withAlpha(30),
                                  backgroundImage: _profilePic != null && _profilePic!.isNotEmpty
                                      ? NetworkImage(_profilePic!)
                                      : null,
                                  child: _profilePic == null || _profilePic!.isEmpty
                                      ? Text(
                                          _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Welcome Greeting & Quick Metrics Banner
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 30 : 6),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Namaste, $_username 👋',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Select a module',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Summary Pill Metrics Bar
                            Row(
                              children: [
                                _buildSummaryMetric(
                                  icon: Icons.people_alt_rounded,
                                  value: '$helpersCount',
                                  label: 'Helpers',
                                  color: const Color(0xFF10B981),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildSummaryMetric(
                                  icon: Icons.iron_rounded,
                                  value: '$workersCount',
                                  label: 'Dhobis',
                                  color: const Color(0xFF6366F1),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildSummaryMetric(
                                  icon: Icons.propane_tank_rounded,
                                  value: '$appliancesCount',
                                  label: 'Assets',
                                  color: const Color(0xFF0D9488),
                                  isDark: isDark,
                                ),
                                const SizedBox(width: 6),
                                _buildSummaryMetric(
                                  icon: Icons.security_rounded,
                                  value: '$activeWarranties',
                                  label: 'Active',
                                  color: const Color(0xFFF59E0B),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Section Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.dashboard_customize_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'MAIN MODULES (मुख्य विकल्प)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 4. The 4 Main Redirection Cards
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Option 1: Attendance Register
                        _buildMainOptionCard(
                          title: 'Helper Attendance & Salary',
                          hindiTitle: 'कामवाली / हेल्पर अटेंडेंस व पगार',
                          subtitle: '1-tap Present / Absent tracking, advance payouts, and automatic monthly wage calculations.',
                          badgeText: '$helpersCount Helpers Active',
                          accentColor: const Color(0xFF10B981),
                          gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                          icon: Icons.people_alt_rounded,
                          vectorArt: const AttendanceVectorArt(size: 78),
                          isDark: isDark,
                          onTap: () => _navigateTo(const EmployeeManagementScreen()),
                        ),
                        const SizedBox(height: 12),

                        // Option 2: Ironing & Dhobi Tracker
                        _buildMainOptionCard(
                          title: 'Ironing & Dhobi Registry',
                          hindiTitle: 'धोबी / इस्त्री का हिसाब व रेट कार्ड',
                          subtitle: 'Batch garment counter by size (S, M, L, XL), customizable rate cards, and vendor balance ledger.',
                          badgeText: workersCount > 0 ? '$workersCount Dhobis Active' : 'Add First Worker',
                          accentColor: const Color(0xFF6366F1),
                          gradient: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                          icon: Icons.iron_rounded,
                          vectorArt: const IroningVectorArt(size: 78),
                          isDark: isDark,
                          onTap: () => _navigateTo(const IroningDashboardScreen()),
                        ),
                        const SizedBox(height: 12),

                        // Option 3: Services & Appliances Hub
                        _buildMainOptionCard(
                          title: 'Appliances & Home Services',
                          hindiTitle: 'घरेलू उपकरण, गैस सिलिंडर व सर्विस',
                          subtitle: 'LPG cylinder refills, drinking water delivery, AC service, warranties & invoice records.',
                          badgeText: '$appliancesCount Items • $activeWarranties Active',
                          accentColor: const Color(0xFF0D9488),
                          gradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                          icon: Icons.propane_tank_rounded,
                          vectorArt: const ApplianceVectorArt(size: 78),
                          isDark: isDark,
                          onTap: () => _navigateTo(const MaintenanceScreen()),
                        ),
                        const SizedBox(height: 12),

                        // Option 4: Reports, Backup & Settings
                        _buildMainOptionCard(
                          title: 'PDF Reports & App Settings',
                          hindiTitle: 'रिपोर्ट्स, बैकअप व सेटिंग्स',
                          subtitle: 'Download monthly attendance salary slips, manage cloud backup, profile, and dark mode.',
                          badgeText: 'Reports & Sync',
                          accentColor: const Color(0xFFF59E0B),
                          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          icon: Icons.settings_rounded,
                          vectorArt: const ReportsSettingsVectorArt(size: 78),
                          isDark: isDark,
                          onTap: () => _navigateTo(ThemeSettingsScreen(
                            onStartTour: _showTourGuideDialog,
                            onRenewApp: _showRenewVerificationStep1,
                          )),
                        ),
                        const SizedBox(height: 18),

                        // Quick Action Shortcuts Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'QUICK SHORTCUTS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickButton(
                                      icon: Icons.analytics_rounded,
                                      label: 'Full Report',
                                      color: const Color(0xFF10B981),
                                      isDark: isDark,
                                      onTap: () => _navigateTo(const EmployeeReportScreen()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickButton(
                                      icon: Icons.explore_rounded,
                                      label: 'Guided Tour',
                                      color: const Color(0xFF6366F1),
                                      isDark: isDark,
                                      onTap: _showTourGuideDialog,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickButton(
                                      icon: Icons.person_rounded,
                                      label: 'Profile',
                                      color: const Color(0xFF0D9488),
                                      isDark: isDark,
                                      onTap: () => _navigateTo(const UserProfileScreen()),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 28 : 16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(45), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOptionCard({
    required String title,
    required String hindiTitle,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
    required List<Color> gradient,
    required IconData icon,
    required Widget vectorArt,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withAlpha(25),
        highlightColor: accentColor.withAlpha(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withAlpha(isDark ? 20 : 12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vector Art Visual Thumbnail
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDark ? 30 : 18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentColor.withAlpha(50)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: vectorArt,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Card Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(isDark ? 40 : 20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              hindiTitle,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // Subtitle
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Action Arrow Link
                    Row(
                      children: [
                        Text(
                          'Open Module',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(isDark ? 25 : 15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withAlpha(45), width: 0.8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
