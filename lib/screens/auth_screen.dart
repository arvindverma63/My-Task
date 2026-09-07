import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/session_manager.dart';
import 'main_dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthScreen extends StatefulWidget {
  final String? expirationMessage;
  const AuthScreen({super.key, this.expirationMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bgAnimationController;
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgAnimationController.dispose();
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
        _showErrorSnackBar(data['error'] ?? 'Login failed. Please check credentials.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Check internet connection.');
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Logging in...')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(data['error'] ?? 'Registration failed.');
      }
    } catch (e) {
      _showErrorSnackBar('Network error. Check internet connection.');
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
        _showErrorSnackBar(data['error'] ?? 'Failed to enter guest mode.');
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
        _showErrorSnackBar(data['error'] ?? 'Google Sign-In backend verification failed.');
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _showErrorSnackBar('Google Sign-In requires SHA-1 configuration on Google Console: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withAlpha(160),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10),
      prefixIcon: Icon(prefixIcon, color: colorScheme.primary.withAlpha(180), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(12),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: colorScheme.primary.withAlpha(160),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.redAccent.withAlpha(100),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Moving Mesh Gradient Background Glows
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              final val = _bgAnimationController.value;
              return Stack(
                children: [
                  Positioned(
                    top: -120 + (val * 40),
                    left: -120 + (val * 30),
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withAlpha((35 + val * 15).round()),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60 - (val * 30),
                    right: -120 - (val * 40),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF06B6D4).withAlpha((25 + val * 15).round()),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Blur filter for background elements
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: const SizedBox.shrink(),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          // Brand Logo emblem with soft glow scale transition
                          Center(
                            child: AnimatedBuilder(
                              animation: _bgAnimationController,
                              builder: (context, child) {
                                final val = _bgAnimationController.value;
                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.primary.withAlpha((40 + val * 20).round()),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withAlpha((20 + val * 15).round()),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.devices_other_rounded,
                                    size: 40,
                                    color: colorScheme.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Sleek Gradient Title Text
                          Center(
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              ).createShader(bounds),
                              child: Text(
                                'My Task Hub',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Track helpers, ironing logs & appliance repairs',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant.withAlpha(200),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          if (widget.expirationMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(25),
                                border: Border.all(color: Colors.orange.withAlpha(76)),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.expirationMessage!,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // 3. Premium Glassmorphic Form Card with Shadows
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(150),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(isDark ? 80 : 20),
                                      blurRadius: 40,
                                      spreadRadius: 4,
                                    )
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isLoading) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            minHeight: 3,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                      // Custom sliding toggle capsule tab bar
                                      Container(
                                        height: 50,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.black38 : Colors.black.withAlpha(12),
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: TabBar(
                                          controller: _tabController,
                                          indicator: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: BorderRadius.circular(99),
                                            boxShadow: [
                                              BoxShadow(
                                                color: colorScheme.primary.withAlpha(120),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          labelColor: Colors.white,
                                          unselectedLabelColor: colorScheme.onSurfaceVariant.withAlpha(180),
                                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          dividerColor: Colors.transparent,
                                          tabs: const [
                                            Tab(text: 'Sign In'),
                                            Tab(text: 'Sign Up'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 28),
                                      SizedBox(
                                        height: 280, // slightly taller for elegant inputs spacing
                                        child: TabBarView(
                                          controller: _tabController,
                                          children: [
                                            _buildLoginForm(colorScheme, isDark),
                                            _buildRegisterForm(colorScheme, isDark),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: 24),

                          // 4. Third party options (Google & Guest)
                          if (!_isLoading) ...[
                            Row(
                              children: [
                                Expanded(child: Divider(color: colorScheme.onSurfaceVariant.withAlpha(40))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant.withAlpha(120),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: colorScheme.onSurfaceVariant.withAlpha(40))),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Google Login Button
                            ElevatedButton(
                              onPressed: _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                foregroundColor: colorScheme.onSurface,
                                elevation: 2,
                                shadowColor: Colors.black12,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GoogleLogoIcon(size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sign in with Google',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Guest Login Button
                            OutlinedButton(
                              onPressed: _handleGuestMode,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(
                                  color: colorScheme.primary.withAlpha(102),
                                  width: 1.2,
                                ),
                                backgroundColor: isDark ? Colors.white.withAlpha(3) : Colors.black.withAlpha(3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_outline_rounded, color: colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continue as Guest',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                '30 days guest limit. Conversions supported later.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withAlpha(140),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else
                            const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(ColorScheme colorScheme, bool isDark) {
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
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
              colorScheme: colorScheme,
              isDark: isDark,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withAlpha(200)],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(ColorScheme colorScheme, bool isDark) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _regUsernameController,
            decoration: _buildInputDecoration(
              label: 'Username',
              prefixIcon: Icons.person_outline_rounded,
              colorScheme: colorScheme,
              isDark: isDark,
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
            controller: _regPasswordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'Password',
              prefixIcon: Icons.lock_outline_rounded,
              colorScheme: colorScheme,
              isDark: isDark,
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
          const SizedBox(height: 12),
          TextFormField(
            controller: _regConfirmPasswordController,
            obscureText: _obscurePassword,
            decoration: _buildInputDecoration(
              label: 'Confirm Password',
              prefixIcon: Icons.lock_clock_outlined,
              colorScheme: colorScheme,
              isDark: isDark,
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
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primary.withAlpha(200)],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(80),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
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

    // Draw Google Arch segments
    // Red segment: top
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -2.4, // start angle
      1.2,  // sweep angle
      false,
      paint,
    );

    // Yellow segment: left-bottom
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -3.6,
      1.2,
      false,
      paint,
    );

    // Green segment: bottom
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -4.8,
      1.4,
      false,
      paint,
    );

    // Blue segment: right-top and crossbar
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -1.2,
      1.2,
      false,
      paint,
    );

    // Crossbar
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
