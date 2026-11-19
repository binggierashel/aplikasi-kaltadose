import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  final _minPpmCtrl = TextEditingController();
  final _maxPpmCtrl = TextEditingController();
  final _targetPpmCtrl = TextEditingController();
  final _tolerancePpmCtrl = TextEditingController();
  final _tempMinCtrl = TextEditingController();
  final _tempMaxCtrl = TextEditingController();
  final _waterMinCtrl = TextEditingController();
  final _waterMaxCtrl = TextEditingController();

  String? _loadedDeviceId;
  String? _error;

  void _syncFromDevice(IoTDevice? device) {
    if (device == null || _loadedDeviceId == device.id) return;
    _loadedDeviceId = device.id;
    final l = device.limits;
    _minPpmCtrl.text = '${l.minPpm}';
    _maxPpmCtrl.text = '${l.maxPpm}';
    _targetPpmCtrl.text = '${l.targetPpm}';
    _tolerancePpmCtrl.text = '${l.tolerancePpm}';
    _tempMinCtrl.text = l.tempMin.toString();
    _tempMaxCtrl.text = l.tempMax.toString();
    _waterMinCtrl.text = '${l.waterMin}';
    _waterMaxCtrl.text = '${l.waterMax}';
    _error = null;
  }

  @override
  void dispose() {
    _minPpmCtrl.dispose();
    _maxPpmCtrl.dispose();
    _targetPpmCtrl.dispose();
    _tolerancePpmCtrl.dispose();
    _tempMinCtrl.dispose();
    _tempMaxCtrl.dispose();
    _waterMinCtrl.dispose();
    _waterMaxCtrl.dispose();
    super.dispose();
  }

  void _save(IoTDevice device) {
    FocusScope.of(context).unfocus();
    final minPpm = int.tryParse(_minPpmCtrl.text.trim());
    final maxPpm = int.tryParse(_maxPpmCtrl.text.trim());
    final targetPpm = int.tryParse(_targetPpmCtrl.text.trim());
    final tolerancePpm = int.tryParse(_tolerancePpmCtrl.text.trim());
    final tempMin = double.tryParse(_tempMinCtrl.text.trim().replaceAll(',', '.'));
    final tempMax = double.tryParse(_tempMaxCtrl.text.trim().replaceAll(',', '.'));
    final waterMin = int.tryParse(_waterMinCtrl.text.trim());
    final waterMax = int.tryParse(_waterMaxCtrl.text.trim());

    if (minPpm == null ||
        maxPpm == null ||
        targetPpm == null ||
        tolerancePpm == null ||
        tempMin == null ||
        tempMax == null ||
        waterMin == null ||
        waterMax == null) {
      setState(() => _error = 'Pastikan seluruh kolom diisi dengan angka yang valid.');
      return;
    }

    final state = AppStateScope.read(context);
    final res = state.saveThresholds(
      device.id,
      SensorLimits(
        minPpm: minPpm,
        maxPpm: maxPpm,
        targetPpm: targetPpm,
        tolerancePpm: tolerancePpm,
        tempMin: tempMin,
        tempMax: tempMax,
        waterMin: waterMin,
        waterMax: waterMax,
      ),
    );
    if (!res.ok) {
      setState(() => _error = res.message);
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;
    _syncFromDevice(device);

    if (device == null) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KaltaPageHeader(
            title: 'Ambang batas',
            subtitle: 'Pengaturan otomatisasi perangkat.',
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

    final locked = !device.online || device.maintenance;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Ambang batas sensor',
          subtitle: 'Owner dan Petani dapat mengubah pengaturan perangkat.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: (id) {
              state.selectDevice(id);
              setState(() => _loadedDeviceId = null);
            },
          ),
        ),
        const SizedBox(height: 16),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!device.online) ...[
                const NoticeBanner(
                  text:
                      'Perangkat offline. Hubungkan kembali sebelum menyimpan pengaturan.',
                  tone: NoticeTone.warning,
                ),
                const SizedBox(height: 18),
              ] else if (device.maintenance) ...[
                const NoticeBanner(
                  text:
                      'Perangkat sedang dalam mode perawatan. Perubahan ambang batas dikunci.',
                  tone: NoticeTone.warning,
                ),
                const SizedBox(height: 18),
              ],

              // Nutrisi / TDS
              Text('Nutrisi / TDS', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Gunakan rentang yang sesuai dengan fase pertumbuhan tanaman melon.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Batas bawah (ppm)',
                controller: _minPpmCtrl,
                enabled: !locked,
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Batas atas (ppm)',
                controller: _maxPpmCtrl,
                enabled: !locked,
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Target nutrisi (ppm)',
                controller: _targetPpmCtrl,
                enabled: !locked,
                hint: 'Target harus berada di antara batas bawah dan atas.',
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Toleransi histeresis (ppm)',
                controller: _tolerancePpmCtrl,
                enabled: !locked,
                hint: 'Pemicu dosing otomatis saat PPM < (target - toleransi).',
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Suhu larutan
              Text('Suhu larutan', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Rentang contoh untuk tampilan; bukan rekomendasi agronomi.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Batas bawah (°C)',
                controller: _tempMinCtrl,
                enabled: !locked,
                decimal: true,
              ),
              const SizedBox(height: 14),
              _NumberField(
                label: 'Batas atas (°C)',
                controller: _tempMaxCtrl,
                enabled: !locked,
                decimal: true,
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Level air tandon (Sensor Pelampung Diskret: Air Penuh / Air Mau Habis)
              Text('Level air tandon', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Sensor pelampung (float switch) hanya memiliki 2 kondisi diskret: Air Penuh dan Air Mau Habis.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Kondisi sensor saat ini:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          device.waterStatusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: device.isWaterLow
                                ? AppColors.red
                                : AppColors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Air Penuh: Pompa nutrisi A/B dan distribusi diizinkan beroperasi.\n'
                      '• Air Mau Habis: Interlock aktif menghentikan pompa dosing dan membuka solenoid pengisian otomatis.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.red),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: locked ? null : () => _save(device),
                      child: const Text('Simpan pengaturan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

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
                'Satu pengaturan,\nuntuk perangkat ini.',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Perubahan hanya berlaku untuk ${device.name}. Owner dan Petani menggunakan pengaturan perangkat yang sama.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const NoticeBanner(
          text:
              'Angka di sini adalah data contoh simulasi lokal. Logika dosing, jeda pencampuran, dan pengaman perangkat pada sistem nyata mengikuti konfigurasi firmware ESP32-S3.',
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    this.decimal = false,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          decoration: InputDecoration(
            fillColor: enabled ? AppColors.white : AppColors.paper,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(hint!, style: theme.textTheme.labelSmall),
        ],
      ],
    );
  }
}
