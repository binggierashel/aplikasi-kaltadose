import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../state/app_state_scope.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.onNavigate,
  });

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    final items = <_MenuItemData>[
      const _MenuItemData(
        route: 'thresholds',
        icon: Icons.water_drop_outlined,
        title: 'Ambang batas',
        subtitle: 'Atur batas nutrisi/TDS, suhu larutan, dan level air tandon.',
        access: 'Semua peran',
      ),
      const _MenuItemData(
        route: 'maintenance',
        icon: Icons.build_outlined,
        title: 'Perawatan & kalibrasi',
        subtitle: 'Mode perawatan dan status parameter kalibrasi per perangkat.',
        access: 'Semua peran',
      ),
      const _MenuItemData(
        route: 'calibration-tds',
        icon: Icons.science_outlined,
        title: 'Kalibrasi sensor TDS',
        subtitle: 'Panduan fisik, larutan standar, ACK ESP, dan verifikasi.',
        access: 'Semua peran',
      ),
      const _MenuItemData(
        route: 'calibration-history',
        icon: Icons.fact_check_outlined,
        title: 'Riwayat kalibrasi',
        subtitle: 'Pelaksana, parameter lama/baru, konfirmasi ESP, & verifikasi.',
        access: 'Semua peran',
      ),
      const _MenuItemData(
        route: 'notifications',
        icon: Icons.notifications_outlined,
        title: 'Notifikasi',
        subtitle: 'Peringatan sensor di luar batas & perangkat offline.',
        access: 'Semua peran',
      ),
      const _MenuItemData(
        route: 'activity',
        icon: Icons.history_rounded,
        title: 'Riwayat aktivitas',
        subtitle: 'Catatan audit kontrol aktuator, mode, dan pengaturan.',
        access: 'Semua peran',
      ),
      if (state.isOwner) ...[
        const _MenuItemData(
          route: 'users',
          icon: Icons.group_outlined,
          title: 'Kelola pengguna',
          subtitle: 'Daftar, tambah, edit, nonaktifkan, dan hapus akun.',
          access: 'Khusus Owner',
        ),
        const _MenuItemData(
          route: 'device-form',
          icon: Icons.add_box_outlined,
          title: 'Tambah perangkat',
          subtitle: 'Daftarkan node ESP32-S3 baru untuk greenhouse.',
          access: 'Khusus Owner',
        ),
      ],
      const _MenuItemData(
        route: 'profile',
        icon: Icons.person_outline_rounded,
        title: 'Profil & keamanan',
        subtitle: 'Informasi akun, ubah password, pratinjau peran, dan keluar.',
        access: 'Semua peran',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KaltaPageHeader(
          title: 'Menu aplikasi',
          subtitle:
              'Akses seluruh modul Smart Autodosing Kalta Farm sesuai hak akses Anda.',
        ),
        const SizedBox(height: 14),
        const NoticeBanner(
          text:
              'Mode simulasi lokal penuh aktif. Seluruh perubahan disimpan di perangkat dan tidak terhubung ke perangkat fisik maupun server eksternal.',
        ),
        const SizedBox(height: 14),

        for (final item in items) ...[
          InkWell(
            onTap: () => onNavigate(item.route),
            borderRadius: BorderRadius.circular(14),
            child: KaltaCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SquareIconBadge(
                    icon: item.icon,
                    size: 42,
                    iconSize: 21,
                    backgroundColor: AppColors.mint,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.access,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 8),
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pengaturan simulasi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Kembalikan daftar perangkat, riwayat sensor, pengguna, dan status kalibrasi ke data bawaan awal.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await showKaltaConfirmDialog(
                    context: context,
                    title: 'Reset data simulasi?',
                    message:
                        'Semua perubahan lokal (perangkat, ambang batas, pengguna, dan riwayat kalibrasi) akan dikembalikan ke data awal.',
                    confirmLabel: 'Reset data',
                  );
                  if (!ok || !context.mounted) return;
                  await state.resetDemoData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data simulasi dikembalikan ke awal'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset data simulasi awal'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.access,
  });

  final String route;
  final IconData icon;
  final String title;
  final String subtitle;
  final String access;
}
