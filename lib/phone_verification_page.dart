import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

import 'package:myapp/supabase_service.dart';

class PhoneVerificationPage extends StatefulWidget {
  final String email;
  final String password;
  final String name;

  const PhoneVerificationPage({
    super.key,
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (_phoneController.text.isEmpty) {
      _showErrorSnackBar('Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign up the user with email and password
      final AuthResponse res = await SupabaseService.client.auth.signUp(
        email: widget.email,
        password: widget.password,
      );

      if (res.user != null) {
        developer.log('Sign up successful for user: ${res.user!.id}');

        // 2. Insert user details into the 'profiles' table
        await SupabaseService.client.from('profiles').insert({
          'id': res.user!.id,
          'name': widget.name,
          'username': widget.email.split('@')[0], // Simple username generation
          'phone_number': _phoneController.text,
        });

        developer.log('Profile created successfully in database');

        _showSuccessSnackBar('Registration successful!');

        // Navigate to home or another page on success
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
         developer.log('Sign up returned no user.');
        _showErrorSnackBar('Registration failed. Please try again.');
      }
    } on AuthException catch (e) {
      developer.log('AuthException: ${e.message}', error: e);
      _showErrorSnackBar('Error: ${e.message}');
    } catch (e) {
       developer.log('Unexpected error: $e', error: e);
      _showErrorSnackBar('An unexpected error occurred.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

   void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: _buildEnterPhoneNumber(),
        ),
      ),
    );
  }

  Widget _buildEnterPhoneNumber() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Enter Your\nPhone Number',
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        _buildTextField(
          controller: _phoneController,
          hintText: '+00 0000000 000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 30),
        _buildStyledButton(
          label: 'Verification',
          onPressed: _isLoading ? null : _registerUser,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Verification',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(prefixIcon, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStyledButton(
      {required String label, required VoidCallback? onPressed, required Widget child}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2E),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
         disabledBackgroundColor: const Color(0xFF2C2C2E).withOpacity(0.5),
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}
