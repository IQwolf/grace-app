import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/app_router.dart';
import 'package:grace_academy/core/strings.dart';
import 'package:grace_academy/data/models/user.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:grace_academy/features/account/delete_account_dialog.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: EduPulseColors.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: EduPulseColors.textMain.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'يجب تسجيل الدخول',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EduPulseColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'سجل دخولك لعرض حسابك',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: EduPulseColors.textMain.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text(AppStrings.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: EduPulseColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: EduPulseColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppStrings.account,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Profile card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: EduPulseColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: EduPulseColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profile avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: EduPulseColors.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: EduPulseColors.primary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // User name
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: EduPulseColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Phone number
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: EduPulseColors.textMain.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.phone,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: EduPulseColors.textMain.withValues(alpha: 0.7),
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Profile details
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: EduPulseColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: EduPulseColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.location_city,
                      label: AppStrings.governorate,
                      value: user.governorate,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.school,
                      label: AppStrings.university,
                      value: user.university,
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: Icons.cake,
                      label: AppStrings.birthDate,
                      value: '${user.birthDate.year}-${user.birthDate.month.toString().padLeft(2, '0')}-${user.birthDate.day.toString().padLeft(2, '0')}',
                    ),
                    _buildDivider(),
                    _buildInfoTile(
                      icon: user.gender == Gender.male ? Icons.male : Icons.female,
                      label: AppStrings.gender,
                      value: user.gender == Gender.male ? AppStrings.male : AppStrings.female,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Actions
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: EduPulseColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: EduPulseColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      context,
                      icon: Icons.support_agent,
                      title: AppStrings.support,
                      onTap: () => _showSupportDialog(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      context,
                      icon: Icons.logout,
                      title: AppStrings.logout,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      context,
                      icon: Icons.edit,
                      title: AppStrings.editAccount,
                      onTap: () => _navigateToEditAccount(context),
                    ),
                    _buildDivider(),
                    _buildActionTile(
                      context,
                      icon: Icons.delete_forever,
                      title: 'حذف الحساب',
                      isDestructive: true,
                      onTap: () => _showDeleteAccountDialog(context, user.phone),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'رمز المستقبل للحلول البرمجية | 07719353229',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ),

              const SizedBox(height: 100), // Bottom padding for navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: EduPulseColors.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: EduPulseColors.textMain.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? EduPulseColors.error : EduPulseColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? EduPulseColors.error : EduPulseColors.textMain,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: EduPulseColors.textMain.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: EduPulseColors.divider,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showSupportDialog(BuildContext context) {
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
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('تيليجرام: @Grace_academy1'),
              onPressed: () async {
                Navigator.of(context).pop();
                bool launched = await launchUrl(telegramUri, mode: LaunchMode.externalApplication);
                if (!launched && context.mounted) {
                  await launchUrl(telegramUri, mode: LaunchMode.platformDefault);
                }
              },
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.email, color: Colors.blue),
              label: const Text('البريد: gracelearning.team@gmail.com'),
              onPressed: () async {
                Navigator.of(context).pop();
                bool launched = await launchUrl(emailUri, mode: LaunchMode.externalApplication);
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: Text(
              AppStrings.logout,
              style: TextStyle(color: EduPulseColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAccountDialog(phoneNumber: phoneNumber),
    );
  }

  Future<void> _navigateToEditAccount(BuildContext context) async {
    final result = await context.push<bool>(AppRoutes.editAccount);
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.profileUpdated),
          backgroundColor: EduPulseColors.primary,
        ),
      );
    }
  }
}
