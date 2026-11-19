import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/confirm_dialog.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/notice_banner.dart';
import '../core/widgets/status_badge.dart';
import '../models/user_model.dart';
import '../state/app_state_scope.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
    required this.onAddUser,
    required this.onEditUser,
  });

  final VoidCallback onAddUser;
  final ValueChanged<int> onEditUser;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();
    final rows = state.users.where((u) {
      if (query.isEmpty) return true;
      return '${u.name} ${u.username}'.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaPageHeader(
          title: 'Kelola pengguna',
          subtitle: 'Kelola akun Owner dan Petani yang menggunakan aplikasi.',
          action: ElevatedButton.icon(
            onPressed: widget.onAddUser,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah pengguna'),
          ),
        ),
        const SizedBox(height: 16),

        // 3 Stat Cards
        _StatCard(label: 'Total pengguna', value: '${state.users.length}'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Owner aktif',
                value: '${state.activeOwnerCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Petani aktif',
                value: '${state.activePetaniCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari nama atau username',
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 19,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (rows.isEmpty)
          const KaltaEmptyState(
            title: 'Pengguna tidak ditemukan',
            message: 'Tidak ada pengguna dengan kata kunci ini.',
            icon: Icons.group_outlined,
          )
        else
          for (final u in rows) ...[
            _UserCard(
              user: u,
              isSelf: u.id == state.currentUser?.id,
              onEdit: () => widget.onEditUser(u.id),
              onDelete: () async {
                if (state.isLastActiveOwner(u)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Owner aktif terakhir tidak dapat dihapus.',
                      ),
                    ),
                  );
                  return;
                }
                final ok = await showKaltaConfirmDialog(
                  context: context,
                  title: 'Hapus pengguna?',
                  message: 'Akun ${u.name} akan dihapus dari daftar pengguna.',
                  confirmLabel: 'Hapus pengguna',
                );
                if (!ok || !context.mounted) return;
                final res = state.deleteUser(u.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res.message)),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

        const SizedBox(height: 4),
        const NoticeBanner(
          text:
              'Owner aktif terakhir tidak dapat dihapus, dinonaktifkan, atau diturunkan perannya. Tidak ada penugasan perangkat kepada Petani.',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return KaltaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.isSelf,
    required this.onEdit,
    required this.onDelete,
  });

  final AppUser user;
  final bool isSelf;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return KaltaCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.avatarBg,
                child: Text(
                  AppFormatters.initials(user.name),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${user.name}${isSelf ? ' (Anda)' : ''}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username} · ${user.phone}',
                      style: const TextStyle(
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
          const Divider(),
          const SizedBox(height: 10),
          Row(
            children: [
              StatusBadge(
                label: user.role.label,
                tone: user.isOwner ? BadgeTone.owner : BadgeTone.mint,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: user.active ? 'Aktif' : 'Nonaktif',
                tone: user.active ? BadgeTone.mint : BadgeTone.offline,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Edit ${user.name}',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppColors.green,
                ),
              ),
              IconButton(
                tooltip: 'Hapus ${user.name}',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
