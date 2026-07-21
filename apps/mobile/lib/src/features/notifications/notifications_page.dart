import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/account_repository.dart';
import '../../data/concert_repository.dart';
import '../../domain/app_notification.dart';
import '../../theme/livearound_theme.dart';
import '../concert/concert_detail_page.dart';

/// Centre de notifications in-app : les alertes personnalisees calculees par
/// l'API (nouveaux concerts correspondant aux preferences). Le meme contenu
/// partira en push une fois FCM branche.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    required this.accountRepository,
    required this.concertRepository,
    super.key,
  });

  final AccountRepository accountRepository;
  final ConcertRepository concertRepository;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _notificationsFuture = widget.accountRepository.findNotifications();
  }

  Future<void> _open(AppNotification notification) async {
    // Historise le clic (mesure de pertinence), puis ouvre la fiche concert.
    unawaited(
      widget.accountRepository.markNotificationClicked(notification.id),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConcertDetailPage(
          concertId: notification.concertId,
          repository: widget.concertRepository,
        ),
      ),
    );
    if (mounted) setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertes')),
      body: SafeArea(
        child: FutureBuilder<List<AppNotification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data ?? const <AppNotification>[];
            if (notifications.isEmpty) {
              return const _EmptyNotifications();
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(_refresh);
                await _notificationsFuture;
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () => _open(notification),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = notification.createdAt.toLocal();
    final dateLabel =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          notification.isFavoriteReminder
              ? (notification.isRead
                  ? Icons.event_available_outlined
                  : Icons.event_available_rounded)
              : (notification.isRead
                  ? Icons.notifications_none_rounded
                  : Icons.notifications_active_rounded),
          color: notification.isRead
              ? Colors.black.withValues(alpha: 0.6)
              : LiveAroundTheme.coral,
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${notification.body}\n$dateLabel'),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'Aucune alerte pour le moment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Activez les alertes dans votre profil : vous serez prevenu des nouveaux concerts correspondant a vos genres et votre rayon.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
