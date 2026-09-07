import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/main_dashboard_screen.dart';
import 'utils/session_manager.dart';
import 'package:flutter/services.dart';

import 'providers/employee_provider.dart';
import 'repositories/api_employee_repository.dart';
import 'providers/appliance_provider.dart';
import 'repositories/api_appliance_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF0F172A),
      visualDensity: VisualDensity.compact,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: brightness == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: brightness == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        selectedColor: colorScheme.primaryContainer,
        side: BorderSide(
          color: brightness == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? Colors.white : const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: brightness == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: brightness == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface.withAlpha(230),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.all(8),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider(ApiEmployeeRepository())),
        ChangeNotifierProvider(create: (_) => ApplianceProvider(ApiApplianceRepository())),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'My Task',
            debugShowCheckedModeBanner: false,
            navigatorKey: SessionManager.navigatorKey,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeProvider.themeMode,
            home: const SessionWrapper(),
          );
        },
      ),
    );
  }
}

class SessionWrapper extends StatelessWidget {
  const SessionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SessionManager().getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        final userId = snapshot.data;
        if (userId == null) {
          return const AuthScreen();
        }

        // Check if guest account is expired
        return FutureBuilder<bool>(
          future: SessionManager().isExpired(),
          builder: (context, expirySnapshot) {
            if (expirySnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isExpired = expirySnapshot.data ?? false;
            if (isExpired) {
              // Clear session and return AuthScreen with warning
              return FutureBuilder<void>(
                future: SessionManager().clearSession(),
                builder: (context, clearSnapshot) {
                  return const AuthScreen(
                    expirationMessage: 'Your 30-day guest period has expired. Please register to convert your account and save your logs.',
                  );
                },
              );
            }

            return const MainDashboardScreen();
          },
        );
      },
    );
  }
}
