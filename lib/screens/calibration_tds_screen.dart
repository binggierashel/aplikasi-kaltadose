import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../core/widgets/status_badge.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class CalibrationTdsScreen extends StatefulWidget {
  const CalibrationTdsScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<CalibrationTdsScreen> createState() => _CalibrationTdsScreenState();
}

class _CalibrationTdsScreenState extends State<CalibrationTdsScreen> {
  final _referenceCtrl = TextEditingController();
  String _scale = '';
  bool _probeReady = false;
  String? _error;
  String? _syncedDeviceId;

  @override
  void dispose() {
    _referenceCtrl.dispose();
    super.dispose();
  }

  void _syncDraftFields(IoTDevice? device) {
    if (device == null) return;
    if (_syncedDeviceId != device.id) {
      _syncedDeviceId = device.id;
      final candidate = device.calibration.draft?.value ??
          device.calibration.pending?.value;
      if (candidate != null) {
        _referenceCtrl.text = candidate.reference.toString();
        _scale = candidate.scale;
        _probeReady = true;
      } else {
        _referenceCtrl.clear();
        _scale = '';
        _probeReady = false;
      }
      _error = null;
    }
  }

  void _captureSample(IoTDevice device) {
    FocusScope.of(context).unfocus();
    final ref = double.tryParse(_referenceCtrl.text.trim().replaceAll(',', '.'));
    if (ref == null) {
      setState(() => _error = 'Masukkan angka nilai larutan standar yang valid.');
      return;
    }
    final state = AppStateScope.read(context);
    final res = state.captureCalibrationSample(
      deviceId: device.id,
      referencePpm: ref,
      scale: _scale,
      probeReady: _probeReady,
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
    _syncDraftFields(device);

    if (device == null) {
      return const KaltaEmptyState(
        title: 'Belum ada perangkat',
        message: 'Pilih perangkat terlebih dahulu.',
      );
    }

    final cal = device.calibration;
    final guardBlocked = !device.online ||
        !device.maintenance ||
        cal.pending != null ||
        cal.draft != null;
    final theme = Theme.of(context);

    final reqNotice = !device.online
        ? const NoticeBanner(
            text: 'ESP offline. Proses kalibrasi diblokir.',
            tone: NoticeTone.warning,
          )
        : !device.maintenance
            ? const NoticeBanner(
                text:
                    'Aktifkan mode perawatan terlebih dahulu. Pengukuran kalibrasi tidak boleh memicu dosing otomatis.',
                tone: NoticeTone.warning,
              )
            : const NoticeBanner(
                text:
                    'Mode perawatan aktif. Panduan pengukuran dan angka berikut adalah simulasi lokal; lakukan pengukuran fisik saat integrasi perangkat.',
              );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaBackLink(label: 'Perawatan & kalibrasi', onTap: widget.onBack),
        const SizedBox(height: 10),
        KaltaPageHeader(
          title: 'Kalibrasi sensor TDS',
          subtitle:
              'Owner dan Petani dapat melakukan kalibrasi perangkat yang dipilih.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: (id) {
              state.selectDevice(id);
              setState(() => _syncedDeviceId = null);
            },
          ),
        ),
        const SizedBox(height: 16),

        reqNotice,
        const SizedBox(height: 14),

        // Form Card: Siapkan larutan standar
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Siapkan larutan standar', style: theme.textTheme.titleLarge),
              const SizedBox(height: 14),
              const _NumberedStep(
                index: '1.',
                text:
                    'Bersihkan probe sesuai petunjuk produsen dan bilas dengan air deionisasi.',
              ),
              const SizedBox(height: 10),
              const _NumberedStep(
                index: '2.',
                text:
                    'Masukkan probe ke larutan standar yang sesuai sensor. Tunggu suhu dan pembacaan stabil.',
              ),
              const SizedBox(height: 10),
              const _NumberedStep(
                index: '3.',
                text:
                    'Masukkan nilai standar pada skala PPM yang cocok. Jangan gunakan nilai nutrisi tandon sebagai acuan.',
              ),
              const SizedBox(height: 20),

              Text(
                'Nilai larutan standar (ppm)',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _referenceCtrl,
                enabled: !guardBlocked,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: 1000 atau 1413',
                  fillColor: guardBlocked ? AppColors.paper : AppColors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Gunakan nilai pada sertifikat/label standar (0,01–10.000 ppm).',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 16),

              Text(
                'Skala konversi PPM',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: guardBlocked ? AppColors.paper : AppColors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _scale,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: '',
                        child: Text('Pilih sesuai sensor / standar'),
                      ),
                      DropdownMenuItem(value: '500', child: Text('500 (NaCl)')),
                      DropdownMenuItem(value: '700', child: Text('700 (KCl)')),
                    ],
                    onChanged: guardBlocked
                        ? null
                        : (v) => setState(() => _scale = v ?? ''),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Skala dan kompensasi suhu mengikuti sensor yang benar-benar digunakan.',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 14),

