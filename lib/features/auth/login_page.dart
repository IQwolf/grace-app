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
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = Validators.formatIraqiPhone(_phoneController.text.trim());

    setState(() => _isLoading = true);

    final result = await ref.read(authControllerProvider.notifier).signIn(phone);

    setState(() => _isLoading = false);

    if (!mounted) return;

    result.when(
      success: (requestId) {
        context.go(AppRoutes.otp, extra: {'phone': phone, 'requestId': requestId});
      },
      failure: (error) async {
        if (error == 'no_account') {
          final goToSignup = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('لا يوجد حساب'),
              content: const Text('لا يوجد حساب مرتبط بهذا الرقم. يرجى إنشاء حساب أولاً.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('إنشاء حساب')),
              ],
            ),
          );
          if (goToSignup == true && mounted) {
            context.go(AppRoutes.signup);
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

  void _showSupportDialog() {
    final telegramUri = Uri.parse('https://t.me/Grace_academy1');
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'gracelearning.team@gmail.com',
      queryParameters: const {
        'subject': 'دعم Grace Academy',
        'body': 'مرحبا,\n\n',
      },
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.support),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('اختر طريقة التواصل'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('تيليجرام: @Grace_academy1'),
              onPressed: () async {
                Navigator.of(context).pop();
                final launched = await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                if (!launched && context.mounted) {
                  await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
                }
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.email, color: Colors.blue),
              label: const Text('البريد: gracelearning.team@gmail.com'),
              onPressed: () async {
                Navigator.of(context).pop();
                final launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                if (!launched && context.mounted) {
                  await launchUrl(emailUri, mode: LaunchMode.platformDefault);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Logo and title
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logononbackground.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      AppStrings.login,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'أدخل رقم هاتفك للمتابعة',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: EduPulseColors.textMain.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Phone number field
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                      onFieldSubmitted: (_) => _signIn(),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
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
                          : Text(
                              AppStrings.login,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ليس لديك حساب؟ ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.signup),
                            child: Text(
                              'إنشاء حساب',
                              style: TextStyle(
                                color: EduPulseColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Continue without login
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.home),
                      icon: Icon(Icons.home_outlined, color: EduPulseColors.primary),
                      label: Text(
                        'العودة إلى الرئيسية بدون تسجيل',
                        style: TextStyle(color: EduPulseColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: EduPulseColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showSupportDialog,
                        icon: Icon(Icons.support_agent, color: EduPulseColors.primary),
                        label: Text(
                          'التواصل مع الدعم',
                          style: TextStyle(
                            color: EduPulseColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Info text
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