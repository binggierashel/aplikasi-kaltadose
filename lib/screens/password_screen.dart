import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/kalta_card.dart';
import '../state/app_state_scope.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({
    super.key,
    required this.onBack,
    required this.onSaved,
  });

  final VoidCallback onBack;
  final VoidCallback onSaved;

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final state = AppStateScope.read(context);
    final res = state.changeOwnPassword(
      currentPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
      confirmPassword: _confirmCtrl.text,
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
          title: 'Ubah password',
          subtitle: 'Perubahan password tersimpan pada penyimpanan lokal perangkat.',
        ),
        const SizedBox(height: 16),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password saat ini', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(controller: _oldCtrl, obscureText: true),
              const SizedBox(height: 16),

              Text('Password baru', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(controller: _newCtrl, obscureText: true),
              const SizedBox(height: 5),
              Text(
                'Gunakan minimal 8 karakter.',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 16),

              Text('Konfirmasi password baru', style: theme.textTheme.labelLarge),
              const SizedBox(height: 7),
              TextField(controller: _confirmCtrl, obscureText: true),

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
                      child: const Text('Simpan password'),
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
