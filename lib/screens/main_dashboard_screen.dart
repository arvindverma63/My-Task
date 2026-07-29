import 'package:flutter/material.dart';
import 'employee_management_screen.dart';
import 'ironing_dashboard_screen.dart';
import 'maintenance_screen.dart';
import 'warranty_screen.dart';
import 'theme_settings_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EmployeeManagementScreen(),
    const IroningDashboardScreen(),
    const MaintenanceScreen(),
    const WarrantyScreen(),
    const ThemeSettingsScreen(),
  ];

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
