import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/kalta_card.dart';
import '../state/app_state_scope.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _phoneCtrl;
  bool _initialized = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final u = AppStateScope.read(context).currentUser;
      _nameCtrl = TextEditingController(text: u?.name ?? '');
      _userCtrl = TextEditingController(text: u?.username ?? '');
      _phoneCtrl = TextEditingController(text: u?.phone ?? '');
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.read(context);
    final res = state.updateOwnProfile(
      name: _nameCtrl.text,
      username: _userCtrl.text,
      phone: _phoneCtrl.text,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaBackLink(label: 'Profil saya', onTap: widget.onBack),
        const SizedBox(height: 10),
        const KaltaPageHeader(
          title: 'Edit profil',
          subtitle: 'Perbarui informasi akun pribadi Anda.',
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
              const SizedBox(height: 16),

              Text('Nomor telepon', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
              ),

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
                      child: const Text('Simpan profil'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
