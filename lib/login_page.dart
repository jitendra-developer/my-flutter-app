import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/app_constants.dart';
import 'package:myapp/google_esign.dart';
import 'package:myapp/utils.dart';

class AuthHubPage extends StatefulWidget {
  const AuthHubPage({super.key});

  @override
  State<AuthHubPage> createState() => _AuthHubPageState();
}

class _AuthHubPageState extends State<AuthHubPage> {
  final GoogleESign _googleESign = GoogleESign();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', height: 100),
                      const SizedBox(height: 40),
                      Text(
                        'Welcome to',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        appName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 60),
                      _buildMainButton(
                        'Log in with Email',
                        () => context.go('/email-login'),
                      ),
                      const SizedBox(height: 16),
                      _buildSecondaryButton(
                        'Sign up with Email',
                        () => context.go('/register'),
                      ),
                      const SizedBox(height: 40),
                      _buildSocialSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Or continue with',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                type: 'google',
                imagePath: 'assets/images/google_logo.png',
                bgColor: const Color(0xFF3D2022),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                type: 'facebook',
                imagePath: 'assets/images/facebook_logo.png',
                bgColor: const Color(0xFF222E3E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String type,
    required String imagePath,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: () async {
        if (_isLoading) return;
        setState(() => _isLoading = true);
        try {
          if (type == 'google') {
            await _googleESign.signInWithGoogle();
          } else if (type == 'facebook') {
            showFeedback(
              context,
              'Facebook Sign-In is not implemented yet.',
              isError: true,
            );
          }
        } catch (e) {
          showFeedback(
            context,
            '$type Sign-In failed. Please try again.',
            isError: true,
          );
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Image.asset(imagePath, height: 24, width: 24),
      ),
    );
  }
}
