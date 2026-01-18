import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:pinput/pinput.dart';

enum _DeleteStep { warning, otp }

class DeleteAccountDialog extends ConsumerStatefulWidget {
  final String phoneNumber;

  const DeleteAccountDialog({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  _DeleteStep _step = _DeleteStep.warning;
  bool _isLoading = false;
  String? _requestId;
  String? _error;
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiClient = ref.read(apiClientProvider);
    final result = await apiClient.sendDeleteAccountOtp(widget.phoneNumber);

    if (!mounted) return;

    if (result is Success<String>) {
      setState(() {
        _requestId = result.data;
        _step = _DeleteStep.otp;
        _isLoading = false;
      });
    } else if (result is Failure) {
      setState(() {
        _error = (result as Failure).error;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeletion() async {
    final otp = _otpController.text.trim();
    
    if (otp.length < 6) {
      setState(() {
        _error = 'يرجى إدخال رمز التحقق كاملاً';
      });
      return;
    }

    if (_requestId == null) {
      setState(() {
        _error = 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
        _step = _DeleteStep.warning;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final apiClient = ref.read(apiClientProvider);

    // 1. Verify OTP
    final verifyResult = await apiClient.verifyDeleteAccountOtp(
      widget.phoneNumber,
      otp,
      _requestId!,
    );

    if (!mounted) return;

    if (verifyResult is Failure) {
      setState(() {
        _error = (verifyResult as Failure).error;
        _isLoading = false;
      });
      return;
    }

    final verificationToken = (verifyResult as Success<String>).data;

    // 2. Confirm Deletion
    final confirmResult = await apiClient.confirmDeleteAccount(
      widget.phoneNumber,
      verificationToken,
    );

    if (!mounted) return;

    if (confirmResult is Failure) {
      setState(() {
        _error = (confirmResult as Failure).error;
        _isLoading = false;
      });
      return;
    }

    // 3. Clear all local data and Redirect
    await ref.read(authControllerProvider.notifier).deleteAccount();
    
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: EduPulseColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  _step == _DeleteStep.warning ? 'حذف الحساب' : 'تأكيد الحذف',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EduPulseColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: EduPulseColors.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Content
            if (_step == _DeleteStep.warning)
              _buildWarningStep()
            else
              _buildOtpStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'هل أنت متأكد من رغبتك في حذف حسابك؟',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'سيؤدي هذا الإجراء إلى حذف جميع بياناتك وصلاحياتك بشكل نهائي. لا يمكن التراجع عن هذا الإجراء.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: EduPulseColors.textMain.withValues(alpha: 0.7),
              ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduPulseColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _sendOtp,
                  child: const Text('إرسال رمز'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'تم إرسال رمز التحقق إلى رقم هاتفك المرتبط بالحساب.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Pinput(
            controller: _otpController,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: EduPulseColors.primary),
              borderRadius: BorderRadius.circular(8),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: const Color.fromRGBO(234, 239, 243, 1),
              ),
            ),
            onCompleted: (pin) => _confirmDeletion(),
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _step = _DeleteStep.warning;
                      _error = null;
                      _otpController.clear();
                    });
                  },
                  child: const Text('رجوع'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EduPulseColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _confirmDeletion,
                  child: const Text('حذف نهائي'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
