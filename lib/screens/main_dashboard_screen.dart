import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_management_screen.dart';
import 'ironing_dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'theme_settings_screen.dart';

import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../models/appliance_model.dart';
import '../utils/session_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  bool _isGuest = false;
  int _guestDaysRemaining = 30;
  String? _userId;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _screens = [
      const EmployeeManagementScreen(),
      const IroningDashboardScreen(),
      const MaintenanceScreen(),
      ThemeSettingsScreen(
        onStartTour: _showTourGuideDialog,
        onRenewApp: _showRenewVerificationStep1,
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _loadSession() async {
    final session = SessionManager();
    final type = await session.getUserType();
    final days = await session.getDaysRemaining();
    final uid = await session.getUserId();
    setState(() {
      _isGuest = type == 'guest';
      _guestDaysRemaining = days;
      _userId = uid;
    });
  }

  Widget _buildGuestBanner() {
    if (!_isGuest) return const SizedBox.shrink();
    
    return Container(
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Guest Mode: $_guestDaysRemaining days left',
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
      if (mounted) {
        _showTourGuideDialog();
      }
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

      // Seed attendance & payment for Ramesh (daily basis)
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
    final colorScheme = Theme.of(context).colorScheme;
    int currentStep = 0;

    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Welcome to My-Task! 👋',
        'desc': 'This app is a simple diary to help you keep track of your daily house helpers, ironing records, gas cylinder refills, and appliance repairs.\n\nWe have added some example entries for you, so you can see how it works right away!',
        'icon': Icons.home_work_rounded,
        'tabIndex': 0,
      },
      {
        'title': 'Helper Attendance 📅',
        'desc': 'Under this tab, helpers are present by default. Tap the 1-tap Absent button if someone is on leave, and record cash advances or salary with on-screen reports.',
        'icon': Icons.people_alt_rounded,
        'tabIndex': 0,
      },
      {
        'title': 'Ironing Wages 👕',
        'desc': 'Keep track of your ironing helper\'s clothes by sizes (Small, Medium, Large, XL). The app automatically calculates wages and balance payments.',
        'icon': Icons.iron_rounded,
        'tabIndex': 1,
      },
      {
        'title': 'Services & Appliances 🛠️',
        'desc': 'Track gas cylinder refills, drinking water cans, Wi-Fi utilities, and home appliances (AC, TV, Fridge) with warranties, refill logs, and receipts.',
        'icon': Icons.propane_tank_rounded,
        'tabIndex': 2,
      },
      {
        'title': 'Warranties & Receipts 🛡️',
        'desc': 'Track when the warranty or renewal cycle is ending. Safe-keep consumer numbers, serial IDs, and bills in one place.',
        'icon': Icons.security_rounded,
        'tabIndex': 3,
      },
      {
        'title': 'All Set! 🎉',
        'desc': 'You are now ready to use the app! You can easily edit or delete the example data and replace it with your own helper names.\n\nTap the button below to start.',
        'icon': Icons.check_circle_outline_rounded,
        'tabIndex': 0,
      },
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          final step = steps[currentStep];
          final stepIcon = step['icon'] as IconData;
          final stepTitle = step['title'] as String;
          final stepDesc = step['desc'] as String;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(stepIcon, size: 28, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      stepTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.1),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stepDesc,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Step ${currentStep + 1} of ${steps.length}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        steps.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentStep == index ? 14 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: currentStep == index ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(150),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            setState(() => _currentIndex = 0);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Skip Tour',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (currentStep < steps.length - 1) {
                              setDlgState(() {
                                currentStep++;
                              });
                              setState(() {
                                _currentIndex = steps[currentStep]['tabIndex'] as int;
                              });
                            } else {
                              setState(() => _currentIndex = 0);
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            currentStep == steps.length - 1 ? 'Finish 🏁' : 'Next ➡️',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
              const SizedBox(width: 8),
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
    
    // 3. Mark first launch completed in prefs but show the tour guide dialog
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch_v2', false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('App renewed successfully! Sample data has been re-seeded.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _currentIndex = 0;
      });
      _showTourGuideDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildGuestBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildProfessionalBottomNav(colorScheme, isDark),
    );
  }

  Widget _buildProfessionalBottomNav(ColorScheme colorScheme, bool isDark) {
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark ? Colors.white.withAlpha(18) : Colors.black.withAlpha(12);

    final navItems = [
      const _NavItemData(
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt_rounded,
        label: 'Attendance',
      ),
      const _NavItemData(
        icon: Icons.iron_outlined,
        selectedIcon: Icons.iron_rounded,
        label: 'Ironing',
      ),
      const _NavItemData(
        icon: Icons.devices_other_outlined,
        selectedIcon: Icons.devices_other_rounded,
        label: 'Services & Assets',
      ),
      _NavItemData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Settings',
        badgeDot: _isGuest,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 8),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: colorScheme.primary.withAlpha(20),
                    highlightColor: Colors.transparent,
                    onTap: () {
                      if (_currentIndex != index) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentIndex = index);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Subtle top indicator bar
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          height: 2.5,
                          width: isSelected ? 22 : 0,
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                          ),
                        ),
                        // Icon capsule with micro-scale & optional badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSelected ? 12 : 6,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary.withAlpha(isDark ? 45 : 22)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AnimatedScale(
                                scale: isSelected ? 1.06 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 20.5,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                            if (item.badgeDot)
                              Positioned(
                                top: 1,
                                right: isSelected ? 8 : 2,
                                child: Container(
                                  width: 6.5,
                                  height: 6.5,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: bg,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Label text with animated style
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                              letterSpacing: isSelected ? -0.2 : 0,
                            ),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool badgeDot;

  const _NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeDot = false,
  });
}
