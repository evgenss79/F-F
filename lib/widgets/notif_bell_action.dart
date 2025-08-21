import 'package:flutter/material.dart';
import '../notifications_service.dart';
import 'notification_bell.dart';
import '../screens/notifications_screen.dart';

class NotifBellAction extends StatelessWidget {
  const NotifBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.unreadCount,
      builder: (context, count, _) => NotificationBell(
        count: count,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        },
      ),
    );
  }
}
