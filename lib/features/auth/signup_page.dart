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

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _startRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = Validators.formatIraqiPhone(_phoneController.text.trim());

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).startRegistration(phone);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (requestId) {
        context.go(AppRoutes.otp, extra: {'phone': phone, 'requestId': requestId});
      },
      failure: (error) async {
        if (error == 'existing_account') {
          final goToLogin = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('الحساب موجود'),
              content: const Text('يوجد حساب مرتبط بهذا الرقم. هل تريد تسجيل الدخول؟'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('تسجيل الدخول')),
              ],
            ),
          );
          if (goToLogin == true && mounted) {
            context.go(AppRoutes.login);
          }
          return;
        }
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
        title: Row(
          children: const [
            AppLogo(size: 36),
            SizedBox(width: 8),
            Text(AppStrings.signUp),
          ],
        ),
        backgroundColor: EduPulseColors.background,
        elevation: 0,
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
              Text(
                'أدخل رقم هاتفك لإنشاء حساب جديد',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: EduPulseColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: Validators.validateIraqiPhone,
                      decoration: InputDecoration(
                        labelText: AppStrings.phoneNumber,
                        hintText: '7712345678',
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: EduPulseColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.phonePrefix,
                            style: TextStyle(
                              color: EduPulseColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) => _startRegistration(),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _startRegistration,
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
                              'إنشاء حساب',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'لديك حساب بالفعل؟ ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: EduPulseColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: EduPulseColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: EduPulseColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'سيتم إرسال رمز التحقق عبر تليجرام',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: EduPulseColors.primary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
