import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/core/validators.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:grace_academy/widgets/app_logo.dart';

class OTPPage extends ConsumerStatefulWidget {
  final String phone;
  final String requestId;

  const OTPPage({
    super.key,
    required this.phone,
    required this.requestId,
  });

  @override
  ConsumerState<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends ConsumerState<OTPPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  late String _requestId;

  @override
  void initState() {
    super.initState();
    _requestId = widget.requestId;
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier)
        .verifyOtp(widget.phone, _otpController.text.trim(), _requestId);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (user) {
        if (user == null) {
          context.go(AppRoutes.profileForm, extra: widget.phone);
        } else {
          context.go(AppRoutes.home);
        }
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: EduPulseColors.error,
          ),
        );
      },
    );
  }

  Future<void> _resendCode() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    final res = await ref.read(authControllerProvider.notifier).resendOtp(widget.phone);
    if (!mounted) return;
    setState(() => _isResending = false);
    res.when(
      success: (newRequestId) {
        _requestId = newRequestId;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال الرمز مرة أخرى'),
            backgroundColor: EduPulseColors.primary,
          ),
        );
      },
      failure: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: EduPulseColors.error,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduPulseColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const AppLogo(size: 36),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Title and subtitle
              Center(
                child: Column(
                  children: [
                    Text(
                      AppStrings.verifyCode,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      AppStrings.codeSentViaTelegram,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: EduPulseColors.textMain.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      widget.phone,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: EduPulseColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // OTP Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // OTP field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: Validators.validateOTP,
                      decoration: const InputDecoration(
                        labelText: 'رمز التحقق',
                      ),
                      onFieldSubmitted: (_) => _verifyOtp(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Verify button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'تحقق',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Resend code
                    Center(
                      child: TextButton(
                        onPressed: _isResending ? null : _resendCode,
                        child: Text(_isResending ? 'جارٍ الإرسال…' : 'إعادة إرسال الرمز'),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}