import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/notification_item.dart';
import '../state/app_state_scope.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.onOpenDeviceDetail,
  });

  final ValueChanged<String> onOpenDeviceDetail;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final rows = _unreadOnly
        ? state.notifications.where((n) => !n.read).toList()
        : state.notifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Notifikasi',
          subtitle: 'Peringatan kondisi sensor dan koneksi perangkat.',
          action: OutlinedButton.icon(
            onPressed: state.unreadNotificationCount > 0
                ? () {
                    state.markAllNotificationsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua notifikasi ditandai dibaca'),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.check_rounded, size: 17),
            label: const Text('Tandai semua dibaca'),
          ),
        ),
        const SizedBox(height: 16),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pembaruan kebun',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.segmentedBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'Semua',
                      selected: !_unreadOnly,
                      onTap: () => setState(() => _unreadOnly = false),
                    ),
                    const SizedBox(width: 4),
                    _FilterTab(
                      label: 'Belum dibaca (${state.unreadNotificationCount})',
                      selected: _unreadOnly,
                      onTap: () => setState(() => _unreadOnly = true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Semua notifikasi sudah dibaca.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (int i = 0; i < rows.length; i++) ...[
                  _NotificationRow(
                    item: rows[i],
                    showDivider: i < rows.length - 1,
                    onInspect: () {
                      state.markNotificationRead(rows[i].id);
                      widget.onOpenDeviceDetail(rows[i].deviceId);
                    },
                    onMarkRead: () => state.markNotificationRead(rows[i].id),
                  ),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.forest : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.showDivider,
    required this.onInspect,
    required this.onMarkRead,
  });

  final AppNotification item;
  final bool showDivider;
  final VoidCallback onInspect;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    final badgeTone = switch (item.severity) {
      NotificationSeverity.critical => BadgeTone.danger,
      NotificationSeverity.warning => BadgeTone.warning,
      NotificationSeverity.info => BadgeTone.owner,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: item.read ? Colors.transparent : AppColors.unreadBg,
        borderRadius: BorderRadius.circular(10),
        border: showDivider && item.read
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SquareIconBadge(
            icon: item.type == NotificationType.offline
                ? Icons.memory_rounded
                : Icons.water_drop_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(
                      label: item.severity.label,
                      tone: badgeTone,
                    ),
                    if (!item.read)
                      const StatusBadge(label: 'Baru', tone: BadgeTone.mint),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.dateTimeShort(item.time),
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    TextButton(
                      onPressed: onInspect,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('Lihat perangkat'),
                    ),
                    if (!item.read)
                      TextButton(
                        onPressed: onMarkRead,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(0, 32),
                        ),
                        child: const Text('Tandai dibaca'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
