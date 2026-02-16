import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/app_constants.dart';
import 'package:myapp/chat_page.dart';
import 'package:myapp/login.dart' as separate_login;
import 'package:myapp/register.dart' as separate_register;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildWelcomePage(),
                _buildSignInPage(),
                _buildSignUpPage(),
                _buildPhonePage(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
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
            'Log in',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const separate_login.LoginPage(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const separate_register.RegisterPage(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF2C2C2C),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Sign up',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildSocialSection(),
        ],
      ),
    );
  }

  Widget _buildSignInPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(() => _pageController.jumpToPage(0)),
          const SizedBox(height: 40),
          Text(
            'Login Your\nAccount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          _buildTextField(Icons.email_outlined, 'Enter Your Email'),
          const SizedBox(height: 16),
          _buildTextField(Icons.lock_outline, 'Password', isPassword: true),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forget Password ?',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMainButton('Login', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
          }),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'New Account? ',
                style: GoogleFonts.plusJakartaSans(color: Colors.white54),
              ),
              GestureDetector(
                onTap: () => _pageController.jumpToPage(2),
                child: Text(
                  'Sign up',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildSocialSection(),
        ],
      ),
    );
  }

  Widget _buildSignUpPage() {
    final formKey = GlobalKey<FormState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBackButton(() => _pageController.jumpToPage(0)),
            const SizedBox(height: 40),
            Text(
              'Create your\nAccount',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField(Icons.person_outline, 'Full Name', required: true),
            const SizedBox(height: 16),
            _buildTextField(
              Icons.email_outlined,
              'Enter Your Email',
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              Icons.lock_outline,
              'Password',
              isPassword: true,
              required: true,
            ),
            const SizedBox(height: 30),
            _buildMainButton('Register', () {
              if (formKey.currentState!.validate()) {
                _pageController.jumpToPage(3);
              }
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already Have An Account? ',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white54),
                ),
                GestureDetector(
                  onTap: () => _pageController.jumpToPage(1),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            _buildSocialSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhonePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBackButton(() => _pageController.jumpToPage(2)),
          const SizedBox(height: 40),
          Text(
            'Enter Your Phone\nNumber',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          _buildTextField(Icons.phone_outlined, 'Phone Number'),
          const SizedBox(height: 30),
          _buildMainButton('Verification', () {}),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: const Color(0xFF2C2C2C),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Later',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(VoidCallback? onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3D3D)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint, {
    bool isPassword = false,
    bool required = false,
  }) {
    return TextFormField(
      obscureText: isPassword,
      style: GoogleFonts.plusJakartaSans(color: Colors.white),
      validator: required
          ? (value) => value == null || value.isEmpty ? 'Field required' : null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white38,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white38),
        suffixIcon: isPassword
            ? Icon(Icons.visibility_off_outlined, color: Colors.white30)
            : null,
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

  Widget _buildSocialSection() {
    return Column(
      children: [
        Center(
          child: Text(
            'Continue With Accounts',
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
                'GOOGLE',
                const Color(0xFF3D2022),
                const Color(0xFFF8D7DA),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSocialButton(
                'FACEBOOK',
                const Color(0xFF1A2A3D),
                const Color(0xFFD1E7FF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, Color bgColor, Color textColor) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
