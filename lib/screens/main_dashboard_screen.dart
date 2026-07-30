import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_management_screen.dart';
import 'ironing_dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'warranty_screen.dart';
import 'theme_settings_screen.dart';

import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../models/employee_model.dart';
import '../models/ironing_model.dart';
import '../models/appliance_model.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const EmployeeManagementScreen(),
      const IroningDashboardScreen(),
      const MaintenanceScreen(),
      const WarrantyScreen(),
      ThemeSettingsScreen(
        onStartTour: _showTourGuideDialog,
        onRenewApp: _showRenewVerificationStep1,
      ),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
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
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final applianceProvider = Provider.of<ApplianceProvider>(context, listen: false);

    // 1. Seed Employees
    final emp1 = Employee(
      id: 'demo_emp_1',
      name: 'Ramesh Kumar',
      contact: '9876543210',
      joiningDate: DateTime.now().subtract(const Duration(days: 45)),
      baseSalary: 450,
      salaryBasis: 'daily',
    );
    final emp2 = Employee(
      id: 'demo_emp_2',
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
    for (int i = 1; i <= 10; i++) {
      final date = now.subtract(Duration(days: i));
      final status = i % 5 == 0 ? AttendanceStatus.absent : (i % 6 == 0 ? AttendanceStatus.late : AttendanceStatus.present);
      final attendance = AttendanceEntry(
        id: 'demo_att_1_$i',
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

    // Seed attendance & payment for Sunita (monthly basis)
    for (int i = 1; i <= 15; i++) {
      final date = now.subtract(Duration(days: i));
      final status = i % 8 == 0 ? AttendanceStatus.absent : AttendanceStatus.present;
      final attendance = AttendanceEntry(
        id: 'demo_att_2_$i',
        employeeId: emp2.id,
        date: date,
        status: status,
        checkInTime: status != AttendanceStatus.absent ? '10:00 AM' : null,
        checkOutTime: status != AttendanceStatus.absent ? '07:00 PM' : null,
        amountGiven: i == 5 ? 2000 : 0,
        paymentDescription: i == 5 ? 'Salary Advance' : '',
      );
      await employeeProvider.markAttendance(attendance);
    }

    // 2. Seed Ironing Workers
    final worker1 = IroningWorker(
      id: 'demo_worker_1',
      name: 'Karan Singh',
      contact: '9988776655',
      joiningDate: DateTime.now().subtract(const Duration(days: 30)),
    );
    await employeeProvider.addIroningWorker(worker1);

    // Seed specific rates for Karan Singh
    await employeeProvider.saveIronRate(worker1.id, IronRate(id: 'shirt_rate', clothingType: 'Shirt', rate: 6.0, date: DateTime.now()));
    await employeeProvider.saveIronRate(worker1.id, IronRate(id: 'pant_rate', clothingType: 'Pant', rate: 7.0, date: DateTime.now()));
    await employeeProvider.saveIronRate(worker1.id, IronRate(id: 'saree_rate', clothingType: 'Saree', rate: 12.0, date: DateTime.now()));

    // Seed ironing records
    final record1 = IroningRecord(
      id: 'demo_rec_1',
      workerId: worker1.id,
      date: now.subtract(const Duration(days: 3)),
      clothesCount: {'Shirt': 15, 'Pant': 10, 'Saree': 2},
      totalWage: (15 * 6.0) + (10 * 7.0) + (2 * 12.0),
      createdAt: DateTime.now(),
    );
    final record2 = IroningRecord(
      id: 'demo_rec_2',
      workerId: worker1.id,
      date: now.subtract(const Duration(days: 1)),
      clothesCount: {'Shirt': 20, 'Pant': 15},
      totalWage: (20 * 6.0) + (15 * 7.0),
      createdAt: DateTime.now(),
    );
    await employeeProvider.saveIroningRecord(worker1.id, record1);
    await employeeProvider.saveIroningRecord(worker1.id, record2);

    // Seed ironing payments
    final pay1 = IroningPayment(
      id: 'demo_pay_1',
      workerId: worker1.id,
      date: now.subtract(const Duration(days: 2)),
      amount: 150.0,
      description: 'Part payment',
      createdAt: DateTime.now(),
    );
    await employeeProvider.saveIroningPayment(worker1.id, pay1);

    // 3. Seed Appliances
    final appliance1 = Appliance(
      id: 'demo_app_1',
      name: 'Daikin AC 1.5 Ton',
      type: 'Air Conditioner',
      brand: 'Daikin',
      serialNumber: 'DK894028392',
      warrantyStart: DateTime.now().subtract(const Duration(days: 365)),
      warrantyEnd: DateTime.now().add(const Duration(days: 365)),
      createdAt: DateTime.now(),
    );
    final appliance2 = Appliance(
      id: 'demo_app_2',
      name: 'Samsung Fridge',
      type: 'Refrigerator',
      brand: 'Samsung',
      serialNumber: 'REF-SAM-29381',
      warrantyStart: DateTime.now().subtract(const Duration(days: 730)),
      warrantyEnd: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now(),
    );
    await applianceProvider.addAppliance(appliance1);
    await applianceProvider.addAppliance(appliance2);

    // Seed service record
    final service = ServiceRecord(
      id: 'demo_srv_1',
      applianceId: appliance1.id,
      serviceDate: DateTime.now().subtract(const Duration(days: 90)),
      price: 1500.0,
      remarks: 'Gas refilling and cleaning',
      createdAt: DateTime.now(),
    );
    await applianceProvider.addServiceRecord(service);
  }

  void _showTourGuideDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    int currentStep = 0;

    final List<Map<String, dynamic>> steps = [
      {
        'title': 'Welcome to My-Task! 👋',
        'desc': 'This app is a simple diary to help you keep track of your daily house helpers, ironing records, and home appliance repairs.\n\nWe have added some example entries for you, so you can see how it works right away!',
        'icon': Icons.home_work_rounded,
        'tabIndex': 0,
      },
      {
        'title': 'Helper Attendance 📅',
        'desc': 'Under this tab, you can mark when your maid or helper comes to work. You can check them in, note if they are late or absent, and record any cash advances or salary given.',
        'icon': Icons.people_alt_rounded,
        'tabIndex': 0,
      },
      {
        'title': 'Ironing Wages 👕',
        'desc': 'Keep track of your ironing helper\'s clothes. Type in how many shirts, pants, or sarees you gave them. The app automatically calculates how much money you owe based on the price per cloth.',
        'icon': Icons.iron_rounded,
        'tabIndex': 1,
      },
      {
        'title': 'Appliance Repairs 🛠️',
        'desc': 'Keep a log of your home appliances (like AC, TV, or Fridge). Write down when they were repaired, what work was done, and how much it cost.',
        'icon': Icons.build_rounded,
        'tabIndex': 2,
      },
      {
        'title': 'Warranties & Receipts 🛡️',
        'desc': 'Track when the warranty period is ending for your appliances. Safe-keep serial numbers and purchase details in one place.',
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(stepIcon, size: 46, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      stepTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      stepDesc,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Step ${currentStep + 1} of ${steps.length}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        steps.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentStep == index ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: currentStep == index ? colorScheme.primary : colorScheme.outlineVariant.withAlpha(150),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            setState(() => _currentIndex = 0);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Skip Tour',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            currentStep == steps.length - 1 ? 'Finish Tour 🏁' : 'Next Step ➡️',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    )
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
            const SizedBox(width: 12),
            const Text('Renew App? (Step 1/2)'),
          ],
        ),
        content: const Text(
          'This will permanently delete all your existing domestic helpers, ironing logs, payments, and appliance data. The app will restart with a fresh set of sample data and the guided tour.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // Close Step 1 Dialog
              _showRenewVerificationStep2(); // Open Step 2 Dialog
            },
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: const Text('Proceed to Step 2'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.lock_person_rounded, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              const Text('Verify Reset (Step 2/2)'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is irreversible. To proceed, please type the word "RENEW" in the input field below:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: verifyController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Verification Word',
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
                      Navigator.pop(context); // Close dialog
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

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        height: 68,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.people_alt_rounded,
              color: _currentIndex == 0 ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(160),
            ),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.iron_rounded,
              color: _currentIndex == 1 ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(160),
            ),
            label: 'Ironing',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.build_rounded,
              color: _currentIndex == 2 ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(160),
            ),
            label: 'Servicing',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.security_rounded,
              color: _currentIndex == 3 ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(160),
            ),
            label: 'Warranties',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_rounded,
              color: _currentIndex == 4 ? colorScheme.primary : colorScheme.onSurfaceVariant.withAlpha(160),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
