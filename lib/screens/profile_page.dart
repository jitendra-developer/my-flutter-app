import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';

import 'package:myapp/services/api_service.dart';
import 'package:myapp/utils.dart';

// ─── SharedPreferences keys ──────────────────────────────────────────────────
const _kProfileName      = 'profile_name';
const _kProfileEmail     = 'profile_email';
const _kProfileAvatarUrl = 'profile_avatar_url';

// ─── Helpers (used by ProfilePage + sidebar in chat_page.dart) ───────────────

String profileInitials(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  final p = t.split(' ');
  return p.length >= 2
      ? '${p.first[0]}${p.last[0]}'.toUpperCase()
      : t[0].toUpperCase();
}

Future<void> saveProfileCache(
    String name, String email, String? avatarUrl) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kProfileName, name);
  await prefs.setString(_kProfileEmail, email);
  if (avatarUrl != null && avatarUrl.isNotEmpty) {
    await prefs.setString(_kProfileAvatarUrl, avatarUrl);
  } else {
    await prefs.remove(_kProfileAvatarUrl);
  }
}

Future<Map<String, String?>> loadProfileCache() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'name':      prefs.getString(_kProfileName),
    'email':     prefs.getString(_kProfileEmail),
    'avatarUrl': prefs.getString(_kProfileAvatarUrl),
  };
}

// ─── Shared avatar widget ─────────────────────────────────────────────────────

