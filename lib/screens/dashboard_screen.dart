import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../core/widgets/sensor_line_chart.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/tank_illustration.dart';
import '../models/device_model.dart';
import '../models/sensor_reading.dart';
import '../models/user_model.dart';
import '../state/app_state_scope.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenDetail,
    required this.onOpenHistory,
    required this.onOpenControl,
  });

  final VoidCallback onOpenDetail;
  final VoidCallback onOpenHistory;
  final VoidCallback onOpenControl;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;

    if (device == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaltaPageHeader(
            title: 'Dashboard',
            subtitle: 'Ringkasan kondisi kebun Anda.',
          ),
          SizedBox(height: 18),
          KaltaEmptyState(
            title: 'Belum ada perangkat',
            message:
                'Owner dapat menambahkan perangkat melalui halaman Perangkat.',
          ),
        ],
      );
    }

    final deviceReadings = state.readings
        .where((r) => r.deviceId == device.id)
        .toList();
    final chartRows = deviceReadings.length > 12
        ? deviceReadings.sublist(deviceReadings.length - 12)
        : deviceReadings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Kebun dalam pantauan',
          subtitle: 'Lihat kondisi nutrisi dan perangkat yang Anda pilih.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: state.selectDevice,
          ),
        ),
        const SizedBox(height: 16),

        // Hero Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 14, 20),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusBadge(
                          label: device.online ? 'Online' : 'Offline',
                          tone: device.online
                              ? BadgeTone.heroOnline
                              : BadgeTone.heroOffline,
                          showDot: true,
                        ),
                        InkWell(
                          onTap: state.toggleLiveSimulation,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: state.liveSimulationEnabled
                                  ? AppColors.lime.withValues(alpha: 0.22)
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.liveSimulationEnabled
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 13,
                                  color: AppColors.lime,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  state.liveSimulationEnabled
                                      ? 'Live aktif'
                                      : 'Simulasi live',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lime,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      device.name,
                      style: AppFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.25,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${device.location}\n${device.online ? 'Data terakhir diterima ${AppFormatters.dateTimeShort(device.lastUpdate)}' : 'Menampilkan data terakhir sebelum koneksi terputus.'}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: Color(0xFFD2E2DA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: onOpenDetail,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Lihat detail perangkat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.lime,
                                ),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.lime,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const TankIllustration(width: 112, height: 108),
            ],
          ),
        ),

        if (!device.online) ...[
          const SizedBox(height: 14),
          const NoticeBanner(
            text:
                'Perangkat offline. Nilai berikut adalah data terakhir; kontrol dan perubahan pengaturan dinonaktifkan.',
            tone: NoticeTone.warning,
          ),
        ],

        if (device.online && device.isWaterLow) ...[
          const SizedBox(height: 14),
          const NoticeBanner(
            text:
                'Level air tandon: Air Mau Habis! Pompa autodosing dinonaktifkan sementara untuk proteksi hardware.',
            tone: NoticeTone.error,
          ),
        ],

        const SizedBox(height: 14),

        // Panel Simulasi Data Dummy Random
        KaltaCard(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SquareIconBadge(
                    icon: Icons.casino_outlined,
                    size: 34,
                    iconSize: 18,
                    backgroundColor: AppColors.mint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Simulasi data dummy',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text(
                          'Uji perubahan sensor random & status air tandon secara instan.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final res = state.randomizeDummyData(
                          deviceId: device.id,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                      },
                      icon: const Icon(Icons.shuffle_rounded, size: 17),
                      label: const Text('Acak Data Random'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      final res = state.toggleWaterLevelStatus(device.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res.message)),
                      );
                    },
                    icon: const Icon(Icons.waves_rounded, size: 16),
                    label: Text(
                      device.isWaterLow ? 'Set Air Penuh' : 'Set Mau Habis',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2x2 Metric Grid
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Nutrisi / TDS',
                icon: Icons.water_drop_outlined,
                value: device.online || device.ppm > 0
                    ? AppFormatters.integer(device.ppm)
                    : '—',
                unit: 'ppm',
                progress: (device.ppm / 3000.0).clamp(0.0, 1.0),
                footer:
                    'Target ${AppFormatters.integer(device.limits.targetPpm)} ppm',
                barColor: device.isPpmLow || device.isPpmHigh
                    ? AppColors.orange
                    : AppColors.barFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Suhu larutan',
                icon: Icons.thermostat_outlined,
                value: device.online || device.temp > 0
                    ? AppFormatters.decimal(device.temp)
                    : '—',
                unit: '°C',
                progress: (device.temp / 40.0).clamp(0.0, 1.0),
                footer:
                    'Rentang ${AppFormatters.decimal(device.limits.tempMin, digits: 0)}–${AppFormatters.decimal(device.limits.tempMax, digits: 0)} °C',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Level air',
                icon: Icons.waves_rounded,
                value: device.waterStatusLabel,
                unit: '',
                valueFontSize: 19,
                progress: device.isWaterLow ? 0.18 : 1.0,
                footer: device.isWaterLow
                    ? 'Pelampung: Isi tandon!'
                    : 'Pelampung: Normal / Aman',
                barColor: device.isWaterLow ? AppColors.red : AppColors.barFill,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                label: 'Mode operasi',
                icon: Icons.tune_rounded,
                value: device.mode.label,
                unit: '',
                valueFontSize: 21,
                footer: device.mode == DeviceMode.auto
                    ? 'Mengikuti ambang batas'
                    : 'Kontrol oleh pengguna',
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Chart Panel
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: 'Perjalanan nutrisi',
                subtitle: '12 pembacaan simulasi terakhir · ppm',
                trailing: TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('Lihat riwayat'),
                ),
              ),
              const SizedBox(height: 16),
              SensorLineChart(
                readings: chartRows,
                metric: SensorMetricType.ppm,
                height: 185,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Nutrisi / TDS (ppm)',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Status Aktuator Panel
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: 'Status aktuator',
                trailing: TextButton(
                  onPressed: onOpenControl,
                  child: const Text('Kontrol'),
                ),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < 4; i++) ...[
                _ActuatorStatusRow(
                  name: IoTDevice.actuatorNames[i],
                  subtitle: i < 2 ? 'Pompa peristaltik' : 'Katup solenoid',
                  icon: i < 2 ? Icons.water_drop_outlined : Icons.tune_rounded,
                  active: device.actuators[i],
                  isPump: i < 2,
                  showDivider: i < 3,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Role Info Notice
        NoticeBanner(
          tone: NoticeTone.success,
          icon: Icons.check_rounded,
          text:
              'Anda masuk sebagai ${state.currentUser?.role.label ?? '-'}. ${state.isOwner ? 'Kelola pengguna dan perangkat dari halaman Menu & Perangkat.' : 'Anda dapat memilih semua perangkat, mengontrol aktuator, mengatur ambang batas, dan melakukan kalibrasi TDS.'}',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.unit,
    required this.footer,
    this.progress,
    this.valueFontSize = 27,
    this.barColor = AppColors.barFill,
  });

  final String label;
  final IconData icon;
  final String value;
  final String unit;
  final String footer;
  final double? progress;
  final double valueFontSize;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return KaltaCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.manrope(
                    fontSize: valueFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.barTrack,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ] else
            const SizedBox(height: 17),
          const SizedBox(height: 8),
          Text(
            footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActuatorStatusRow extends StatelessWidget {
  const _ActuatorStatusRow({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.isPump,
    required this.showDivider,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool isPump;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final statusLabel = active
        ? (isPump ? 'Menyala' : 'Terbuka')
        : (isPump ? 'Mati' : 'Tertutup');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEDF1ED))),
            )
          : null,
      child: Row(
        children: [
          SquareIconBadge(icon: icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: statusLabel,
            tone: active ? BadgeTone.mint : BadgeTone.offline,
          ),
        ],
      ),
    );
  }
}
