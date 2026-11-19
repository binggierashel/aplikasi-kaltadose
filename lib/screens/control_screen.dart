import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../core/widgets/status_badge.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({
    super.key,
    required this.onOpenThresholds,
  });

  final VoidCallback onOpenThresholds;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;

    if (device == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaltaPageHeader(
            title: 'Kontrol aktuator',
            subtitle: 'Kendalikan perangkat yang dipilih.',
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

    final modeLocked = !device.online || device.maintenance;
    final actuatorLocked =
        !device.online || device.maintenance || device.mode == DeviceMode.auto;

    String statusNotice;
    NoticeTone statusTone = NoticeTone.warning;
    if (!device.online) {
      statusNotice = 'Perangkat offline. Kontrol tidak dapat dikirim.';
    } else if (device.maintenance) {
      statusNotice =
          'Mode perawatan aktif. Perpindahan mode dan kontrol aktuator dikunci.';
    } else if (device.mode == DeviceMode.auto) {
      statusNotice =
          'Kontrol manual dikunci saat mode otomatis. Pilih mode Manual untuk menggunakan tombol.';
    } else if (device.isWaterLow) {
      statusNotice =
          'Interlock aktif: status tandon Air Mau Habis! Pompa A/B dan solenoid distribusi dikunci; hanya solenoid pengisian yang dapat dibuka.';
      statusTone = NoticeTone.error;
    } else {
      statusNotice =
          'Mode manual aktif. Periksa kondisi tandon sebelum menyalakan pompa.';
    }

    Future<void> requestModeChange(DeviceMode target) async {
      if (modeLocked || device.mode == target) return;
      final ok = await showKaltaConfirmDialog(
        context: context,
        title: 'Ubah mode operasi?',
        message:
            'Beralih ke mode ${target == DeviceMode.auto ? 'otomatis' : 'manual'}? Semua aktuator simulasi akan dimatikan saat perpindahan mode.',
        confirmLabel: 'Ubah mode',
        isDanger: false,
      );
      if (!ok || !context.mounted) return;
      final res = state.changeDeviceMode(device.id, target);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Kontrol aktuator',
          subtitle: 'Kendalikan pompa peristaltik dan katup solenoid.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: state.selectDevice,
          ),
        ),
        const SizedBox(height: 16),

        // Mode Operasi panel
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mode operasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                device.mode == DeviceMode.auto
                    ? 'Aktuator mengikuti pengaturan otomatis perangkat.'
                    : 'Aktuator dikendalikan melalui tombol manual.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.segmentedBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _SegmentButton(
                      label: 'Manual',
                      selected: device.mode == DeviceMode.manual,
                      disabled: modeLocked,
                      onTap: () => requestModeChange(DeviceMode.manual),
                    ),
                    const SizedBox(width: 4),
                    _SegmentButton(
                      label: 'Otomatis',
                      selected: device.mode == DeviceMode.auto,
                      disabled: modeLocked,
                      onTap: () => requestModeChange(DeviceMode.auto),
                    ),
                  ],
                ),
              ),
              if (device.mode == DeviceMode.manual && !modeLocked) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Batas durasi manual aman',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      children: [5, 10, 30, 60].map((sec) {
                        final selected = state.manualDurationSeconds == sec;
                        return InkWell(
                          onTap: () => state.setManualDurationSeconds(sec),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.mint
                                  : AppColors.paper,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? AppColors.green
                                    : AppColors.line,
                              ),
                            ),
                            child: Text(
                              '${sec}d',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? AppColors.forest
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        NoticeBanner(text: statusNotice, tone: statusTone),

        if (device.lastAckText != null) ...[
          const SizedBox(height: 10),
          NoticeBanner(
            text: device.lastAckText!,
            tone: NoticeTone.success,
            icon: Icons.check_circle_outline_rounded,
          ),
        ],

        const SizedBox(height: 14),

        // 4 Actuator control cards
        for (int i = 0; i < 4; i++) ...[
          _ActuatorControlCard(
            name: IoTDevice.actuatorNames[i],
            description: IoTDevice.actuatorDescriptions[i],
            icon: i < 2 ? Icons.water_drop_outlined : Icons.tune_rounded,
            isPump: i < 2,
            active: device.actuators[i],
            disabled: actuatorLocked || (device.isWaterLow && i != 2),
            onToggle: () {
              final res = state.toggleActuator(device.id, i);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.message)),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Pengaturan otomatisasi shortcut
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pengaturan otomatisasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Batas nutrisi, suhu larutan, dan level air.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onOpenThresholds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.forest,
                ),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Atur ambang batas'),
              ),
              const SizedBox(height: 12),
              Text(
                'Respons tombol menjalankan simulasi lokal dan mencatat log aktivitas. Tidak ada pompa atau katup fisik yang dikendalikan.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Opacity(
        opacity: disabled ? 0.48 : 1.0,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(7),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected ? AppColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x14164F43),
                        blurRadius: 6,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.forest : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActuatorControlCard extends StatelessWidget {
  const _ActuatorControlCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.isPump,
    required this.active,
    required this.disabled,
    required this.onToggle,
  });

  final String name;
  final String description;
  final IconData icon;
  final bool isPump;
  final bool active;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final statusLabel = active
        ? (isPump ? 'Menyala' : 'Terbuka')
        : (isPump ? 'Mati' : 'Tertutup');

    return KaltaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SquareIconBadge(
                icon: icon,
                size: 48,
                iconSize: 24,
                radius: 13,
                backgroundColor: AppColors.mint,
                iconColor: AppColors.green,
              ),
              StatusBadge(
                label: statusLabel,
                tone: active ? BadgeTone.mint : BadgeTone.offline,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPump ? 'Daya pompa' : 'Aliran katup',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Opacity(
                opacity: disabled ? 0.45 : 1.0,
                child: GestureDetector(
                  onTap: disabled ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 48,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color:
                          active ? AppColors.green : const Color(0xFFDCE4DE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment:
                        active ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