              InkWell(
                onTap: guardBlocked
                    ? null
                    : () => setState(() => _probeReady = !_probeReady),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Checkbox(
                          value: _probeReady,
                          activeColor: AppColors.forest,
                          onChanged: guardBlocked
                              ? null
                              : (v) => setState(() => _probeReady = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Probe sudah disiapkan dan pembacaan stabil (konfirmasi pengguna).',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.red),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: guardBlocked ? null : () => _captureSample(device),
                  child: const Text('Ambil pembacaan simulasi'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pembacaan Kalibrasi Card
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pembacaan kalibrasi', style: theme.textTheme.titleLarge),
              const SizedBox(height: 18),
              Text(
                cal.draft != null
                    ? AppFormatters.decimal(cal.draft!.value.observed, digits: 2)
                    : (cal.pending != null
                        ? AppFormatters.decimal(
                            cal.pending!.value.observed,
                            digits: 2,
                          )
                        : '—'),
                style: AppFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ppm · simulasi',
                style: theme.textTheme.bodySmall,
              ),
              if (cal.draft != null || cal.pending != null) ...[
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final v = (cal.draft?.value ?? cal.pending!.value);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'ADC ADS1115 (simulasi): ${AppFormatters.decimal(v.adcMv)} mV · Suhu DS18B20: ${AppFormatters.decimal(v.tempC)} °C · Faktor koreksi: ${v.factor.toStringAsFixed(3)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.ink,
                          height: 1.5,
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Nilai ini bukan pembacaan tandon. Pada perangkat nyata, ESP32-S3 membaca tegangan rata-rata ADS1115 dan suhu DS18B20 sebelum menyimpan faktor ke NVS.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Workflow panel: Draft / Pending / Result
        if (cal.pending != null)
          KaltaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    label: 'Menunggu konfirmasi ESP · Simulasi',
                    tone: BadgeTone.warning,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum dinyatakan tersimpan',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Sensor TDS · ${cal.pending!.requestId}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Nilai aktif belum berubah. Pilih respons ESP di bawah untuk mencoba hasil proses.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    final res = state.settleCalibration(device.id, 'ack');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Simulasikan ESP berhasil'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final res = state.settleCalibration(device.id, 'reject');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redBg,
                    foregroundColor: AppColors.red,
                  ),
                  child: const Text('Simulasikan gagal'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    final res = state.settleCalibration(device.id, 'timeout');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                  },
                  child: const Text('Simulasikan timeout'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Konfirmasi harus sesuai ID perintah dan ID perangkat; tidak boleh dianggap berhasil hanya karena aplikasi mengirim perintah.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          )
        else if (cal.draft != null)
          KaltaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    label: 'Hasil siap dikirim · Simulasi',
                    tone: BadgeTone.mint,
                  ),
                ),
                const SizedBox(height: 14),
                Text('Sensor TDS', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  cal.draft!.value.formattedSummary,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: () {
                    final res = state.sendCalibrationToEsp(device.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                  },
                  icon: const Icon(Icons.memory_rounded, size: 17),
                  label: const Text('Kalibrasi & simpan ke ESP'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    final res = state.discardCalibrationDraft(device.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res.message)),
                    );
                  },
                  child: const Text('Batalkan hasil'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nilai ini belum menjadi parameter aktif sampai ESP memberikan konfirmasi penyimpanan.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          )
        else if (cal.result != null)
          NoticeBanner(
            text: cal.result!.text,
            tone: cal.result!.ok ? NoticeTone.success : NoticeTone.warning,
          ),

        // Verification panel
        if (cal.activeTds != null &&
            cal.pending == null &&
            cal.draft == null) ...[
          const SizedBox(height: 14),
          KaltaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KaltaSectionHead(
                  title: 'Verifikasi sensor TDS',
                  subtitle: 'Versi parameter ${cal.activeTds!.requestId}',
                  trailing: StatusBadge(
                    label: cal.activeTds!.verified
                        ? 'Lulus simulasi'
                        : 'Perlu verifikasi',
                    tone: cal.activeTds!.verified
                        ? BadgeTone.mint
                        : BadgeTone.warning,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pada alat nyata, ukur acuan verifikasi yang sesuai, periksa kestabilan dan toleransi sensor. Tombol berikut mencontohkan hasil pemeriksaan fisik.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: (!device.online || !device.maintenance)
                      ? null
                      : () {
                          final res = state.verifyActiveCalibration(
                            device.id,
                            true,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message)),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
                    foregroundColor: AppColors.forest,
                  ),
                  icon: const Icon(Icons.check_rounded, size: 17),
                  label: const Text('Simulasikan verifikasi lulus'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: (!device.online || !device.maintenance)
                      ? null
                      : () {
                          final res = state.verifyActiveCalibration(
                            device.id,
                            false,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res.message)),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redBg,
                    foregroundColor: AppColors.red,
                  ),
                  child: const Text('Simulasikan verifikasi gagal'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Text(
            index,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
