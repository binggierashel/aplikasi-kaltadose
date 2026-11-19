import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/device_selector.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/user_model.dart';
import '../state/app_state_scope.dart';

class CalibrationHistoryScreen extends StatefulWidget {
  const CalibrationHistoryScreen({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  State<CalibrationHistoryScreen> createState() =>
      _CalibrationHistoryScreenState();
}

class _CalibrationHistoryScreenState extends State<CalibrationHistoryScreen> {
  String _statusFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final device = state.selectedDevice;

    if (device == null) {
      return const KaltaEmptyState(
        title: 'Belum ada perangkat',
        message: 'Pilih perangkat terlebih dahulu.',
      );
    }

    final allRows = device.calibration.history;
    final rows = _statusFilter == 'Semua'
        ? allRows
        : allRows.where((r) => r.status == _statusFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KaltaBackLink(label: 'Perawatan & kalibrasi', onTap: widget.onBack),
        const SizedBox(height: 10),
        KaltaPageHeader(
          title: 'Riwayat kalibrasi',
          subtitle:
              'Jejak parameter lama, perubahan, dan hasil konfirmasi ESP.',
          action: DeviceSelectorRow(
            devices: state.devices,
            selectedId: device.id,
            onChanged: state.selectDevice,
          ),
        ),
        const SizedBox(height: 14),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Semua', 'Tersimpan', 'Ditolak', 'Timeout', 'Dibatalkan']
                .map((status) {
              final selected = _statusFilter == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
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
                  onSelected: (_) => setState(() => _statusFilter = status),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: device.name,
                trailing: StatusBadge(
                  label: '${rows.length} catatan',
                  tone: BadgeTone.offline,
                ),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Belum ada kalibrasi pada perangkat atau filter ini. Mulai dari menu Perawatan & kalibrasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (int i = 0; i < rows.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final r = rows[i];
                      final roleLabel =
                          UserRoleExt.fromCode(r.userRoleCode).label;
                      final statusTone = r.status == 'Tersimpan'
                          ? BadgeTone.mint
                          : r.status == 'Dibatalkan'
                              ? BadgeTone.offline
                              : BadgeTone.warning;
                      final verifText = r.status == 'Tersimpan'
                          ? (r.verified == true
                              ? 'Lulus simulasi'
                              : r.verified == false
                                  ? 'Gagal simulasi'
                                  : 'Belum dilakukan')
                          : 'Tidak berlaku';
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: i < rows.length - 1
                            ? const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.line),
                                ),
                              )
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sensor TDS',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${AppFormatters.dateTimeShort(r.time)} · ${r.userName} ($roleLabel)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: '${r.status} · simulasi',
                                  tone: statusTone,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            KaltaDetailRow(
                              label: 'Parameter sebelumnya',
                              value: r.previous?.formattedSummary ??
                                  'Belum ada parameter tersimpan',
                            ),
                            KaltaDetailRow(
                              label: 'Parameter yang diajukan',
                              value: r.value.formattedSummary,
                            ),
                            KaltaDetailRow(
                              label: 'ID perintah',
                              value: r.requestId,
                            ),
                            KaltaDetailRow(
                              label: 'Verifikasi',
                              value: verifText,
                              showDivider: false,
                            ),
                            if (r.note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                r.note,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
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
