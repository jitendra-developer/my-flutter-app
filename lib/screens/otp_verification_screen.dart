import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';
import 'package:myapp/chat_provider.dart';
import 'package:myapp/services/api_service.dart';
import 'package:myapp/utils.dart';
import 'dart:developer' as developer;

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      showFeedback(context, 'Please enter a 6-digit OTP.', isError: true);
      return;
    }
    setState(() => _isVerifying = true);

    try {
      final apiService = ApiService();
      await apiService.verifyEmailOTP(
        widget.email,
        _otpController.text.trim(),
      );
      
      developer.log('OTP verification successful');
      if (mounted) {
        Provider.of<ChatProvider>(context, listen: false).initializeAfterAuth();
        context.go('/chat');
      }
    } catch (e) {
      developer.log('OTP error: $e', error: e);
      if (mounted) {
        showFeedback(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      final apiService = ApiService();
      await apiService.resendEmailOTP(widget.email);
      
      if (mounted) {
        showFeedback(
          context,
          'A new confirmation code has been sent to ${widget.email}.',
        );
      }
    } catch (e) {
      developer.log('Resend OTP error: $e', error: e);
      if (mounted) {
        showFeedback(context, e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/register'), // Go back to registration
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Verify Email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'We have sent a code to your email',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  widget.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Pinput(
                  controller: _otpController,
                  length: 6,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  onCompleted: (_) => _verifyOtp(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying
                      ? const CircularProgressIndicator()
                      : const Text('Verify'),
                ),
                TextButton(
                  onPressed: _isResending ? null : _resendOtp,
                  child: _isResending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Send Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
