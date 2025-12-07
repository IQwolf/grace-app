import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_academy/features/auth/signup_page.dart';

// Thin wrapper to expose a RegisterPage while keeping existing SignupPage logic.
class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SignupPage();
  }
}
