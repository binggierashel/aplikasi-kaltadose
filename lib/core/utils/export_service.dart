import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../../models/device_model.dart';
import '../../models/sensor_reading.dart';
import 'formatters.dart';

class ExportPayload {
  const ExportPayload({
    required this.filename,
    required this.savedPath,
    required this.byteSize,
    required this.rowCount,
    required this.csvContent,
    required this.isExcel,
  });

  final String filename;
  final String savedPath;
  final int byteSize;
  final int rowCount;
  final String csvContent;
  final bool isExcel;
}

class ExportService {
  ExportService._();

  static String _escapeCsvCell(Object? value) {
    final text = '${value ?? ''}';
    if (RegExp(r'[";\r\n]').hasMatch(text)) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  static String _escapeXml(Object? value) {
    return '${value ?? ''}'
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static double _excelSerialDate(DateTime dt) {
    final localOffsetMs = dt.timeZoneOffset.inMilliseconds;
    return (dt.millisecondsSinceEpoch + localOffsetMs) / 86400000.0 + 25569.0;
  }

  static String _deviceName(List<IoTDevice> devices, String id) {
    for (final d in devices) {
      if (d.id == id) return d.name;
    }
    return id;
  }

  static String _safeFileSlug(String deviceFilter) {
    if (deviceFilter == 'all') return 'semua-perangkat';
    return deviceFilter.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-');
  }

  static String buildCsvText({
    required List<SensorReading> rows,
    required List<IoTDevice> devices,
  }) {
    final lines = <String>[
      [
        'Waktu',
        'ID perangkat',
        'Nama perangkat',
        'Nutrisi TDS (ppm)',
        'Suhu (°C)',
        'Level air',
      ].map(_escapeCsvCell).join(';'),
      ...rows.map(
        (r) => [
          AppFormatters.timestampExcel(r.time),
          r.deviceId,
          _deviceName(devices, r.deviceId),
          '${r.ppm}',
          r.temp.toStringAsFixed(1).replaceAll('.', ','),
          r.waterStatusLabel,
        ].map(_escapeCsvCell).join(';'),
      ),
    ];
    return lines.join('\r\n');
  }

  static Future<String> _writeBytesToDevice(
    String filename,
    List<int> bytes,
  ) async {
    final candidateDirs = <Directory>[
      Directory('/storage/emulated/0/Download'),
      Directory.systemTemp,
    ];
    for (final dir in candidateDirs) {
      try {
        if (await dir.exists()) {
          final file = File('${dir.path}${Platform.pathSeparator}$filename');
          await file.writeAsBytes(bytes, flush: true);
          return file.path;
        }
      } catch (_) {
        // Fallback to next writable directory
      }
    }
    final fallback =
        File('${Directory.systemTemp.path}${Platform.pathSeparator}$filename');
    await fallback.writeAsBytes(bytes, flush: true);
    return fallback.path;
  }

  /// Generates a UTF-8 BOM semicolon-delimited CSV compatible with Indonesian Excel.
  static Future<ExportPayload> exportCsv({
    required List<SensorReading> rows,
    required List<IoTDevice> devices,
    required String deviceFilter,
  }) async {
    final bodyCsv = buildCsvText(rows: rows, devices: devices);
    final content = '\uFEFFsep=;\r\n$bodyCsv\r\n';
    final bytes = utf8.encode(content);
    final today = AppFormatters.dateIso(DateTime.now());
    final filename =
        'riwayat-sensor-${_safeFileSlug(deviceFilter)}-$today.csv';

    final savedPath = await _writeBytesToDevice(filename, bytes);
    return ExportPayload(
      filename: filename,
      savedPath: savedPath,
      byteSize: bytes.length,
      rowCount: rows.length,
      csvContent: bodyCsv,
      isExcel: false,
    );
  }

  /// Generates a genuine styled `.xlsx` workbook matching `export.js`.
  static Future<ExportPayload> exportXlsx({
    required List<SensorReading> rows,
    required List<IoTDevice> devices,
    required String deviceFilter,
    required String rangeLabel,
    required String actorName,
  }) async {
    final deviceLabel = deviceFilter == 'all'
        ? 'Semua perangkat'
        : _deviceName(devices, deviceFilter);
    final filterText =
        'Perangkat: $deviceLabel · Periode: $rangeLabel · ${rows.length} data simulasi · Diunduh ${AppFormatters.dateTimeShort(DateTime.now())} oleh $actorName';

    final archive = Archive();
    void addXml(String name, String xml) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    addXml(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '</Types>',
    );

    addXml(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
      '</Relationships>',
    );

    addXml(
      'xl/workbook.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheets><sheet name="Riwayat Sensor" sheetId="1" r:id="rId1"/></sheets>'
      '<definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">'
      '\'Riwayat Sensor\'!\$A\$4:\$F\$${4 + rows.length}</definedName></definedNames>'
      '</workbook>',
    );

    addXml(
      'xl/_rels/workbook.xml.rels',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '</Relationships>',
    );

    addXml(
      'xl/styles.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
      '<numFmts count="2">'
      '<numFmt numFmtId="164" formatCode="yyyy-mm-dd hh:mm"/>'
      '<numFmt numFmtId="165" formatCode="0.0"/>'
      '</numFmts>'
      '<fonts count="4">'
      '<font><sz val="11"/><name val="Calibri"/></font>'
      '<font><b/><sz val="14"/><color rgb="FF164F43"/><name val="Calibri"/></font>'
      '<font><i/><sz val="10"/><color rgb="FF5F6B66"/><name val="Calibri"/></font>'
      '<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>'
      '</fonts>'
      '<fills count="3">'
      '<fill><patternFill patternType="none"/></fill>'
      '<fill><patternFill patternType="gray125"/></fill>'
      '<fill><patternFill patternType="solid"><fgColor rgb="FF164F43"/><bgColor indexed="64"/></patternFill></fill>'
      '</fills>'
      '<borders count="2">'
      '<border><left/><right/><top/><bottom/><diagonal/></border>'
      '<border>'
      '<left style="thin"><color rgb="FFD0D7D3"/></left>'
      '<right style="thin"><color rgb="FFD0D7D3"/></right>'
      '<top style="thin"><color rgb="FFD0D7D3"/></top>'
      '<bottom style="thin"><color rgb="FFD0D7D3"/></bottom>'
      '<diagonal/>'
      '</border>'
      '</borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="8">'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
      '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
      '<xf numFmtId="164" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="left" vertical="center"/></xf>'
      '<xf numFmtId="0" fontId="0" fillId="0" borderId="1" xfId="0" applyBorder="1" applyAlignment="1"><alignment vertical="center"/></xf>'
      '<xf numFmtId="1" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
      '<xf numFmtId="165" fontId="0" fillId="0" borderId="1" xfId="0" applyNumberFormat="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center"/></xf>'
      '<xf numFmtId="0" fontId="3" fillId="2" borderId="1" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1"><alignment horizontal="center" vertical="center" wrapText="1"/></xf>'
      '</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>',
    );

    String textCell(String ref, String val, int style) =>
        '<c r="$ref" t="inlineStr" s="$style"><is><t xml:space="preserve">${_escapeXml(val)}</t></is></c>';
    String numCell(String ref, num val, int style) =>
        '<c r="$ref" s="$style"><v>$val</v></c>';

    const headers = [
      'Waktu',
      'ID perangkat',
      'Nama perangkat',
      'Nutrisi TDS (ppm)',
      'Suhu (°C)',
      'Level air',
    ];
    const widths = [19, 15, 26, 19, 12, 16];
    const headerRow = 4;
    final lastRow = headerRow + rows.length;

    final bodyBuf = StringBuffer();
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final n = headerRow + 1 + i;
      bodyBuf.write(
        '<row r="$n">'
        '${numCell('A$n', _excelSerialDate(r.time), 3)}'
        '${textCell('B$n', r.deviceId, 4)}'
        '${textCell('C$n', _deviceName(devices, r.deviceId), 4)}'
        '${numCell('D$n', r.ppm, 5)}'
        '${numCell('E$n', r.temp, 6)}'
        '${textCell('F$n', r.waterStatusLabel, 4)}'
        '</row>',
      );
    }

    final colsXml = [
      for (int i = 0; i < widths.length; i++)
        '<col min="${i + 1}" max="${i + 1}" width="${widths[i]}" customWidth="1"/>',
    ].join();

    final headerCellsXml = [
      for (int i = 0; i < headers.length; i++)
        textCell('${String.fromCharCode(65 + i)}$headerRow', headers[i], 7),
    ].join();

    addXml(
      'xl/worksheets/sheet1.xml',
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
      '<sheetViews><sheetView workbookViewId="0">'
      '<pane ySplit="$headerRow" topLeftCell="A${headerRow + 1}" activePane="bottomLeft" state="frozen"/>'
      '</sheetView></sheetViews>'
      '<sheetFormatPr defaultRowHeight="18"/>'
      '<cols>$colsXml</cols>'
      '<sheetData>'
      '<row r="1" ht="24" customHeight="1">${textCell('A1', 'Riwayat Sensor Kalta Dose', 1)}</row>'
      '<row r="2">${textCell('A2', filterText, 2)}</row>'
      '<row r="$headerRow" ht="22" customHeight="1">$headerCellsXml</row>'
      '${bodyBuf.toString()}'
      '</sheetData>'
      '<autoFilter ref="A$headerRow:F$lastRow"/>'
      '<mergeCells count="2"><mergeCell ref="A1:F1"/><mergeCell ref="A2:F2"/></mergeCells>'
      '<pageMargins left="0.5" right="0.5" top="0.75" bottom="0.75" header="0.3" footer="0.3"/>'
      '</worksheet>',
    );

    final encoded = ZipEncoder().encode(archive);
    final today = AppFormatters.dateIso(DateTime.now());
    final filename =
        'riwayat-sensor-${_safeFileSlug(deviceFilter)}-$today.xlsx';
    final savedPath = await _writeBytesToDevice(filename, encoded);

    return ExportPayload(
      filename: filename,
      savedPath: savedPath,
      byteSize: encoded.length,
      rowCount: rows.length,
      csvContent: buildCsvText(rows: rows, devices: devices),
      isExcel: true,
    );
  }
}
