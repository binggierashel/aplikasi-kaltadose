import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../models/device_model.dart';
import '../state/app_state_scope.dart';

class DeviceFormScreen extends StatefulWidget {
  const DeviceFormScreen({
    super.key,
    this.editingDeviceId,
    required this.onBack,
    required this.onSaved,
  });

  final String? editingDeviceId;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _plantCtrl;
  late final TextEditingController _volumeCtrl;
  bool _initialized = false;
  String? _error;

  IoTDevice? _existing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = AppStateScope.read(context);
      _existing = widget.editingDeviceId != null
          ? state.deviceById(widget.editingDeviceId!)
          : null;
      _nameCtrl = TextEditingController(text: _existing?.name ?? '');
      _idCtrl = TextEditingController(text: _existing?.id ?? '');
      _locationCtrl = TextEditingController(text: _existing?.location ?? '');
      _plantCtrl = TextEditingController(text: _existing?.plantType ?? 'Melon');
      _volumeCtrl = TextEditingController(
        text: '${_existing?.tankVolumeLiters ?? 200}',
      );
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _locationCtrl.dispose();
    _plantCtrl.dispose();
    _volumeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.read(context);
    final vol = int.tryParse(_volumeCtrl.text.trim()) ?? 200;

    final res = _existing != null
        ? state.updateDevice(
            id: _existing!.id,
            name: _nameCtrl.text,
            location: _locationCtrl.text,
            plantType: _plantCtrl.text,
            tankVolumeLiters: vol,
          )
        : state.addDevice(
            id: _idCtrl.text,
            name: _nameCtrl.text,
            location: _locationCtrl.text,
            plantType: _plantCtrl.text,
            tankVolumeLiters: vol,
          );

    if (!res.ok) {
      setState(() => _error = res.message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res.message)),
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaBackLink(label: 'Daftar perangkat', onTap: widget.onBack),
        const SizedBox(height: 10),
        KaltaPageHeader(
          title: isEdit ? 'Edit perangkat' : 'Tambah perangkat',
          subtitle:
              'Daftarkan perangkat agar tersedia untuk Owner dan Petani.',
        ),
        const SizedBox(height: 16),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama perangkat', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Greenhouse Melon 04',
                ),
              ),
              const SizedBox(height: 16),

              Text('ID perangkat', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(
                controller: _idCtrl,
                enabled: !isEdit,
                decoration: InputDecoration(
                  hintText: 'Contoh: ESP32S3-04 atau KALTA-004',
                  fillColor: isEdit ? AppColors.paper : AppColors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Contoh: ESP32S3-04. ID harus unik dan tidak dapat diubah setelah dibuat.',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 16),

              Text('Lokasi perangkat', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Blok D · Kalta Farm',
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Jenis tanaman', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _plantCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Melon',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kapasitas tandon (L)',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 7),
                        TextField(
                          controller: _volumeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '200'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const NoticeBanner(
                text:
                    'Perangkat baru ditampilkan offline sampai menerima telemetri. Status koneksi dapat dicoba melalui halaman Detail perangkat.',
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: AppColors.red),
                ),
              ],

              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onBack,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Simpan perubahan' : 'Tambah perangkat',
                      ),
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
              Text(
                'Sebelum menambahkan',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const KaltaDetailRow(
                label: 'Identitas',
                value: 'ID sesuai firmware perangkat',
              ),
              const KaltaDetailRow(
                label: 'Akses',
                value: 'Tersedia untuk semua pengguna',
              ),
              const KaltaDetailRow(
                label: 'Penugasan Petani',
                value: 'Tidak diperlukan',
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
