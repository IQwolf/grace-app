import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/models/university.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';

final universitiesProvider =
    FutureProvider.autoDispose.family<List<University>, String?>((ref, type) async {
  final apiClient = ref.watch(apiClientProvider);
  final result = await apiClient.getUniversities(type: type);
  return result.when(
    success: (value) => value,
    failure: (error) => throw Exception(error),
  );
});