import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/tank_illustration.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.onSelectAndGoDashboard,
    required this.onOpenDetail,
    required this.onAddDevice,
    required this.onEditDevice,
  });

  final ValueChanged<String> onSelectAndGoDashboard;
  final ValueChanged<String> onOpenDetail;
  final VoidCallback onAddDevice;
  final ValueChanged<String> onEditDevice;

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();

    final filtered = state.devices.where((d) {
      final matchesText =
          query.isEmpty ||
          '${d.name} ${d.location} ${d.id}'.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'all' ||
          (_statusFilter == 'online' && d.online) ||
          (_statusFilter == 'offline' && !d.online);
      return matchesText && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Perangkat kebun',
          subtitle:
              'Pilih perangkat yang ingin dipantau. Tidak memerlukan penugasan.',
          action: state.isOwner
              ? ElevatedButton.icon(
                  onPressed: widget.onAddDevice,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah perangkat'),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Search input
        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Cari nama, ID, atau lokasi',
            prefixIcon: const Icon(
              Icons.search_rounded,
              size: 19,
              color: AppColors.muted,
            ),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),

        // Status filter dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              style: Theme.of(context).textTheme.bodyMedium,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua status')),
                DropdownMenuItem(value: 'online', child: Text('Online')),
                DropdownMenuItem(value: 'offline', child: Text('Offline')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _statusFilter = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          const KaltaEmptyState(
            title: 'Tidak ada perangkat',
            message:
                'Coba kata kunci atau filter lain. Owner dapat menambahkan perangkat baru.',
          )
        else
          for (final device in filtered) ...[
            _DeviceCard(
              device: device,
              isSelected: device.id == state.selectedDeviceId,
              isOwner: state.isOwner,
              onSelect: () => widget.onSelectAndGoDashboard(device.id),
              onDetail: () => widget.onOpenDetail(device.id),
              onEdit: () => widget.onEditDevice(device.id),
            ),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isSelected,
    required this.isOwner,
    required this.onSelect,
    required this.onDetail,
    required this.onEdit,
  });

  final IoTDevice device;
  final bool isSelected;
  final bool isOwner;
  final VoidCallback onSelect;
  final VoidCallback onDetail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KaltaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SquareIconBadge(icon: Icons.memory_rounded),
              const Spacer(),
              if (device.maintenance) ...[
                const StatusBadge(label: 'Perawatan', tone: BadgeTone.warning),
                const SizedBox(width: 6),
              ],
              StatusBadge(
                label: device.online ? 'Online' : 'Offline',
                tone: device.online ? BadgeTone.mint : BadgeTone.offline,
                showDot: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const TankIllustration(width: 155, height: 88),
          ),
          const SizedBox(height: 14),
          Text(device.name, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(device.location, style: theme.textTheme.bodySmall),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(bottom: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.id,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  device.online
                      ? '${AppFormatters.integer(device.ppm)} ppm'
                      : 'Data terakhir',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSelect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.forest,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    isSelected ? 'Perangkat dipilih' : 'Pilih perangkat',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onDetail,
                child: const Text('Detail'),
              ),
              if (isOwner) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.edit_outlined, size: 18),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
