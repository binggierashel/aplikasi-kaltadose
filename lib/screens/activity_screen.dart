import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../state/app_state_scope.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _searchCtrl = TextEditingController();
  String _category = 'Semua';

  static const _categories = [
    'Semua',
    'Kontrol',
    'Mode',
    'Ambang batas',
    'Kalibrasi',
    'Perangkat',
    'Pengguna',
    'Profil',
    'Riwayat',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();

    final rows = state.logs.where((l) {
      if (_category != 'Semua' && l.category != _category) return false;
      if (query.isEmpty) return true;
      return '${l.text} ${l.userName} ${l.category} ${state.deviceNameById(l.deviceId)}'
          .toLowerCase()
          .contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KaltaPageHeader(
          title: 'Riwayat aktivitas',
          subtitle: 'Lihat siapa yang mengubah kontrol dan pengaturan perangkat.',
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Cari nama pengguna, aksi, atau perangkat',
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 19,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final selected = _category == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: selected,
                  selectedColor: AppColors.mint,
                  backgroundColor: AppColors.white,
                  side: BorderSide(
                    color: selected ? AppColors.green : AppColors.line,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.forest : AppColors.muted,
                  ),
                  onSelected: (_) => setState(() => _category = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        KaltaCard(
          child: rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Belum ada aktivitas pada kategori ini.',
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      Builder(
                        builder: (_) {
                          final l = rows[i];
                          final icon = switch (l.category) {
                            'Kontrol' => Icons.tune_rounded,
                            'Mode' => Icons.refresh_rounded,
                            'Kalibrasi' => Icons.build_outlined,
                            'Ambang batas' => Icons.water_drop_outlined,
                            'Pengguna' => Icons.group_outlined,
                            'Perangkat' => Icons.memory_rounded,
                            _ => Icons.history_rounded,
                          };
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: i < rows.length - 1
                                ? const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: AppColors.line),
                                    ),
                                  )
                                : null,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SquareIconBadge(icon: icon),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.text,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${l.userName} · ${l.deviceId == '—' ? 'Sistem' : state.deviceNameById(l.deviceId)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          StatusBadge(
                                            label: l.category,
                                            tone: BadgeTone.offline,
                                          ),
                                          Text(
                                            AppFormatters.dateTimeShort(l.time),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
