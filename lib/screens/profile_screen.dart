import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/user_model.dart';
import '../state/app_state_scope.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onRoleSwitched,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onRoleSwitched;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final user = state.currentUser;
    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KaltaPageHeader(
          title: 'Profil saya',
          subtitle: 'Kelola informasi akun dan keamanan Anda.',
        ),
        const SizedBox(height: 16),

        // Profile summary card
        KaltaCard(
          padding: const EdgeInsets.all(26),
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.avatarBg,
                child: Text(
                  AppFormatters.initials(user.name),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              StatusBadge(
                label: user.role.label,
                tone: user.isOwner ? BadgeTone.owner : BadgeTone.mint,
              ),
              const SizedBox(height: 12),
              Text(
                user.isOwner
                    ? 'Pengelola pengguna, perangkat, dan operasional kebun.'
                    : 'Monitoring dan operasional perangkat kebun.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await showKaltaConfirmDialog(
                      context: context,
                      title: 'Keluar dari aplikasi?',
                      message:
                          'Anda dapat masuk lagi menggunakan akun terdaftar. Penguncian mode perawatan yang aktif pada perangkat tetap dipertahankan.',
                      confirmLabel: 'Keluar',
                    );
                    if (ok) state.logout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redBg,
                    foregroundColor: AppColors.red,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 17),
                  label: const Text('Keluar dari aplikasi'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Informasi akun
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: 'Informasi akun',
                trailing: OutlinedButton.icon(
                  onPressed: onEditProfile,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit profil'),
                ),
              ),
              const SizedBox(height: 8),
              KaltaDetailRow(label: 'Nama lengkap', value: user.name),
              KaltaDetailRow(label: 'Username', value: user.username),
              KaltaDetailRow(label: 'Nomor telepon', value: user.phone),
              KaltaDetailRow(label: 'Peran', value: user.role.label),
              const KaltaDetailRow(
                label: 'Status akun',
                value: 'Aktif',
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Keamanan akun
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Keamanan akun', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Gunakan password minimal 8 karakter yang tidak mudah ditebak.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onChangePassword,
                icon: const Icon(Icons.lock_outline_rounded, size: 17),
                label: const Text('Ubah password'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pratinjau peran (simulasi)
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pratinjau peran', style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                'Khusus simulasi lokal: berpindah akun demo untuk membandingkan hak akses Owner dan Petani.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final res = state.previewRole(UserRole.owner);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                        if (res.ok) onRoleSwitched();
                      },
                      child: const Text('Sebagai Owner'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final res = state.previewRole(UserRole.petani);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(res.message)),
                        );
                        if (res.ok) onRoleSwitched();
                      },
                      child: const Text('Sebagai Petani'),
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
