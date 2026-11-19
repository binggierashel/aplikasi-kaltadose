import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/export_service.dart';
import '../core/utils/formatters.dart';
import '../core/widgets/kalta_card.dart';
import '../core/widgets/sensor_line_chart.dart';
import '../models/sensor_reading.dart';
import '../state/app_state_scope.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _deviceFilter = 'all';
  SensorMetricType _metric = SensorMetricType.ppm;
  String _range = 'day'; // day | three | all
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _exporting = false;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now().subtract(const Duration(days: 1)))
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _deviceFilter = 'all';
      _range = 'day';
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Future<void> _handleExport({required bool excel}) async {
    final state = AppStateScope.read(context);
    final rows = state.filteredReadings(
      deviceFilter: _deviceFilter,
      range: _range,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diunduh pada filter ini.'),
        ),
      );
      return;
    }

    setState(() => _exporting = true);
    try {
      final rangeLabel = (_dateFrom != null || _dateTo != null)
          ? '${_dateFrom != null ? AppFormatters.dateIso(_dateFrom!) : 'awal'} s.d. ${_dateTo != null ? AppFormatters.dateIso(_dateTo!) : 'akhir'}'
          : (_range == 'day'
              ? '24 jam terakhir'
              : _range == 'three'
                  ? '3 hari terakhir'
                  : 'Semua waktu');

      final payload = excel
          ? await ExportService.exportXlsx(
              rows: rows,
              devices: state.devices,
              deviceFilter: _deviceFilter,
              rangeLabel: rangeLabel,
              actorName: state.currentUser?.name ?? '-',
            )
          : await ExportService.exportCsv(
              rows: rows,
              devices: state.devices,
              deviceFilter: _deviceFilter,
            );

      state.logExport(excel ? 'Excel' : 'CSV', rows.length, _deviceFilter);

      if (mounted) {
        await _showExportDialog(payload);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _showExportDialog(ExportPayload payload) async {
    final previewLines = payload.csvContent.split('\r\n').take(10).join('\n');
    final kb = (payload.byteSize / 1024.0).toStringAsFixed(1);

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x66142C28),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payload.isExcel
                    ? 'File Excel (.xlsx) berhasil dibuat'
                    : 'File CSV berhasil dibuat',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${payload.filename} · ${payload.rowCount} baris ($kb KB)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tersimpan di:\n${payload.savedPath}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Pratinjau data (pemisah ; untuk Excel Indonesia):',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 130),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.line),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    previewLines,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: payload.csvContent),
                        );
                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Data CSV (${payload.rowCount} baris) disalin ke clipboard',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Salin CSV'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final safeDeviceFilter =
        _deviceFilter == 'all' ||
                state.devices.any((d) => d.id == _deviceFilter)
            ? _deviceFilter
            : 'all';

    final rows = state.filteredReadings(
      deviceFilter: safeDeviceFilter,
      range: _range,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    final graphDeviceId = safeDeviceFilter == 'all'
        ? state.selectedDeviceId
        : safeDeviceFilter;
    final graphCandidates =
        rows.where((r) => r.deviceId == graphDeviceId).toList();
    final graphRows = graphCandidates.length > 24
        ? graphCandidates.sublist(graphCandidates.length - 24)
        : graphCandidates;

    final tableRows = rows.reversed.take(60).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KaltaPageHeader(
          title: 'Riwayat sensor',
          subtitle: 'Telusuri pembacaan berdasarkan perangkat dan tanggal.',
        ),
        const SizedBox(height: 14),

        // Device filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeDeviceFilter,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('Semua perangkat'),
                ),
                ...state.devices.map(
                  (d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _deviceFilter = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Date filters
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: true),
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: Text(
                  _dateFrom != null
                      ? AppFormatters.dateIso(_dateFrom!)
                      : 'Dari tanggal',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: false),
                icon: const Icon(Icons.calendar_today_outlined, size: 15),
                label: Text(
                  _dateTo != null
                      ? AppFormatters.dateIso(_dateTo!)
                      : 'Sampai tanggal',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset filter'),
          ),
        ),
        const SizedBox(height: 6),

        // Chart card
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: 'Grafik pembacaan',
                subtitle:
                    '${state.deviceNameById(graphDeviceId)} · ${_metric.unit}',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<SensorMetricType>(
                          value: _metric,
                          isExpanded: true,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                          items: SensorMetricType.values
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.label),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _metric = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _range,
                          isExpanded: true,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                          items: const [
                            DropdownMenuItem(value: 'day', child: Text('24 jam')),
                            DropdownMenuItem(
                              value: 'three',
                              child: Text('3 hari'),
                            ),
                            DropdownMenuItem(value: 'all', child: Text('Semua')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _range = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SensorLineChart(
                readings: graphRows,
                metric: _metric,
                height: 190,
              ),
              const SizedBox(height: 10),
              Text(
                'Grafik menampilkan maksimal 24 pembacaan dari satu perangkat. Data di bawah mengikuti seluruh filter.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Data pembacaan + Export buttons
        KaltaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KaltaSectionHead(
                title: 'Data pembacaan',
                subtitle: '${rows.length} data simulasi',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_exporting || rows.isEmpty)
                          ? null
                          : () => _handleExport(excel: true),
                      icon: const Icon(Icons.download_rounded, size: 17),
                      label: Text(_exporting ? 'Menyiapkan...' : 'Unduh Excel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: (_exporting || rows.isEmpty)
                        ? null
                        : () => _handleExport(excel: false),
                    icon: const Icon(Icons.download_rounded, size: 17),
                    label: const Text('CSV'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (tableRows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      'Tidak ada data pada filter ini. Coba rentang tanggal lain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ),
                )
              else
                for (final r in tableRows) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                state.deviceNameById(r.deviceId),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              AppFormatters.dateTimeShort(r.time),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ReadingChip(
                              label: 'Nutrisi',
                              value: '${AppFormatters.integer(r.ppm)} ppm',
                            ),
                            const SizedBox(width: 8),
                            _ReadingChip(
                              label: 'Suhu',
                              value: '${AppFormatters.decimal(r.temp)} °C',
                            ),
                            const SizedBox(width: 8),
                            _ReadingChip(
                              label: 'Level air',
                              value: r.waterStatusLabel,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              if (rows.length > 60)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Menampilkan 60 pembacaan terbaru. Unduh Excel/CSV untuk mendapatkan seluruh ${rows.length} baris hasil filter.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadingChip extends StatelessWidget {
  const _ReadingChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
