import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      showFeedback(context, 'Please enter a 6-digit OTP.', isError: true);
      return;
    }
    setState(() => _isVerifying = true);

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.signup,
        token: _otpController.text.trim(),
        email: widget.email,
      );
      // The GoRouter redirect logic in main.dart will handle navigation
      // to the /chat screen automatically upon successful session creation.
      developer.log('OTP verification successful: ${response.user?.id}');
    } on AuthException catch (e) {
      developer.log('OTP AuthException: ${e.message}', error: e);
      showFeedback(context, e.message, isError: true);
    } catch (e) {
      developer.log('Unexpected OTP error: $e', error: e);
      showFeedback(context, 'An unexpected error occurred.', isError: true);
    }

    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      showFeedback(
        context,
        'A new confirmation code has been sent to ${widget.email}.',
      );
    } on AuthException catch (e) {
      developer.log('Resend OTP AuthException: ${e.message}', error: e);
      showFeedback(context, e.message, isError: true);
    } catch (e) {
      developer.log('Unexpected Resend OTP error: $e', error: e);
      showFeedback(context, 'An unexpected error occurred.', isError: true);
    }

    if (mounted) {
      setState(() => _isResending = false);
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
