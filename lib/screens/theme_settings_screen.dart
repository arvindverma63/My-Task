import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/theme_provider.dart';
import '../providers/employee_provider.dart';
import '../providers/appliance_provider.dart';
import '../utils/session_manager.dart';
import 'auth_screen.dart';

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

    if (uid != null) {
      try {
        final response = await http.get(
          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/get-profile'),
          headers: {'X-User-Id': uid},
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

  void _showEditProfileDialog() {
    final usernameController = TextEditingController(
      text: _username.contains('@') ? _username.split('@')[0] : _username,
    );
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;
    bool isUploading = false;
    String? dialogProfilePic = _profilePic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) {
          final hasPic = dialogProfilePic != null && dialogProfilePic!.isNotEmpty;
          final avatarUrl = hasPic
              ? (dialogProfilePic!.startsWith('http')
                  ? dialogProfilePic!
                  : 'https://slateblue-guanaco-751834.hostingersite.com/$dialogProfilePic')
              : null;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          ),
                          border: Border(
                            bottom: BorderSide(color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE)),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF4F46E5),
                              child: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Edit Profile & Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
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
                          children: [
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF4F46E5).withAlpha(100), width: 2.5),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: const Color(0xFF4F46E5).withAlpha(30),
                                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                                      child: isUploading
                                          ? const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4F46E5))
                                          : (avatarUrl == null
                                              ? const Icon(Icons.person_rounded, size: 44, color: Color(0xFF4F46E5))
                                              : null),
                                    ),
                                  ),
                                  if (!isUploading)
                                    GestureDetector(
                                      onTap: () async {
                                        final picker = ImagePicker();
                                        final pickedFile = await picker.pickImage(
                                          source: ImageSource.gallery,
                                          maxWidth: 512,
                                          maxHeight: 512,
                                          imageQuality: 80,
                                        );

                                        if (pickedFile != null) {
                                          setDlgState(() => isUploading = true);
                                          try {
                                            final request = http.MultipartRequest(
                                              'POST',
                                              Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/upload'),
                                            );
                                            request.headers['X-User-Id'] = _userId ?? '';
                                            request.files.add(
                                              await http.MultipartFile.fromPath(
                                                'file',
                                                pickedFile.path,
                                              ),
                                            );

                                            final streamedResponse = await request.send();
                                            final response = await http.Response.fromStream(streamedResponse);
                                            final data = json.decode(response.body);

                                            if (response.statusCode == 200 && data['success'] == true) {
                                              setDlgState(() {
                                                dialogProfilePic = data['path'];
                                              });
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(data['error'] ?? 'Image upload failed.'),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Network error uploading picture.'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          } finally {
                                            setDlgState(() => isUploading = false);
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4F46E5),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            _buildDialogInputField(
                              context: context,
                              controller: TextEditingController(
                                text: _username.contains('@') ? _username : 'linked-account@todo.com',
                              ),
                              label: 'Email Address (Linked Account)',
                              prefixIcon: Icons.email_rounded,
                              readOnly: true,
                            ),
                            const SizedBox(height: 12),
                            _buildDialogInputField(
                              context: context,
                              controller: usernameController,
                              label: 'Display Name / Username',
                              prefixIcon: Icons.badge_rounded,
                              hintText: 'e.g. Rahul Sharma',
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return 'Enter username';
                                if (value.trim().length < 3) return 'Must be at least 3 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildDialogInputField(
                              context: context,
                              controller: passwordController,
                              label: 'New Password (Optional)',
                              prefixIcon: Icons.lock_outline_rounded,
                              hintText: 'Leave empty to keep existing password',
                              obscureText: true,
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
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: (isSaving || isUploading)
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDlgState(() => isSaving = true);

                                      try {
                                        final response = await http.post(
                                          Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/update-profile'),
                                          headers: {
                                            'Content-Type': 'application/json',
                                            'X-User-Id': _userId ?? '',
                                          },
                                          body: json.encode({
                                            'username': usernameController.text.trim(),
                                            'password': passwordController.text.isNotEmpty ? passwordController.text : null,
                                            'profilePic': dialogProfilePic,
                                          }),
                                        );

                                        if (response.statusCode == 200) {
                                          final data = json.decode(response.body);
                                          if (data['success'] == true) {
                                            final session = SessionManager();
                                            await session.saveSession(
                                              userId: _userId ?? '',
                                              username: usernameController.text.trim(),
                                              userType: _userType,
                                              expiresAt: _userType == 'guest' ? (await session.getExpiresAt()) : null,
                                              profilePic: dialogProfilePic,
                                            );
                                            await _loadSessionDetails();
                                            if (context.mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Profile updated successfully!'),
                                                  backgroundColor: Color(0xFF059669),
                                                ),
                                              );
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(data['error'] ?? 'Profile update failed.'),
                                                  backgroundColor: Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Server response error (${response.statusCode})'),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e. Check your internet connection.'),
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
                                  : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            color: const Color(0xFF3B82F6).withAlpha(isDark ? 25 : 12),
                            border: Border.all(color: const Color(0xFF3B82F6).withAlpha(80), width: 1.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, color: Color(0xFF3B82F6), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'ANNUAL PASS',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6), letterSpacing: 0.8),
                                  ),
                                  Spacer(),
                                  Text(
                                    '₹299 / Year',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3B82F6)),
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
                                    final response = await http.post(
                                      Uri.parse('https://slateblue-guanaco-751834.hostingersite.com/api/update-subscription'),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'X-User-Id': _userId ?? '',
                                      },
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

    return Container(
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isGuest ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: isGuest
                      ? const Color(0xFF4F46E5).withAlpha(30)
                      : const Color(0xFFF59E0B).withAlpha(30),
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: isGuest ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                        )
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _showEditProfileDialog,
                child: Container(
                  padding: const EdgeInsets.all(4.5),
                  decoration: BoxDecoration(
                    color: isGuest ? const Color(0xFF4F46E5) : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                ),
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
                    fontSize: 15.5,
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
                            ? const Color(0xFF4F46E5).withAlpha(isDark ? 60 : 25)
                            : const Color(0xFFF59E0B).withAlpha(isDark ? 60 : 25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isGuest
                              ? const Color(0xFF4F46E5).withAlpha(isDark ? 100 : 70)
                              : const Color(0xFFF59E0B).withAlpha(isDark ? 100 : 70),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGuest ? Icons.timelapse_rounded : Icons.stars_rounded,
                            size: 11,
                            color: isGuest ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGuest ? 'Free Trial (${_guestDaysRemaining}d left)' : 'Lifetime Member',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isGuest
                                  ? (isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA))
                                  : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            onPressed: _showEditProfileDialog,
            tooltip: 'Account Settings',
          ),
        ],
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
                    subtitle: 'Sleek & Focused',
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
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFEEF2FF))
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
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
                    ? const Color(0xFF4F46E5)
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

  Widget _buildDialogInputField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hintText,
    bool readOnly = false,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 13.5,
        color: readOnly
            ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
            : (isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF4F46E5), size: 18),
        filled: true,
        fillColor: readOnly
            ? (isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: RefreshIndicator(
                  onRefresh: _loadSessionDetails,
                  color: const Color(0xFF4F46E5),
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
                                  ? const Color(0xFF4F46E5).withAlpha(30)
                                  : const Color(0xFFF59E0B).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _userType == 'guest' ? Icons.timelapse_rounded : Icons.stars_rounded,
                              color: _userType == 'guest' ? const Color(0xFF4F46E5) : const Color(0xFFD97706),
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

                      // 3. Backup & Restore
                      const _SectionLabel(title: 'Backup & Data Export', icon: Icons.cloud_sync_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: const Text('Export Backup File', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Save local JSON snapshot of your data', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.download_rounded, color: Color(0xFF10B981), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: () => _exportBackup(context),
                            ),
                            Divider(height: 1, indent: 52, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ListTile(
                              dense: true,
                              title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Restore registry data from file or JSON string', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.upload_rounded, color: Color(0xFF3B82F6), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: () => _showRestoreDialog(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 4. Tools & Diagnostics
                      const _SectionLabel(title: 'App Utilities & Tour', icon: Icons.tune_rounded),
                      const SizedBox(height: 8),
                      _SettingCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            ListTile(
                              dense: true,
                              title: const Text('Renew App (Fresh Seed)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
                              subtitle: Text('Reset state & seed sample household data', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: widget.onRenewApp,
                            ),
                            Divider(height: 1, indent: 52, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ListTile(
                              dense: true,
                              title: const Text('Start Guided Tour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('Interactive walkthrough of all modules', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                              leading: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_circle_filled_rounded, color: Color(0xFF8B5CF6), size: 18),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                              onTap: widget.onStartTour,
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
                              color: const Color(0xFFEF4444).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                          ),
                          onTap: () => _showLogoutConfirmation(context),
                        ),
                      ),
                      const SizedBox(height: 24),
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

  Future<void> _exportBackup(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final defaultFolderPath = directory.path;
      final defaultFilename = 'Registry_Backup_${DateTime.now().millisecondsSinceEpoch}.json';

      final folderController = TextEditingController(text: defaultFolderPath);
      final fileController = TextEditingController(text: defaultFilename);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
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
                              ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                              : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                        ),
                        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF10B981) : const Color(0xFFA7F3D0))),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF10B981),
                            child: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Export Data Backup',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : const Color(0xFF064E3B),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogInputField(
                            context: context,
                            controller: folderController,
                            label: 'Destination Folder',
                            prefixIcon: Icons.folder_open_rounded,
                          ),
                          const SizedBox(height: 12),
                          _buildDialogInputField(
                            context: context,
                            controller: fileController,
                            label: 'Backup Filename',
                            prefixIcon: Icons.insert_drive_file_rounded,
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
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () async {
                              final folderPath = folderController.text.trim();
                              final filename = fileController.text.trim();
                              if (folderPath.isEmpty || filename.isEmpty) return;

                              try {
                                final dir = Directory(folderPath);
                                if (!await dir.exists()) {
                                  await dir.create(recursive: true);
                                }

                                final prefs = await SharedPreferences.getInstance();
                                final keys = prefs.getKeys();
                                final Map<String, dynamic> backupData = {};

                                for (final key in keys) {
                                  final val = prefs.get(key);
                                  backupData[key] = val;
                                }

                                final jsonString = json.encode(backupData);
                                final file = File('${dir.path}/$filename');
                                await file.writeAsString(jsonString);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Backup exported successfully to ${file.path}'),
                                      backgroundColor: const Color(0xFF059669),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save file: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Export File', style: TextStyle(fontWeight: FontWeight.bold)),
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
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context) {
    final pathController = TextEditingController();
    final jsonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int activeTab = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) => DefaultTabController(
            length: 2,
            child: Dialog(
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
                                ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                          ),
                          border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE))),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF4F46E5),
                              child: const Icon(Icons.upload_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Restore from Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
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
                          children: [
                            TabBar(
                              onTap: (idx) => setDlgState(() => activeTab = idx),
                              labelColor: const Color(0xFF4F46E5),
                              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              indicatorColor: const Color(0xFF4F46E5),
                              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              tabs: const [
                                Tab(text: 'File Path'),
                                Tab(text: 'Paste JSON'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 160,
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDialogInputField(
                                              context: context,
                                              controller: pathController,
                                              label: 'Backup File Path',
                                              prefixIcon: Icons.folder_rounded,
                                              hintText: 'e.g. C:\\backup.json',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filled(
                                            style: IconButton.styleFrom(
                                              backgroundColor: const Color(0xFF4F46E5),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () async {
                                              try {
                                                final FilePickerResult? result = await FilePicker.pickFiles(
                                                  type: FileType.custom,
                                                  allowedExtensions: ['json'],
                                                );
                                                if (result != null && result.files.single.path != null) {
                                                  pathController.text = result.files.single.path!;
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Picker notice: $e')),
                                                  );
                                                }
                                              }
                                            },
                                            icon: const Icon(Icons.folder_open_rounded, color: Colors.white, size: 20),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  TextField(
                                    controller: jsonController,
                                    maxLines: null,
                                    expands: true,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    decoration: InputDecoration(
                                      hintText: 'Paste JSON text here...',
                                      filled: true,
                                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
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
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                String data = '';
                                if (activeTab == 0) {
                                  final path = pathController.text.trim();
                                  if (path.isEmpty) return;
                                  try {
                                    final file = File(path);
                                    if (!await file.exists()) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('File does not exist'), backgroundColor: Colors.red),
                                        );
                                      }
                                      return;
                                    }
                                    data = await file.readAsString();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error reading file: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                    return;
                                  }
                                } else {
                                  data = jsonController.text.trim();
                                }

                                if (data.isEmpty) return;

                                try {
                                  final Map<String, dynamic> parsed = json.decode(data);
                                  final prefs = await SharedPreferences.getInstance();

                                  for (final entry in parsed.entries) {
                                    if (entry.value is List) {
                                      final List<String> list = List<String>.from(entry.value);
                                      await prefs.setStringList(entry.key, list);
                                    } else if (entry.value is String) {
                                      await prefs.setString(entry.key, entry.value);
                                    } else if (entry.value is bool) {
                                      await prefs.setBool(entry.key, entry.value);
                                    } else if (entry.value is int) {
                                      await prefs.setInt(entry.key, entry.value);
                                    } else if (entry.value is double) {
                                      await prefs.setDouble(entry.key, entry.value);
                                    }
                                  }

                                  if (context.mounted) {
                                    final empProvider = context.read<EmployeeProvider>();
                                    final appProvider = context.read<ApplianceProvider>();
                                    final navigator = Navigator.of(context);
                                    final scaffoldMessenger = ScaffoldMessenger.of(context);

                                    navigator.pop();

                                    await empProvider.refreshData();
                                    await appProvider.loadAppliances();

                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Backup restored successfully!'),
                                        backgroundColor: Color(0xFF059669),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Invalid backup content: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                              child: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.bold)),
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
      },
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
        Icon(icon, size: 14, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA),
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
