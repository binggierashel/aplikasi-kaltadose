import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../models/user_model.dart';
import '../state/app_state_scope.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({
    super.key,
    this.editingUserId,
    required this.onBack,
    required this.onSaved,
  });

  final int? editingUserId;
  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passCtrl;
  UserRole _role = UserRole.petani;
  bool _active = true;
  bool _initialized = false;
  AppUser? _existing;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = AppStateScope.read(context);
      if (widget.editingUserId != null) {
        for (final u in state.users) {
          if (u.id == widget.editingUserId) {
            _existing = u;
            break;
          }
        }
      }
      _nameCtrl = TextEditingController(text: _existing?.name ?? '');
      _userCtrl = TextEditingController(text: _existing?.username ?? '');
      _phoneCtrl = TextEditingController(text: _existing?.phone ?? '');
      _passCtrl = TextEditingController();
      _role = _existing?.role ?? UserRole.petani;
      _active = _existing?.active ?? true;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.read(context);
    final res = _existing != null
        ? state.updateUser(
            id: _existing!.id,
            name: _nameCtrl.text,
            username: _userCtrl.text,
            phone: _phoneCtrl.text,
            role: _role,
            active: _active,
          )
        : state.addUser(
            name: _nameCtrl.text,
            username: _userCtrl.text,
            phone: _phoneCtrl.text,
            role: _role,
            active: _active,
            password: _passCtrl.text,
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
        KaltaBackLink(label: 'Kelola pengguna', onTap: widget.onBack),
        const SizedBox(height: 10),
        KaltaPageHeader(
          title: isEdit ? 'Edit pengguna' : 'Tambah pengguna',
          subtitle: 'Tentukan data akun dan hak akses pengguna.',
        ),
        const SizedBox(height: 16),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama lengkap', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(controller: _nameCtrl),
              const SizedBox(height: 16),

              Text('Username', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(controller: _userCtrl, autocorrect: false),
              const SizedBox(height: 5),
              Text(
                'Huruf, angka, titik, garis bawah, atau tanda hubung (3–30 karakter).',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 16),

              Text('Nomor telepon', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              Text('Peran pengguna', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: _role,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.petani,
                        child: Text('Petani'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('Owner'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _role = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text('Status akun', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: _active,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Aktif')),
                      DropdownMenuItem(value: false, child: Text('Nonaktif')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _active = v);
                    },
                  ),
                ),
              ),

              if (!isEdit) ...[
                const SizedBox(height: 16),
                Text('Password awal', style: theme.textTheme.labelLarge),
                const SizedBox(height: 7),
                TextField(controller: _passCtrl, obscureText: true),
                const SizedBox(height: 5),
                Text(
                  'Minimal 8 karakter. Disimpan lokal untuk simulasi.',
                  style: theme.textTheme.labelSmall,
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 12),
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
                      onPressed: widget.onBack,
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(
                        isEdit ? 'Simpan perubahan' : 'Tambah pengguna',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const NoticeBanner(
          text:
              'Owner dapat mengelola pengguna dan perangkat. Petani dapat monitoring, kontrol aktuator, ambang batas, serta kalibrasi TDS. Keduanya memilih perangkat dari daftar yang sama.',
        ),
      ],
    );
  }
}
