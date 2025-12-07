import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_academy/core/result.dart';
import 'package:grace_academy/data/api/api_client.dart';
import 'package:grace_academy/data/models/app_notification.dart';
import 'package:grace_academy/features/auth/auth_controller.dart';

class NotificationsState {
  final bool isLoading;
  final String? error;
  final List<AppNotification> items;
  const NotificationsState({this.isLoading = false, this.error, this.items = const []});
  
  int get unreadCount => items.where((n) => !n.isRead).length;
  
  NotificationsState copyWith({bool? isLoading, String? error, List<AppNotification>? items}) => NotificationsState(
    isLoading: isLoading ?? this.isLoading,
    error: error,
    items: items ?? this.items,
  );
}

class NotificationsController extends AsyncNotifier<NotificationsState> {
  @override
  Future<NotificationsState> build() async {
    return const NotificationsState();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = const AsyncData(NotificationsState(error: 'يجب تسجيل الدخول'));
        return;
      }
      final api = ref.read(apiClientProvider);
      final res = await api.getNotifications(studentId: user.id);
      if (res is Success<List<AppNotification>>) {
        state = AsyncData(NotificationsState(items: res.data));
      } else if (res is Failure<List<AppNotification>>) {
        state = AsyncData(NotificationsState(error: res.error));
      }
    } catch (e) {
      state = AsyncData(NotificationsState(error: e.toString()));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    // Update locally first
    final updatedItems = currentState.items.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }
      return n;
    }).toList();

    state = AsyncData(NotificationsState(items: updatedItems));

    // Then sync with backend
    try {
      final api = ref.read(apiClientProvider);
      await api.markNotificationAsRead(notificationId);
    } catch (e) {
      // Silently fail - local state is already updated
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state.asData?.value;
    if (currentState == null) return;

    final now = DateTime.now();
    final updatedItems = currentState.items.map((n) => n.copyWith(isRead: true, readAt: now)).toList();
    state = AsyncData(NotificationsState(items: updatedItems));

    // Sync each notification with backend
    try {
      final api = ref.read(apiClientProvider);
      for (final n in currentState.items.where((n) => !n.isRead)) {
        api.markNotificationAsRead(n.id); // Fire and forget
      }
    } catch (e) {
      // Silently fail - local state is already updated
    }
  }
}

final notificationsControllerProvider = AsyncNotifierProvider<NotificationsController, NotificationsState>(() => NotificationsController());
