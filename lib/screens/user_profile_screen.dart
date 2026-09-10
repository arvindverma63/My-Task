import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../utils/session_manager.dart';
import 'auth_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String _username = '';
  String _userType = 'guest';
  int _guestDaysRemaining = 30;
  String? _userId;
  String? _profilePic;
  bool _isLoading = false;
  bool _isUploadingPic = false;
  bool _copiedId = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final session = SessionManager();
    final uid = await session.getUserId();
    final uname = await session.getUsername();
    final utype = await session.getUserType();
    final days = await session.getDaysRemaining();
    final pic = await session.getProfilePic();

    if (mounted) {
      setState(() {
        _userId = uid;
        _username = uname ?? 'Household Admin';
        _userType = utype ?? 'guest';
        _guestDaysRemaining = days;
        _profilePic = pic;
      });
    }

    if (uid != null && uid.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/get-profile?userId=$uid'),
          headers: {'X-User-Id': uid, 'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            await session.saveSession(
              userId: uid,
              username: data['username'] ?? _username,
              userType: data['userType'] ?? _userType,
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
        // Fallback to local session
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() => _isUploadingPic = true);
    try {
      final uid = _userId ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/upload?userId=$uid'),
      );
      if (uid.isNotEmpty) {
        request.headers['X-User-Id'] = uid;
        request.fields['userId'] = uid;
      }
      request.files.add(await http.MultipartFile.fromPath('file', picked.path));

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final data = json.decode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final newPicPath = data['path'];
        // Update profile with new pic
        final updateRes = await http.post(
          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/update-profile?userId=$uid'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-User-Id': uid,
          },
          body: json.encode({
            'userId': uid,
            'username': _username,
            'profilePic': newPicPath,
          }),
        );

        final updateData = json.decode(updateRes.body);
        if (updateRes.statusCode == 200 && updateData['success'] == true) {
          final session = SessionManager();
          await session.saveSession(
            userId: _userId ?? '',
            username: _username,
            userType: _userType,
            profilePic: newPicPath,
          );

          if (mounted) {
            setState(() => _profilePic = newPicPath);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Profile photo updated successfully!'),
                  ],
                ),
                backgroundColor: Color(0xFF0D9488),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? 'Failed to upload photo'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPic = false);
    }
  }

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(
      text: _username.contains('@') ? _username.split('@')[0] : _username,
    );
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool obscurePassword = true;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dialog Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF134E4A), const Color(0xFF0F766E)]
                                : [const Color(0xFFF0FDFA), const Color(0xFFCCFBF1)],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark ? const Color(0xFF115E59) : const Color(0xFF99F6E4),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488).withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0D9488), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Profile Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Update your display name and credentials',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : Colors.black.withAlpha(15),
                                padding: const EdgeInsets.all(6),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: usernameController,
                              style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                prefixIcon: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF0D9488)),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Change Password (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Leave empty to keep unchanged',
                                prefixIcon: const Icon(Icons.lock_rounded, size: 18, color: Color(0xFF0D9488)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 18,
                                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                  ),
                                  onPressed: () => setDlgState(() => obscurePassword = !obscurePassword),
                                ),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Password should be at least 6 characters long if changing.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0D9488),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDlgState(() => isSaving = true);
                                      try {
                                        final newName = usernameController.text.trim();
                                        final newPass = passwordController.text.trim();

                                        final uid = _userId ?? '';
                                        final response = await http.post(
                                          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/update-profile?userId=$uid'),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'Accept': 'application/json',
                                            'X-User-Id': uid,
                                          },
                                          body: json.encode({
                                            'userId': uid,
                                            'username': newName,
                                            if (newPass.isNotEmpty) 'password': newPass,
                                            'profilePic': _profilePic,
                                          }),
                                        );

                                        final data = json.decode(response.body);
                                        if (response.statusCode == 200 && data['success'] == true) {
                                          final session = SessionManager();
                                          await session.saveSession(
                                            userId: _userId ?? '',
                                            username: newName,
                                            userType: _userType,
                                            profilePic: _profilePic,
                                          );

                                          if (mounted) {
                                            setState(() => _username = newName);
                                          }
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('Profile updated successfully!'),
                                                  ],
                                                ),
                                                backgroundColor: Color(0xFF0D9488),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(data['error'] ?? 'Profile update failed.'),
                                                backgroundColor: const Color(0xFFEF4444),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Network error: $e'),
                                              backgroundColor: const Color(0xFFEF4444),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } finally {
                                        setDlgState(() => isSaving = false);
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSubscriptionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // VIP Banner Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB45309), Color(0xFFD97706), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VIP Executive Plan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Unlimited power for your household',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.white24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildFeatureItem(isDark, Icons.group_rounded, 'Unlimited Staff & Helpers', 'Add and manage without limit'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(isDark, Icons.inventory_2_rounded, 'Full Appliance Registry', 'Keep records of all warranties & services'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(isDark, Icons.dry_cleaning_rounded, 'Ironing & Laundry Ledger', 'Track dhobi counts and daily totals'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(isDark, Icons.cloud_sync_rounded, 'Encrypted Cloud Backup', 'Automatic real-time sync across devices'),
                    const SizedBox(height: 12),
                    _buildFeatureItem(isDark, Icons.file_download_rounded, 'PDF & CSV Exporting', 'Download and share comprehensive reports'),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(isDark ? 30 : 20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD97706).withAlpha(80)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _userType == 'guest'
                                  ? 'Your trial has $_guestDaysRemaining days remaining.'
                                  : 'Your account is permanently activated as VIP.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Got It / Close', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(bool isDark, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0D9488).withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D9488), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? Your credentials on this device will be cleared.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final session = SessionManager();
              await session.clearSession();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empProvider = context.watch<EmployeeProvider>();
    final appProvider = context.watch<ApplianceProvider>();

    final totalStaff = empProvider.employees.length;
    final totalAppliances = appProvider.appliances.length;
    final isGuest = _userType == 'guest';

    final hasPic = _profilePic != null && _profilePic!.isNotEmpty;
    final avatarUrl = hasPic
        ? (_profilePic!.startsWith('http')
            ? _profilePic!
            : 'https://slateblue-guanaco-751834.hostingersite.com/$_profilePic')
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'User Profile & Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh Profile',
            onPressed: _loadProfile,
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 20),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            tooltip: 'Sign Out',
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: const Color(0xFF0D9488),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Executive Hero Profile Card
                    _buildProfileHeroCard(isDark, isGuest, avatarUrl),
                    const SizedBox(height: 16),

                    // 2. Household Overview Stats
                    _buildQuickStatsCard(isDark, totalStaff, totalAppliances),
                    const SizedBox(height: 16),

                    // 3. Account Information & ID
                    _buildAccountInfoCard(isDark, isGuest),
                    const SizedBox(height: 16),

                    // 4. Cloud & Security Status Card
                    _buildSecurityAndSyncCard(isDark),
                    const SizedBox(height: 16),

                    // 5. Quick Action Hub
                    _buildQuickActionsCard(isDark),
                    const SizedBox(height: 20),

                    // 6. Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0D9488),
                              side: BorderSide(color: isDark ? const Color(0xFF14B8A6) : const Color(0xFF0D9488)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _showEditProfileDialog,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _showLogoutDialog,
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

  Widget _buildProfileHeroCard(bool isDark, bool isGuest, String? avatarUrl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF134E4A), const Color(0xFF0F766E), const Color(0xFF1E293B)]
              : [const Color(0xFF0F766E), const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withAlpha(isDark ? 70 : 45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Avatar with Camera Badge
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white.withAlpha(40),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: _isUploadingPic
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      : (avatarUrl == null
                          ? const Icon(Icons.person_rounded, size: 50, color: Colors.white)
                          : null),
                ),
              ),
              InkWell(
                onTap: _isUploadingPic ? null : _pickAndUploadPhoto,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _username.isNotEmpty ? _username : 'Household Manager',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Membership & Trial Badge
          InkWell(
            onTap: _showSubscriptionDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isGuest
                    ? const Color(0xFFD97706).withAlpha(220)
                    : const Color(0xFF10B981).withAlpha(220),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(140), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGuest ? Icons.timelapse_rounded : Icons.verified_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isGuest ? 'Free Trial • $_guestDaysRemaining Days Left' : 'VIP Executive Member',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white70),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(bool isDark, int staffCount, int applianceCount) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              isDark: isDark,
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF0D9488),
              label: 'Staff & Helpers',
              value: '$staffCount Active',
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _buildStatItem(
              isDark: isDark,
              icon: Icons.handyman_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'Appliances',
              value: '$applianceCount Items',
            ),
          ),
          Container(
            height: 38,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _buildStatItem(
              isDark: isDark,
              icon: Icons.cloud_done_rounded,
              iconColor: const Color(0xFFD97706),
              label: 'Cloud Sync',
              value: 'Active',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard(bool isDark, bool isGuest) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded, size: 16, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                'ACCOUNT INFORMATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            title: 'Display Name',
            value: _username.isNotEmpty ? _username : 'Household Manager',
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0D9488)),
              tooltip: 'Edit Name',
              onPressed: _showEditProfileDialog,
            ),
          ),
          Divider(height: 22, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildInfoRow(
            isDark: isDark,
            icon: Icons.card_membership_rounded,
            title: 'Account Tier',
            value: isGuest ? 'Guest Trial Mode ($guestDaysRemainingLeft)' : 'Cloud VIP Member',
            trailing: InkWell(
              onTap: _showSubscriptionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Details',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 22, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildInfoRow(
            isDark: isDark,
            icon: Icons.fingerprint_rounded,
            title: 'Unique User ID',
            value: _userId != null
                ? '${_userId!.substring(0, _userId!.length > 12 ? 12 : _userId!.length)}...'
                : 'Local Device',
            trailing: IconButton(
              icon: Icon(
                _copiedId ? Icons.check_circle_rounded : Icons.copy_rounded,
                size: 16,
                color: _copiedId ? const Color(0xFF10B981) : (isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              tooltip: 'Copy User ID',
              onPressed: () {
                if (_userId != null) {
                  Clipboard.setData(ClipboardData(text: _userId!));
                  setState(() => _copiedId = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('User ID copied to clipboard!'),
                        ],
                      ),
                      backgroundColor: Color(0xFF0D9488),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _copiedId = false);
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String get guestDaysRemainingLeft => '$_guestDaysRemaining days';

  Widget _buildSecurityAndSyncCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'CLOUD BACKEND & SECURITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cloud Sync: Connected & Verified',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All employee registers, daily wages, ironing items, and appliance maintenance logs are synchronized with your dedicated cloud account.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF0D9488), size: 18),
            ),
            title: Text(
              'Subscription & Plan Benefits',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: _showSubscriptionDialog,
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF10B981), size: 18),
            ),
            title: Text(
              'Change Account Password',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: _showEditProfileDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
