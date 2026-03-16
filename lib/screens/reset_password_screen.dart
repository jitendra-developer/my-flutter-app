import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import 'package:myapp/services/api_service.dart';
import 'package:myapp/utils.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _otpCtrl     = TextEditingController();
  final TextEditingController _newPwCtrl   = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _showNewPw     = false;
  bool _showConfirm   = false;
  bool _isResending   = false;
  bool _isSubmitting  = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      await _apiService.forgotPasswordOtp(widget.email);
      if (mounted) {
        showFeedback(context, 'A new code has been sent to ${widget.email}');
      }
    } catch (e) {
      developer.log('Resend OTP error: $e', error: e);
      if (mounted) {
        showFeedback(context,
            e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _resetPassword() async {
    final otp     = _otpCtrl.text.trim();
    final newPw   = _newPwCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (otp.length != 6) {
      showFeedback(context, 'Please enter the 6-digit code', isError: true);
      return;
    }
    if (newPw.isEmpty || confirm.isEmpty) {
      showFeedback(context, 'Please fill in the password fields', isError: true);
      return;
    }
    if (newPw.length < 8) {
      showFeedback(context, 'Password must be at least 8 characters',
          isError: true);
      return;
    }
    if (newPw != confirm) {
      showFeedback(context, 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _apiService.resetPasswordWithOtp(
        email: widget.email,
        otp: otp,
        newPassword: newPw,
        newPasswordConfirmation: confirm,
      );
      if (mounted) {
        showFeedback(context, 'Password reset successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      developer.log('Reset password error: $e', error: e);
      if (mounted) {
        showFeedback(context,
            e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pinput theme matching the global palette
    final pinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3D3D3D)),
      ),
    );

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
          'Reset Password',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Text(
              'Check your email',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 14, height: 1.5),
                children: [
                  const TextSpan(text: 'We sent a 6-digit code to '),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(
                      text:
                          '. Enter the code below along with your new password.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── OTP section label ────────────────────────────────────────
            Text(
              'VERIFICATION CODE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white38,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ── Pinput ───────────────────────────────────────────────────
            Center(
              child: Pinput(
                controller: _otpCtrl,
                length: 6,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyDecorationWith(
                  border: Border.all(
                      color: const Color(0xFF4A60D4), width: 1.5),
                ),
                submittedPinTheme: pinTheme.copyDecorationWith(
                  color: const Color(0xFF1C1C24),
                  border: Border.all(color: const Color(0xFF4A60D4)),
                ),
                showCursor: true,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              ),
            ),
            const SizedBox(height: 6),

            // ── Resend link ──────────────────────────────────────────────
            Center(
              child: TextButton(
                onPressed: _isResending ? null : _resendOtp,
                child: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF4A60D4)),
                      )
                    : Text(
                        "Didn't receive a code? Resend",
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF4A60D4),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // ── New password section label ────────────────────────────────
            Text(
              'NEW PASSWORD',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.white38,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            // ── New password field ────────────────────────────────────────
            _buildField(
              controller: _newPwCtrl,
              label: 'New Password',
              icon: Icons.lock_reset_rounded,
              obscure: !_showNewPw,
              eye: _eyeToggle(
                  visible: _showNewPw,
                  onTap: () => setState(() => _showNewPw = !_showNewPw)),
            ),
            const SizedBox(height: 12),

            // ── Confirm password field ────────────────────────────────────
            _buildField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              icon: Icons.lock_outline_rounded,
              obscure: !_showConfirm,
              eye: _eyeToggle(
                  visible: _showConfirm,
                  onTap: () =>
                      setState(() => _showConfirm = !_showConfirm)),
            ),
            const SizedBox(height: 6),
            Text(
              'Minimum 8 characters.',
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // ── Reset button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black54))
                    : Text(
                        'Reset Password',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required Widget eye,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style:
          GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        suffixIcon: eye,
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
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
}
