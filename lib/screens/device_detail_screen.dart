import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/tank_illustration.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({
    super.key,
    required this.onBack,
    required this.onEditDevice,
    required this.onOpenDashboard,
    required this.onOpenControl,
    required this.onOpenThresholds,
    required this.onOpenMaintenance,
    required this.onDeleted,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onEditDevice;
  final VoidCallback onOpenDashboard;
  final VoidCallback onOpenControl;
  final VoidCallback onOpenThresholds;
  final VoidCallback onOpenMaintenance;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;

    if (device == null) {
      return const KaltaEmptyState(
        title: 'Belum ada perangkat',
        message: 'Pilih atau tambahkan perangkat terlebih dahulu.',
      );
    }

    final activeCal = device.calibration.activeTds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaBackLink(label: 'Daftar perangkat', onTap: onBack),
        const SizedBox(height: 10),
        KaltaPageHeader(
          title: device.name,
          subtitle: 'Informasi perangkat dan status koneksi.',
          action: state.isOwner
              ? OutlinedButton.icon(
                  onPressed: () => onEditDevice(device.id),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit perangkat'),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: device.online ? 'Online' : 'Offline',
                      tone: device.online
                          ? BadgeTone.heroOnline
                          : BadgeTone.heroOffline,
                      showDot: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Smart Autodosing',
                      style: AppFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Nutrisi AB Mix\n${device.location}',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Color(0xFFD2E2DA),
                      ),
                    ),
                  ],
                ),
              ),
              const TankIllustration(width: 112, height: 102),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Informasi perangkat
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi perangkat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              KaltaDetailRow(label: 'ID perangkat', value: device.id),
              KaltaDetailRow(label: 'Nama perangkat', value: device.name),
              KaltaDetailRow(label: 'Lokasi', value: device.location),
              KaltaDetailRow(label: 'Jenis tanaman', value: device.plantType),
              KaltaDetailRow(
                label: 'Kapasitas tandon',
                value: '${device.tankVolumeLiters} liter',
              ),
              KaltaDetailRow(label: 'Versi firmware', value: device.firmware),
              KaltaDetailRow(
                label: 'Data terakhir diterima',
                value: AppFormatters.dateTimeShort(device.lastUpdate),
              ),
              KaltaDetailRow(
                label: 'Mode aktif',
                value: device.maintenance
                    ? 'Mode perawatan (dikunci)'
                    : device.mode.label,
              ),
              KaltaDetailRow(
                label: 'Kalibrasi TDS',
                value: activeCal != null
                    ? '${AppFormatters.dateTimeShort(activeCal.time)} (${activeCal.verified ? 'Terverifikasi' : 'Perlu verifikasi'})'
                    : 'Belum ada parameter',
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Akses cepat
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Akses cepat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onOpenDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.forest,
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text('Buka dashboard'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenControl,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Kontrol aktuator'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenThresholds,
                icon: const Icon(Icons.water_drop_outlined, size: 18),
                label: const Text('Atur ambang batas'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenMaintenance,
                icon: const Icon(Icons.build_outlined, size: 18),
                label: const Text('Perawatan & kalibrasi TDS'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Simulasi koneksi
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Simulasi koneksi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Coba kondisi online dan offline untuk menguji pengaman kontrol serta kalibrasi, tanpa mengubah perangkat fisik.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  final res = state.toggleDeviceOnline(device.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res.message)),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  device.online
                      ? 'Simulasikan offline'
                      : 'Simulasikan online',
                ),
              ),
            ],
          ),
        ),

        if (state.isOwner) ...[
          const SizedBox(height: 14),
          KaltaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hapus perangkat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Menghapus perangkat dari daftar aplikasi, bukan mematikan perangkat fisik.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (device.maintenance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Selesaikan mode perawatan sebelum menghapus perangkat.',
                          ),
                        ),
                      );
                      return;
                    }
                    final ok = await showKaltaConfirmDialog(
                      context: context,
                      title: 'Hapus perangkat?',
                      message:
                          '${device.name} akan dihapus dari daftar aplikasi. Tindakan ini tidak mematikan perangkat fisik.',
                      confirmLabel: 'Hapus perangkat',
                    );
                    if (!ok || !context.mounted) return;
                    final res = state.deleteDevice(device.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                    if (res.ok) onDeleted();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redBg,
                    foregroundColor: AppColors.red,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus perangkat'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
