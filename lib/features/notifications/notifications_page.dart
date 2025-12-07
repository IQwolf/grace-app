import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grace_academy/features/notifications/notifications_controller.dart';
import 'package:grace_academy/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:grace_academy/widgets/app_logo.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationsControllerProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(notificationsControllerProvider);
    final data = asyncState.asData?.value ?? const NotificationsState();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            AppLogo(size: 36),
            SizedBox(width: 8),
            Text('الإشعارات'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: EduPulseColors.background,
      body: Builder(
        builder: (_) {
          if (asyncState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.error != null) {
            return Center(
              child: Text(
                data.error!,
                style: TextStyle(color: EduPulseColors.error),
              ),
            );
          }
          if (data.items.isEmpty) {
            return const Center(
              child: Text('لا توجد إشعارات'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: data.items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = data.items[index];
              final icon = n.type == 'enrollment'
                  ? Icons.school
                  : n.type == 'activation'
                      ? Icons.verified_user
                      : Icons.notifications;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: EduPulseColors.primary.withValues(alpha: 0.1),
                  child: Icon(icon, color: EduPulseColors.primary),
                ),
                title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(n.createdAt),
                      style: TextStyle(color: EduPulseColors.textMain.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ),
                onTap: () {
                  if (n.type == 'enrollment') {
                    // Many backends include courseId only in data payload; the history may not include it
                    // This page can't infer courseId from history item safely without field, so just keep noop or future enhancement
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'الآن';
    
    if (diff.inHours < 1) {
      final minutes = diff.inMinutes;
      if (minutes == 1) return 'منذ دقيقة';
      if (minutes == 2) return 'منذ دقيقتين';
      if (minutes <= 10) return 'منذ $minutes دقائق';
      return 'منذ $minutes دقيقة';
    }
    
    if (diff.inDays < 1) {
      final hours = diff.inHours;
      if (hours == 1) return 'منذ ساعة';
      if (hours == 2) return 'منذ ساعتين';
      if (hours <= 10) return 'منذ $hours ساعات';
      return 'منذ $hours ساعة';
    }
    
    if (diff.inDays < 7) {
      final days = diff.inDays;
      if (days == 1) return 'منذ يوم';
      if (days == 2) return 'منذ يومين';
      return 'منذ $days أيام';
    }
    
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
