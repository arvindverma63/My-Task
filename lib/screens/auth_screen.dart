import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';
import 'main_dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../widgets/app_logo.dart';

class AuthScreen extends StatefulWidget {
  final String? expirationMessage;
  const AuthScreen({super.key, this.expirationMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  static const String _apiUrl = 'https://slateblue-guanaco-751834.hostingersite.com/api';

  // Red & White Theme Constants
  static const Color _crimsonPrimary = Color(0xFFDC2626);
  static const Color _crimsonDark = Color(0xFFB91C1C);
  static const Color _crimsonLight = Color(0xFFFEE2E2);
  static const Color _crimsonSubtle = Color(0xFFFEF2F2);
  static const Color _slateBg = Color(0xFFF8FAFC);
  static const Color _slateText = Color(0xFF0F172A);
  static const Color _slateMuted = Color(0xFF64748B);
  static const Color _slateBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await SessionManager().saveSession(
          userId: data['userId'],
          username: data['username'],
          userType: data['userType'],
          expiresAt: data['expiresAt'],
          profilePic: data['profilePic'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['error'] ?? 'Invalid username or password.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please verify your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _regUsernameController.text.trim(),
          'password': _regPasswordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await SessionManager().saveSession(
          userId: data['userId'],
          username: data['username'],
          userType: data['userType'],
          expiresAt: data['expiresAt'],
          profilePic: data['profilePic'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['error'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Please verify your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestMode() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/register-guest'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await SessionManager().saveSession(
          userId: data['userId'],
          username: data['username'],
          userType: data['userType'],
          expiresAt: data['expiresAt'],
          profilePic: data['profilePic'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['error'] ?? 'Failed to initialize guest mode.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Check internet connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? '1000343378364-8q2jn8a47ek2mtf711kctclj84rc1005.apps.googleusercontent.com'
            : null,
        serverClientId: '1000343378364-8q2jn8a47ek2mtf711kctclj84rc1005.apps.googleusercontent.com',
        scopes: ['email'],
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.post(
        Uri.parse('$_apiUrl/login-google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'googleId': account.id,
          'email': account.email,
          'displayName': account.displayName ?? '',
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await SessionManager().saveSession(
          userId: data['userId'],
          username: data['username'],
          userType: data['userType'],
          expiresAt: data['expiresAt'],
          profilePic: data['profilePic'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['error'] ?? 'Google Sign-In verification failed.');
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('10') || errStr.contains('12500') || errStr.contains('sign_in_failed') || errStr.contains('ApiException')) {
          _showGoogleSignInHelpDialog(errStr);
        } else {
          _showErrorSnackBar('Google Sign-In error: $e');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showGoogleSignInHelpDialog(String errorDetail) {
    const String sha1Fingerprint = 'B7:A0:04:32:84:10:E0:96:A3:3F:89:25:58:B7:8B:C9:46:B7:AC:F9';
    const String packageName = 'com.todo.todo';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _crimsonSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.security_rounded, color: _crimsonPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Google Sign-In Setup',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _slateText,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On Android, Google Play Services requires registering your app’s SHA-1 fingerprint in the Google Cloud / Firebase Console under your OAuth Client.',
                style: TextStyle(fontSize: 13, color: _slateMuted, height: 1.4),
              ),
              const SizedBox(height: 14),
              
              // Package Name Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _slateBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PACKAGE NAME',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _slateMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            packageName,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _slateText, fontFamily: 'monospace'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: _crimsonPrimary),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: packageName));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Package name copied!'), duration: Duration(seconds: 2)),
                            );
                          },
                          tooltip: 'Copy Package Name',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // SHA-1 Fingerprint Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _slateBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEBUG SHA-1 CERTIFICATE FINGERPRINT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _slateMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            sha1Fingerprint,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _slateText, fontFamily: 'monospace'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: _crimsonPrimary),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: sha1Fingerprint));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SHA-1 fingerprint copied!'), duration: Duration(seconds: 2)),
                            );
                          },
                          tooltip: 'Copy SHA-1',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Tip: You can also Sign Up / Sign In directly with a Username & Password or use Guest Mode without any setup.',
                style: TextStyle(fontSize: 12, color: _crimsonDark, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700, color: _crimsonPrimary)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: _crimsonPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _slateMuted,
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(prefixIcon, color: _crimsonPrimary.withAlpha(200), size: 19),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _slateBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _slateBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _crimsonPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _crimsonPrimary.withAlpha(150)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _crimsonPrimary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _slateBg,
      body: Stack(
        children: [
          // Subtle Red Ambient Lighting Top
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _crimsonPrimary.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _crimsonPrimary.withAlpha(10),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
              child: const SizedBox.shrink(),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Logo Header
                      const Center(
                        child: AppLogo(
                          size: 76,
                          showText: true,
                          subtitle: 'Household Staff, Ironing & Appliance Management',
                          heroTag: 'app_auth_logo',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Expiration / Deleted User Warning Banner
                      if (widget.expirationMessage != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _crimsonSubtle,
                            border: Border.all(color: _crimsonPrimary.withAlpha(80)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: _crimsonPrimary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.expirationMessage!,
                                  style: const TextStyle(
                                    color: _crimsonDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // White Form Container Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _slateBorder),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLoading) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: _crimsonLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(_crimsonPrimary),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Red & White Capsule Tab Bar
                            Container(
                              height: 42,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _slateBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _slateBorder),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: _crimsonPrimary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _crimsonPrimary.withAlpha(60),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: _slateMuted,
                                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Roboto'),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              height: 240,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildLoginForm(),
                                  _buildRegisterForm(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Third-Party Options
                      if (!_isLoading) ...[
                        Row(
                          children: [
                            const Expanded(child: Divider(color: _slateBorder)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  color: _slateMuted.withAlpha(160),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: _slateBorder)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Sign In
                        ElevatedButton(
                          onPressed: _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _slateText,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: _slateBorder),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GoogleLogoIcon(size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Sign in with Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Guest Mode (30-Day Trial)
                        OutlinedButton(
                          onPressed: _handleGuestMode,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(color: _crimsonPrimary, width: 1.2),
                            backgroundColor: _crimsonSubtle,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_outline_rounded, color: _crimsonPrimary, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Continue as Guest (30-Day Free Trial)',
                                style: TextStyle(
                                  color: _crimsonPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Guest accounts can convert to lifetime premium anytime.',
                            style: TextStyle(
                              color: _slateMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showForgotPasswordDialog() async {
    final forgotUsernameController = TextEditingController(text: _usernameController.text.trim());
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool isAccountVerified = false;
    String? verifiedUserId;
    String? verifiedUsername;
    bool isSubmitting = false;
    bool obscureNewPass = true;
    String? dialogError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _crimsonSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, color: _crimsonPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAccountVerified ? 'Create New Password' : 'Reset Password',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: _slateText,
                          ),
                        ),
                        Text(
                          isAccountVerified ? 'Step 2 of 2: Set new credentials' : 'Step 1 of 2: Find your account',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: _slateMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        if (dialogError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: _crimsonSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _crimsonPrimary.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: _crimsonPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogError!,
                                    style: const TextStyle(fontSize: 12, color: _crimsonDark, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (!isAccountVerified) ...[
                          const Text(
                            'Enter your registered username to verify your account.',
                            style: TextStyle(fontSize: 12.5, color: _slateMuted, height: 1.35),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: forgotUsernameController,
                            autofocus: true,
                            decoration: _buildInputDecoration(
                              label: 'Username',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter username' : null,
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Account verified: @$verifiedUsername',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextFormField(
                            controller: newPasswordController,
                            obscureText: obscureNewPass,
                            autofocus: true,
                            decoration: _buildInputDecoration(
                              label: 'New Password',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 19,
                                  color: _slateMuted,
                                ),
                                onPressed: () {
                                  setDialogState(() => obscureNewPass = !obscureNewPass);
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter new password';
                              if (v.length < 4) return 'Password must be at least 4 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureNewPass,
                            decoration: _buildInputDecoration(
                              label: 'Confirm New Password',
                              prefixIcon: Icons.lock_reset_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm password';
                              if (v != newPasswordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: _slateMuted, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            if (!isAccountVerified) {
                              final res = await http.post(
                                Uri.parse('$_apiUrl/forgot-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({'username': forgotUsernameController.text.trim()}),
                              );
                              final data = json.decode(res.body);
                              if (res.statusCode == 200 && data['success'] == true) {
                                setDialogState(() {
                                  isAccountVerified = true;
                                  verifiedUserId = data['userId'];
                                  verifiedUsername = data['username'];
                                  isSubmitting = false;
                                });
                              } else {
                                setDialogState(() {
                                  dialogError = data['error'] ?? 'User account not found.';
                                  isSubmitting = false;
                                });
                              }
                            } else {
                              final res = await http.post(
                                Uri.parse('$_apiUrl/reset-password'),
                                headers: {'Content-Type': 'application/json'},
                                body: json.encode({
                                  'username': verifiedUsername,
                                  'userId': verifiedUserId,
                                  'newPassword': newPasswordController.text,
                                }),
                              );
                              final data = json.decode(res.body);
                              if (res.statusCode == 200 && data['success'] == true) {
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                _usernameController.text = verifiedUsername ?? '';
                                _passwordController.text = newPasswordController.text;
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset successfully! You can now Sign In.'),
                                      backgroundColor: Color(0xFF16A34A),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } else {
                                setDialogState(() {
                                  dialogError = data['error'] ?? 'Failed to reset password.';
                                  isSubmitting = false;
                                });
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              dialogError = 'Connection error: $e';
                              isSubmitting = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _crimsonPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text(
                          isAccountVerified ? 'Reset Password' : 'Verify Account',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: _buildInputDecoration(
              label: 'Username',
              prefixIcon: Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: _slateMuted,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _showForgotPasswordDialog,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: _crimsonPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _crimsonPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Sign In',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regUsernameController,
            decoration: _buildInputDecoration(
              label: 'New Username',
              prefixIcon: Icons.person_add_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter username';
              }
              if (value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regPasswordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'New Password',
              prefixIcon: Icons.lock_outline_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 4) {
                return 'Password must be at least 4 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _regConfirmPasswordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'Confirm Password',
              prefixIcon: Icons.lock_reset_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm password';
              }
              if (value != _regPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: _crimsonPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}

class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -2.4,
      1.2,
      false,
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -3.6,
      1.2,
      false,
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -4.8,
      1.4,
      false,
      paint,
    );

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -1.2,
      1.2,
      false,
      paint,
    );

    final Paint fillPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.45, h * 0.2),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