class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final File? localFile;
  final double radius;
  final double fontSize;

  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.localFile,
    required this.radius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? bg;
    if (localFile != null) {
      bg = FileImage(localFile!);
    } else if (avatarUrl != null &&
        avatarUrl!.isNotEmpty &&
        !avatarUrl!.startsWith('data:')) {
      bg = NetworkImage(avatarUrl!);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF4A60D4),
      backgroundImage: bg,
      child: bg == null
          ? Text(
              profileInitials(name),
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

// ─── Profile Page ─────────────────────────────────────────────────────────────

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();

  // Profile fields
  String _name       = '';
  String _email      = '';
  String? _avatarUrl;              // URL from API / cache
  File?   _pickedFile;             // locally picked image (not yet saved)
  bool _isLoadingProfile = true;
  bool _isSavingProfile  = false;

  late TextEditingController _nameCtrl;

  // Password fields
  final TextEditingController _currentPwCtrl  = TextEditingController();
  final TextEditingController _newPwCtrl      = TextEditingController();
  final TextEditingController _confirmPwCtrl  = TextEditingController();
  bool _showCurrentPw  = false;
  bool _showNewPw      = false;
  bool _showConfirmPw  = false;
  bool _isSavingPw     = false;
  bool _isSendingOtp   = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _initProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  // ── Load profile: cache first → API refresh ────────────────────────────────

  Future<void> _initProfile() async {
    // Show cache instantly
    final cached = await loadProfileCache();
    if (mounted && (cached['name'] ?? '').isNotEmpty) {
      setState(() {
        _name      = cached['name']!;
        _email     = cached['email'] ?? '';
        _avatarUrl = cached['avatarUrl'];
        _nameCtrl.text = _name;
        _isLoadingProfile = false;
      });
    }

    // Refresh silently from API
    try {
      final profile  = await _apiService.getProfile();
      final name     = profile['name']?.toString()  ?? _name;
      final email    = profile['email']?.toString() ?? _email;
      // avatar field can be a URL (Google photo, or uploaded URL from backend)
      final avatar   = profile['avatar']?.toString() ??
                       profile['profile_photo_url']?.toString() ??
                       profile['photo']?.toString();

      await saveProfileCache(name, email, avatar);

      if (mounted) {
        setState(() {
          _name      = name;
          _email     = email;
          _avatarUrl = avatar;
          _nameCtrl.text = name;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      developer.log('Profile API refresh failed', error: e);
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  // ── Pick image from gallery ────────────────────────────────────────────────

  Future<void> _pickImage() async {
    var status = await Permission.photos.status;
    if (status.isPermanentlyDenied) {
      openAppSettings();
      return;
    }
    if (!status.isGranted) {
      status = await Permission.photos.request();
      if (!status.isGranted) return;
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked != null && mounted) {
      setState(() => _pickedFile = File(picked.path));
    }
  }

  // ── Save profile (name + optional photo) ──────────────────────────────────

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showFeedback(context, 'Name cannot be empty', isError: true);
      return;
    }
    setState(() => _isSavingProfile = true);
    try {
      String? base64Avatar;
      if (_pickedFile != null) {
        final bytes = await _pickedFile!.readAsBytes();
        base64Avatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      final result = await _apiService.updateProfile(
          name, avatar: base64Avatar);

      // Backend may return the stored avatar URL after processing
      final updatedAvatar = result['avatar']?.toString() ??
          result['profile_photo_url']?.toString() ??
          (base64Avatar ?? _avatarUrl);
      final updatedEmail = result['email']?.toString() ?? _email;

      await saveProfileCache(name, updatedEmail, updatedAvatar);

      if (mounted) {
        setState(() {
          _name      = name;
          _email     = updatedEmail;
          _avatarUrl = updatedAvatar;
          _pickedFile = null; // clear local pick — now committed
        });
        showFeedback(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        showFeedback(context,
            e.toString().replaceAll('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  // ── Change password ────────────────────────────────────────────────────────

  Future<void> _changePassword() async {
    final current = _currentPwCtrl.text.trim();
    final newPw   = _newPwCtrl.text.trim();
    final confirm = _confirmPwCtrl.text.trim();

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      showFeedback(context, 'Please fill all password fields', isError: true);
      return;
    }
    if (newPw.length < 8) {
      showFeedback(context, 'New password must be at least 8 characters',
          isError: true);
      return;
    }
    if (newPw != confirm) {
      showFeedback(context, 'New passwords do not match', isError: true);
      return;
    }

    setState(() => _isSavingPw = true);
    try {
      await _apiService.changePassword(
        currentPassword: current,
        newPassword: newPw,
        newPasswordConfirmation: confirm,
      );
      if (mounted) {
        _currentPwCtrl.clear();
        _newPwCtrl.clear();
        _confirmPwCtrl.clear();
        showFeedback(context, 'Password changed successfully');
      }
    } catch (e) {
      if (mounted) {
        showFeedback(context,
            e.toString().replaceAll('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSavingPw = false);
    }
  }

  // ── Forgot password → send OTP then go to reset screen ────────────────────

  Future<void> _forgotPassword() async {
    if (_email.isEmpty) {
      showFeedback(context, 'No email on file', isError: true);
      return;
    }
    setState(() => _isSendingOtp = true);
    try {
      await _apiService.forgotPasswordOtp(_email);
      if (mounted) {
        showFeedback(context, 'OTP sent to $_email');
        context.push('/reset-password', extra: _email);
      }
    } catch (e) {
      if (mounted) {
        showFeedback(context,
            e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A60D4)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: _pickedFile != null ? null : _pickImage,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatar(
                            name: _name,
                            avatarUrl: _avatarUrl,
                            localFile: _pickedFile,
                            radius: 54,
                            fontSize: 34,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A60D4),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF13131A),
                                      width: 2),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name display (updates as user types)
                  Center(
                    child: Text(
                      (_nameCtrl.text.trim().isEmpty
                              ? _name
                              : _nameCtrl.text.trim())
                          .toUpperCase(),
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      _email,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Profile section ──────────────────────────────────────
                  _sectionLabel('Profile'),
                  const SizedBox(height: 10),

                  // Name field
                  _buildField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),

                  // Email (read-only)
                  _buildField(
                    controller: TextEditingController(text: _email),
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                    suffixIcon: const Icon(Icons.lock_outline,
                        color: Colors.white24, size: 16),
                  ),
                  const SizedBox(height: 18),

                  // Save profile button
                  _primaryButton(
                    label: 'Save Changes',
                    isLoading: _isSavingProfile,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 36),

                  // ── Password section ──────────────────────────────────────
                  _sectionLabel('Password'),
                  const SizedBox(height: 10),

                  // Current password
                  _buildField(
                    controller: _currentPwCtrl,
                    label: 'Current Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showCurrentPw,
                    suffixIcon: _eyeToggle(
                      visible: _showCurrentPw,
                      onTap: () =>
                          setState(() => _showCurrentPw = !_showCurrentPw),
                    ),
                  ),
                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSendingOtp ? null : _forgotPassword,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4A60D4)),
                            )
                          : Text(
                              'Forgot Password?',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF4A60D4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // New password
                  _buildField(
                    controller: _newPwCtrl,
                    label: 'New Password',
                    icon: Icons.lock_reset_rounded,
                    obscure: !_showNewPw,
                    suffixIcon: _eyeToggle(
                      visible: _showNewPw,
                      onTap: () =>
                          setState(() => _showNewPw = !_showNewPw),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Confirm new password
                  _buildField(
                    controller: _confirmPwCtrl,
                    label: 'Confirm New Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showConfirmPw,
                    suffixIcon: _eyeToggle(
                      visible: _showConfirmPw,
                      onTap: () =>
                          setState(() => _showConfirmPw = !_showConfirmPw),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use at least 8 characters. Your new password applies immediately on next login.',
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 18),

                  // Change password button
                  _primaryButton(
                    label: 'Change Password',
                    isLoading: _isSavingPw,
                    onPressed: _changePassword,
                  ),
                ],
              ),
            ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        color: Colors.white38,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool obscure = false,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.plusJakartaSans(
        color: readOnly ? Colors.white38 : Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon,
            color: readOnly ? Colors.white24 : Colors.white54, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            readOnly ? const Color(0xFF13131A) : const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF4A60D4), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _eyeToggle({required bool visible, required VoidCallback onTap}) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: Colors.white38,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  Widget _primaryButton({
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white24,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black54))
            : Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
