import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../core/widgets/status_badge.dart';
import '../state/app_state_scope.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({
    super.key,
    required this.onOpenCalibrationTds,
    required this.onOpenCalibrationHistory,
  });

  final VoidCallback onOpenCalibrationTds;
  final VoidCallback onOpenCalibrationHistory;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;

    if (device == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaltaPageHeader(
            title: 'Perawatan & kalibrasi',
            subtitle: 'Tersedia untuk Owner dan Petani.',
          ),
          SizedBox(height: 16),
          KaltaEmptyState(
            title: 'Belum ada perangkat',
            message:
                'Owner dapat menambahkan perangkat melalui halaman Perangkat.',
          ),
        ],
      );
    }

    final cal = device.calibration;
    final active = cal.activeTds;
    final canToggleMaintenance =
        device.online && cal.pending == null && cal.draft == null;

    Future<void> toggleMaintenance() async {
      if (!device.maintenance) {
        final ok = await showKaltaConfirmDialog(
          context: context,
          title: 'Mulai mode perawatan?',
          message:
              'Pompa dan solenoid ${device.name} akan dimatikan dalam simulasi. Mode operasi dan ambang batas dikunci untuk semua peran selama perawatan.',
          confirmLabel: 'Mulai perawatan',
          isDanger: false,
        );
        if (!ok || !context.mounted) return;
        final res = state.enterMaintenance(device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      } else {
        if (active != null && !active.verified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verifikasi parameter aktif terlebih dahulu; jika gagal, lakukan kalibrasi ulang.',
              ),
            ),
          );
          return;
        }
        final ok = await showKaltaConfirmDialog(
          context: context,
          title: 'Selesaikan perawatan?',
          message:
              'Pastikan probe TDS terpasang kembali dengan aman. ${device.name} akan kembali ke mode manual dengan semua aktuator mati. Aktifkan otomatisasi secara terpisah setelah memeriksa kondisi.',
          confirmLabel: 'Selesaikan perawatan',
          isDanger: false,
        );
        if (!ok || !context.mounted) return;
        final res = state.exitMaintenance(device.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.message)),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Perawatan & kalibrasi',
          subtitle: 'Kalibrasi sensor TDS untuk perangkat yang dipilih.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: state.selectDevice,
          ),
        ),
        const SizedBox(height: 16),

        const NoticeBanner(
          text:
              'Alur sistem: aplikasi mengirim referensi → ESP menghitung dan menyimpan secara atomik ke NVS → ESP mengirim konfirmasi ACK. Pada build lokal ini proses ESP disimulasikan interaktif.',
        ),
        const SizedBox(height: 14),

        // Mode Perawatan Card
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: device.maintenance
                      ? 'Mode perawatan aktif'
                      : 'Operasional',
                  tone:
                      device.maintenance ? BadgeTone.warning : BadgeTone.offline,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Siapkan perangkat sebelum kalibrasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Pompa dan solenoid dimatikan selama perawatan. Setelah selesai, perangkat kembali ke mode manual aman, bukan langsung otomatis.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (device.maintenance)
                OutlinedButton.icon(
                  onPressed: canToggleMaintenance ? toggleMaintenance : null,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Selesaikan perawatan'),
                )
              else
                ElevatedButton.icon(
                  onPressed: canToggleMaintenance ? toggleMaintenance : null,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text('Mulai perawatan'),
                ),
            ],
          ),
        ),

        if (!device.online) ...[
          const SizedBox(height: 14),
          const NoticeBanner(
            text:
                'Perangkat offline. Kalibrasi dan penyelesaian perawatan tidak dapat dikonfirmasi. Pulihkan koneksi melalui Detail perangkat.',
            tone: NoticeTone.warning,
          ),
        ],

        const SizedBox(height: 14),

        // Sensor TDS Card
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SquareIconBadge(
                icon: Icons.water_drop_outlined,
                size: 40,
                iconSize: 21,
              ),
              const SizedBox(height: 14),
              Text(
                'Sensor TDS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Gunakan larutan standar dan skala PPM yang cocok dengan sensor.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  border: Border(
                    left: BorderSide(color: Color(0xFFA1B779), width: 3),
                  ),
                ),
                child: Text(
                  active != null
                      ? active.value.formattedSummary
                      : 'Belum ada parameter tersimpan',
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.55,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                active != null
                    ? 'Konfirmasi ESP simulasi: ${AppFormatters.dateTimeShort(active.time)} · ${active.verified ? 'Terverifikasi secara simulasi' : 'Perlu verifikasi'}'
                    : 'Belum pernah dikalibrasi pada perangkat ini.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onOpenCalibrationTds,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.forest,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  label: const Text('Buka kalibrasi TDS'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Riwayat Kalibrasi Card
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catatan kalibrasi TDS',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${cal.history.length} catatan pada perangkat ini. Nilai lama dipertahankan jika penyimpanan ditolak atau waktu tunggu habis. Selesaikan verifikasi sebelum keluar dari perawatan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onOpenCalibrationHistory,
                icon: const Icon(Icons.history_rounded, size: 17),
                label: const Text('Lihat riwayat'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
