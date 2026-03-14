import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/utils.dart';
import 'dart:developer' as developer;
import 'package:myapp/google_esign.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:myapp/utils/app_localization.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final GoogleESign _googleESign = GoogleESign();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      await apiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      developer.log('Login successful');
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false).initializeAfterAuth();
        context.go('/chat');
      }
    } catch (e) {
      developer.log('Login error: $e', error: e);
      if (e.toString().contains('credentials') || e.toString().contains('does not exist')) {
        showFeedback(
          context,
          'User does not exist or password was incorrect.',
          isError: true,
        );
      } else {
        showFeedback(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final l10n = chatProvider.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.translate('welcome_back'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.translate('sign_in_continue'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: l10n.translate('enter_email'),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter an email';
                      if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hint: l10n.translate('password'),
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter a password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMainButton(l10n.translate('login'), _login),
                  const SizedBox(height: 20),
                  _buildSignUpInstead(l10n),
                  const SizedBox(height: 40),
                  _buildSocialSection(l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (keeping other helper methods mostly same but updating where needed)
  // I need to update _buildSignUpInstead and _buildSocialSection signature to accept l10n

  Widget _buildSignUpInstead(AppLocalization l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${l10n.translate('dont_have_account')} ",
          style: GoogleFonts.plusJakartaSans(color: Colors.white54),
        ),
        GestureDetector(
          onTap: () => context.go('/register'),
          child: Text(
            l10n.translate('sign_up'),
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialSection(AppLocalization l10n) {
    return Column(
      children: [
        Center(
          child: Text(
            l10n.translate('or_continue_with'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: GoogleFonts.plusJakartaSans(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3D3D3D)),
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
            
            // Navigate on success
            if (mounted) {
              final apiService = ApiService();
              if (await apiService.hasToken()) {
                 developer.log('Google login confirmed, navigating to chat');
                 Provider.of<ChatProvider>(context, listen: false).initializeAfterAuth();
                 context.go('/chat');
              }
            }
          } else if (type == 'facebook') {
            showFeedback(
              context,
              'Facebook Sign-In is not implemented yet.',
              isError: true,
            );
          }
        } catch (e) {
          developer.log('$type Sign-In failed: $e', error: e);
          showFeedback(
            context,
            e.toString().replaceAll('Exception: ', ''),
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
