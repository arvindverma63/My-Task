import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/theme_provider.dart';
import '../utils/session_manager.dart';
import 'auth_screen.dart';
import 'user_profile_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  final VoidCallback? onStartTour;
  final VoidCallback? onRenewApp;
  const ThemeSettingsScreen({super.key, this.onStartTour, this.onRenewApp});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _username = '';
  String _userType = 'guest';
  int _guestDaysRemaining = 30;
  String? _userId;
  String? _profilePic;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadSessionDetails();
  }

  Future<void> _loadSessionDetails() async {
    setState(() => _isLoadingProfile = true);
    final session = SessionManager();
    final uid = await session.getUserId();
    final uname = await session.getUsername();
    final utype = await session.getUserType();
    final days = await session.getDaysRemaining();
    final pic = await session.getProfilePic();
    setState(() {
      _userId = uid;
      _username = uname ?? 'Guest User';
      _userType = utype ?? 'guest';
      _guestDaysRemaining = days;
      _profilePic = pic;
    });

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
              username: data['username'],
              userType: data['userType'],
              expiresAt: data['expiresAt'],
              profilePic: data['profilePic'],
            );
            final freshDays = await session.getDaysRemaining();
            if (mounted) {
              setState(() {
                _username = data['username'] ?? _username;
                _userType = data['userType'] ?? _userType;
                _profilePic = data['profilePic'] ?? _profilePic;
                _guestDaysRemaining = freshDays;
              });
            }
          }
        }
      } catch (e) {
        // Fallback gracefully on network timeout
      } finally {
        if (mounted) setState(() => _isLoadingProfile = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
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
                                      final session = SessionManager();
                                      await session.saveSession(
                                        userId: _userId ?? '',
                                        username: _username,
                                        userType: 'registered',
                                        expiresAt: null,
                                      );
                                      await _loadSessionDetails();
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('🎉 Congratulations! You are now a Lifetime Member!'),
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

  Widget _buildUserProfileHeader(bool isDark) {
    final hasImage = _profilePic != null && _profilePic!.isNotEmpty;
    final imageUrl = hasImage
        ? (_profilePic!.startsWith('http')
            ? _profilePic!
            : 'https://slateblue-guanaco-751834.hostingersite.com/$_profilePic')
        : null;

    final isGuest = _userType == 'guest';

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
        _loadSessionDetails();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGuest ? const Color(0xFF0D9488) : const Color(0xFFF59E0B),
                      width: 2.2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: isGuest
                        ? const Color(0xFF0D9488).withAlpha(25)
                        : const Color(0xFFF59E0B).withAlpha(25),
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: isGuest ? const Color(0xFF0D9488) : const Color(0xFFF59E0B),
                          )
                        : null,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isGuest ? const Color(0xFF0D9488) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.verified_user_rounded, size: 10, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username.isNotEmpty ? _username : 'Household Manager',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGuest
                              ? const Color(0xFF0D9488).withAlpha(isDark ? 50 : 20)
                              : const Color(0xFFF59E0B).withAlpha(isDark ? 50 : 20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isGuest
                                ? const Color(0xFF0D9488).withAlpha(isDark ? 100 : 60)
                                : const Color(0xFFF59E0B).withAlpha(isDark ? 100 : 60),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGuest ? Icons.timelapse_rounded : Icons.stars_rounded,
                              size: 11,
                              color: isGuest ? const Color(0xFF0D9488) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isGuest ? 'Trial (${_guestDaysRemaining}d left)' : 'Lifetime VIP',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isGuest
                                    ? const Color(0xFF0D9488)
                                    : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userId != null && _userId!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '#ID-${_userId!.length > 6 ? _userId!.substring(0, 6) : _userId}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF0D9488), size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(ThemeProvider settings, bool isDark) {
    return _SettingCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildThemeModeCard(
                    title: 'Light Mode',
                    subtitle: 'Clean & Crisp',
                    icon: Icons.light_mode_rounded,
                    isSelected: settings.themeMode == ThemeMode.light,
                    isDark: isDark,
                    onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.light),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildThemeModeCard(
                    title: 'Dark Mode',
                    subtitle: 'Sleek Midnight',
                    icon: Icons.dark_mode_rounded,
                    isSelected: settings.themeMode == ThemeMode.dark,
                    isDark: isDark,
                    onTap: () => context.read<ThemeProvider>().setThemeMode(ThemeMode.dark),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0x280D9488) : const Color(0xFFF0FDFA))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D9488)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0D9488)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeProvider>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings & Account',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_isLoadingProfile)
            const ClipRRect(
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: _loadSessionDetails,
                  color: const Color(0xFF0D9488),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 20 + bottomInset),
                    children: [
                      _buildUserProfileHeader(isDark),

                      // 1. Subscription & Plan
                      const _SectionLabel(title: 'Plan & Cloud Access', icon: Icons.workspace_premium_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: Text(
                            _userType == 'guest' ? '30-Day Guest Trial' : 'Premium Lifetime Active',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          subtitle: Text(
                            _userType == 'guest'
                                ? '$_guestDaysRemaining days remaining on free trial'
                                : 'Continuous cloud backup and synchronization',
                            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _userType == 'guest'
                                  ? const Color(0xFF0D9488).withAlpha(25)
                                  : const Color(0xFFF59E0B).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _userType == 'guest' ? Icons.timelapse_rounded : Icons.stars_rounded,
                              color: _userType == 'guest' ? const Color(0xFF0D9488) : const Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          trailing: _userType == 'guest'
                              ? Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    onTap: _showSubscriptionDialog,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFD97706), Color(0xFFB45309)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD97706).withAlpha(60),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1.5),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'Upgrade',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(isDark ? 50 : 25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
                                  ),
                                  child: const Text(
                                    'Active',
                                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10.5),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Appearance
                      const _SectionLabel(title: 'Appearance Mode', icon: Icons.palette_rounded),
                      const SizedBox(height: 8),
                      _buildThemeSelector(settings, isDark),
                      const SizedBox(height: 16),

                      // 3. Display & Layout Preferences
                      const _SectionLabel(title: 'Preferences & Regional', icon: Icons.tune_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: const Text('Currency Symbol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Current currency: ${settings.currency.symbol} (${settings.currency.label})', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF0D9488), size: 18),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  settings.currency.symbol,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D9488)),
                                ),
                              ),
                            ),
                            Divider(height: 1, indent: 52, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            SwitchListTile(
                              dense: true,
                              title: const Text('Compact Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Denser padding for lists and registers', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              secondary: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.density_medium_rounded, color: Color(0xFF0284C7), size: 18),
                              ),
                              value: settings.compactMode,
                              activeThumbColor: const Color(0xFF0D9488),
                              activeTrackColor: const Color(0xFF0D9488).withAlpha(100),
                              onChanged: (val) => settings.setCompactMode(val),
                            ),
                            Divider(height: 1, indent: 52, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            SwitchListTile(
                              dense: true,
                              title: const Text('Show Timestamps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Display exact time on activity logs', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              secondary: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 18),
                              ),
                              value: settings.showTimestamps,
                              activeThumbColor: const Color(0xFF0D9488),
                              activeTrackColor: const Color(0xFF0D9488).withAlpha(100),
                              onChanged: (val) => settings.setShowTimestamps(val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Tools & Walkthrough
                      const _SectionLabel(title: 'App Utilities & Tour', icon: Icons.explore_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: const Text('Start Guided Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Interactive walkthrough of all household modules', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF0D9488), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: widget.onStartTour,
                            ),
                            Divider(height: 1, indent: 52, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ListTile(
                              dense: true,
                              title: const Text('Renew App (Fresh Seed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                              subtitle: Text('Reload fresh sample household data', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD97706).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh_rounded, color: Color(0xFFD97706), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: widget.onRenewApp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Account & Session
                      const _SectionLabel(title: 'Session Management', icon: Icons.account_circle_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: ListTile(
                          dense: true,
                          title: const Text('Log Out', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('Sign out of your active device session', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          leading: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                          ),
                          onTap: () => _showLogoutConfirmation(context),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. About & Build Tag
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'My Task • v2.5.0 Professional Edition',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Cloud Connected & Synchronized',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
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

  void _showLogoutConfirmation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                'Log Out Session?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'You will need to sign in again to access cloud synchronization.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await SessionManager().clearSession();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionLabel({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF0D9488)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 5),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: child,
    );
  }
}
