import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/utils/formatters.dart';
import '../models/activity_log.dart';
import '../models/calibration_model.dart';
import '../models/device_model.dart';
import '../models/notification_item.dart';
import '../models/sensor_reading.dart';
import '../models/user_model.dart';

class ActionResult {
  const ActionResult.ok([this.message = '']) : ok = true;
  const ActionResult.err(this.message) : ok = false;

  final bool ok;
  final String message;
}

class AppState extends ChangeNotifier {
  static const String _storageFileName = 'kalta_dose_state_v2.json';
  static const Duration _inactivityTimeout = Duration(minutes: 30);
  static bool disableDiskPersistenceForTests = false;

  File get _stateFile => File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$_storageFileName',
      );

  List<AppUser> _users = [];
  List<IoTDevice> _devices = [];
  List<SensorReading> _readings = [];
  List<AppNotification> _notifications = [];
  List<ActivityLog> _logs = [];

  int? _currentUserId;
  String _selectedDeviceId = '';
  int _commandSequence = 0;
  int _nextNotificationId = 10;
  int _manualDurationSeconds = 10;
  bool _liveSimulationEnabled = false;
  bool _initialized = false;
  String? _sessionExpiredBanner;

  Timer? _telemetryTimer;
  Timer? _inactivityTimer;
  final math.Random _rng = math.Random();

  // Getters
  bool get initialized => _initialized;
  List<AppUser> get users => List.unmodifiable(_users);
  List<IoTDevice> get devices => List.unmodifiable(_devices);
  List<SensorReading> get readings => List.unmodifiable(_readings);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<ActivityLog> get logs => List.unmodifiable(_logs);

  AppUser? get currentUser {
    if (_currentUserId == null) return null;
    for (final u in _users) {
      if (u.id == _currentUserId) return u;
    }
    return null;
  }

  bool get isLoggedIn => currentUser != null;
  bool get isOwner => currentUser?.isOwner ?? false;
  String get selectedDeviceId => _selectedDeviceId;
  int get manualDurationSeconds => _manualDurationSeconds;
  bool get liveSimulationEnabled => _liveSimulationEnabled;
  String? get sessionExpiredBanner => _sessionExpiredBanner;

  IoTDevice? get selectedDevice {
    if (_devices.isEmpty) return null;
    for (final d in _devices) {
      if (d.id == _selectedDeviceId) return d;
    }
    return _devices.first;
  }

  IoTDevice? deviceById(String id) {
    for (final d in _devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  String deviceNameById(String id) => deviceById(id)?.name ?? id;

  List<IoTDevice> get maintenanceDevices =>
      _devices.where((d) => d.maintenance).toList();

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;

  int get activeOwnerCount =>
      _users.where((u) => u.active && u.role == UserRole.owner).length;

  int get activePetaniCount =>
      _users.where((u) => u.active && u.role == UserRole.petani).length;

  bool isLastActiveOwner(AppUser user) =>
      user.active && user.role == UserRole.owner && activeOwnerCount <= 1;

  // Initialization & Persistence
  Future<void> init() async {
    try {
      if (!disableDiskPersistenceForTests && await _stateFile.exists()) {
        final raw = await _stateFile.readAsString();
        if (raw.isNotEmpty) {
          _restoreFromJson(jsonDecode(raw) as Map<String, dynamic>);
        } else {
          _seedDefaults();
        }
      } else {
        _seedDefaults();
      }
    } catch (_) {
      _seedDefaults();
    }
    _initialized = true;
    notifyListeners();
  }

  void _seedDefaults() {
    final now = DateTime.now();
    _users = const [
      AppUser(
        id: 1,
        name: 'Pemilik Kalta Farm',
        username: 'owner',
        role: UserRole.owner,
        active: true,
        phone: '0812 3456 7890',
        password: 'owner123',
      ),
      AppUser(
        id: 2,
        name: 'Petani Kalta Farm',
        username: 'petani',
        role: UserRole.petani,
        active: true,
        phone: '0813 9876 5432',
        password: 'petani123',
      ),
      AppUser(
        id: 3,
        name: 'Dewi Lestari',
        username: 'dewi',
        role: UserRole.petani,
        active: true,
        phone: '0812 1111 2222',
        password: 'demo12345',
      ),
      AppUser(
        id: 4,
        name: 'Ahmad Fauzi',
        username: 'ahmad',
        role: UserRole.petani,
        active: false,
        phone: '0812 3333 4444',
        password: 'demo12345',
      ),
    ];

    _devices = [
      IoTDevice(
        id: 'ESP32S3-01',
        name: 'Greenhouse Melon 01',
        location: 'Blok A · Kalta Farm',
        online: true,
        ppm: 1985,
        temp: 26.5,
        water: 100, // Air Penuh
        firmware: 'v1.0.0',
        lastUpdate: now.subtract(const Duration(seconds: 12)),
        mode: DeviceMode.auto,
        actuators: const [false, false, false, false],
        limits: SensorLimits.defaults(),
        maintenance: false,
        calibration: const DeviceCalibration(),
        plantType: 'Melon Inthanon',
        tankVolumeLiters: 250,
      ),
      IoTDevice(
        id: 'ESP32S3-02',
        name: 'Greenhouse Melon 02',
        location: 'Blok B · Kalta Farm',
        online: true,
        ppm: 1920,
        temp: 26.2,
        water: 100, // Air Penuh
        firmware: 'v1.0.0',
        lastUpdate: now.subtract(const Duration(seconds: 18)),
        mode: DeviceMode.auto,
        actuators: const [false, false, false, false],
        limits: SensorLimits.defaults(),
        maintenance: false,
        calibration: const DeviceCalibration(),
        plantType: 'Melon Golden',
        tankVolumeLiters: 200,
      ),
      IoTDevice(
        id: 'ESP32S3-03',
        name: 'Pembibitan Melon',
        location: 'Blok C · Kalta Farm',
        online: false,
        ppm: 1850,
        temp: 25.9,
        water: 0, // Air Mau Habis
        firmware: 'v1.0.0',
        lastUpdate: now.subtract(const Duration(hours: 1)),
        mode: DeviceMode.auto,
        actuators: const [false, false, false, false],
        limits: SensorLimits.defaults(),
        maintenance: false,
        calibration: const DeviceCalibration(),
        plantType: 'Bibit Melon',
        tankVolumeLiters: 120,
      ),
    ];

    _selectedDeviceId = _devices.first.id;
    _readings = [];
    for (int di = 0; di < _devices.length; di++) {
      final d = _devices[di];
      for (int i = 0; i < 72; i++) {
        final t = now.subtract(Duration(hours: 71 - i));
        final ppmVal = (d.ppm + math.sin(i * 0.7 + di) * 72).round();
        final tempVal = double.parse(
          (26.5 + math.sin(i * 0.3 + di) * 1.1).toStringAsFixed(1),
        );
        final waterVal = (i % 19 == 0) ? 0 : 100;
        _readings.add(
          SensorReading(
            deviceId: d.id,
            time: t,
            ppm: ppmVal,
            temp: tempVal,
            water: waterVal,
          ),
        );
      }
    }

    _logs = [
      ActivityLog(
        time: now.subtract(const Duration(minutes: 2)),
        deviceId: 'ESP32S3-01',
        userName: 'Pemilik Kalta Farm',
        category: 'Mode',
        text: 'Mode otomatis diaktifkan',
      ),
      ActivityLog(
        time: now.subtract(const Duration(minutes: 15)),
        deviceId: 'ESP32S3-02',
        userName: 'Petani Kalta Farm',
        category: 'Ambang batas',
        text: 'Target nutrisi diubah menjadi 2.000 ppm',
      ),
      ActivityLog(
        time: now.subtract(const Duration(minutes: 30)),
        deviceId: 'ESP32S3-01',
        userName: 'Petani Kalta Farm',
        category: 'Kontrol',
        text: 'Pompa nutrisi A dimatikan',
      ),
    ];

    _notifications = [
      AppNotification(
        id: 1,
        deviceId: 'ESP32S3-03',
        title: 'Perangkat tidak terhubung',
        text:
            'Pembibitan Melon tidak mengirim data. Periksa daya dan koneksi jaringan.',
        time: now.subtract(const Duration(hours: 1)),
        read: false,
        type: NotificationType.offline,
        severity: NotificationSeverity.critical,
      ),
      AppNotification(
        id: 2,
        deviceId: 'ESP32S3-02',
        title: 'Nutrisi sempat di bawah batas',
        text:
            'Greenhouse Melon 02: pembacaan 1.750 ppm, di bawah batas 1.800 ppm. Ini contoh peringatan historis.',
        time: now.subtract(const Duration(hours: 2)),
        read: false,
        type: NotificationType.sensor,
        severity: NotificationSeverity.warning,
      ),
      AppNotification(
        id: 3,
        deviceId: 'ESP32S3-01',
        title: 'Level air kembali normal',
        text:
            'Greenhouse Melon 01: level air kembali ke rentang pengaturan.',
        time: now.subtract(const Duration(hours: 4)),
        read: true,
        type: NotificationType.sensor,
        severity: NotificationSeverity.info,
      ),
    ];

    _commandSequence = 0;
    _nextNotificationId = 10;
    _currentUserId = null;
  }

  void _restoreFromJson(Map<String, dynamic> data) {
    _users = (data['users'] as List<dynamic>)
        .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
        .toList();
    _devices = (data['devices'] as List<dynamic>)
        .map((e) => IoTDevice.fromJson(e as Map<String, dynamic>))
        .toList();
    _readings = (data['readings'] as List<dynamic>)
        .map((e) => SensorReading.fromJson(e as Map<String, dynamic>))
        .toList();
    _notifications = (data['notifications'] as List<dynamic>)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
    _logs = (data['logs'] as List<dynamic>)
        .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
        .toList();
    _selectedDeviceId =
        (data['selectedDeviceId'] as String?) ??
        (_devices.isNotEmpty ? _devices.first.id : '');
    _commandSequence = (data['commandSequence'] as num?)?.toInt() ?? 0;
    _nextNotificationId = (data['nextNotificationId'] as num?)?.toInt() ?? 10;
    _currentUserId = (data['currentUserId'] as num?)?.toInt();

    if (_users.isEmpty) {
      _seedDefaults();
    } else if (_currentUserId != null && currentUser == null) {
      _currentUserId = null;
    }
    if (_currentUserId != null) {
      _resetInactivityTimer();
    }
  }

  Future<void> _persist() async {
    if (disableDiskPersistenceForTests) return;
    try {
      final payload = jsonEncode({
        'users': _users.map((e) => e.toJson()).toList(),
        'devices': _devices.map((e) => e.toJson()).toList(),
        'readings': _readings.length > 360
            ? _readings
                .sublist(_readings.length - 360)
                .map((e) => e.toJson())
                .toList()
            : _readings.map((e) => e.toJson()).toList(),
        'notifications': _notifications.map((e) => e.toJson()).toList(),
        'logs': _logs.take(150).map((e) => e.toJson()).toList(),
        'selectedDeviceId': _selectedDeviceId,
        'commandSequence': _commandSequence,
        'nextNotificationId': _nextNotificationId,
        'currentUserId': _currentUserId,
      });
      await _stateFile.writeAsString(payload, flush: true);
    } catch (_) {
      // Safe fallback in restricted environments
    }
  }

  Future<void> resetDemoData() async {
    final currentRole = currentUser?.role;
    stopLiveSimulation();
    _seedDefaults();
    if (currentRole != null) {
      final match = _users.where((u) => u.role == currentRole && u.active);
      if (match.isNotEmpty) {
        _currentUserId = match.first.id;
      }
    }
    await _persist();
    notifyListeners();
  }

  void _record(String category, String text, [String? deviceId]) {
    _logs.insert(
      0,
      ActivityLog(
        time: DateTime.now(),
        deviceId: deviceId ?? _selectedDeviceId,
        userName: currentUser?.name ?? 'Sistem',
        category: category,
        text: text,
      ),
    );
  }

  void _pushNotification({
    required String deviceId,
    required String title,
    required String text,
    required NotificationType type,
    required NotificationSeverity severity,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: ++_nextNotificationId,
        deviceId: deviceId,
        title: title,
        text: text,
        time: DateTime.now(),
        read: false,
        type: type,
        severity: severity,
      ),
    );
  }

  void _replaceDevice(IoTDevice updated) {
    final idx = _devices.indexWhere((d) => d.id == updated.id);
    if (idx != -1) {
      _devices[idx] = updated;
    }
  }

  // Inactivity auto-logout (SKPL 5.2: 30 minutes)
  void recordUserInteraction() {
    if (!isLoggedIn) return;
    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (isLoggedIn) {
        _sessionExpiredBanner =
            'Sesi berakhir otomatis setelah 30 menit tidak aktif. Silakan masuk kembali.';
        logout();
      }
    });
  }

  void clearSessionExpiredBanner() {
    if (_sessionExpiredBanner != null) {
      _sessionExpiredBanner = null;
      notifyListeners();
    }
  }

  // KF-01: Authentication
  ActionResult login(String username, String password) {
    final trimmedUser = username.trim();
    if (trimmedUser.isEmpty || password.isEmpty) {
      return const ActionResult.err('Username dan password wajib diisi.');
    }
    final candidates = _users.where(
      (u) => u.username.toLowerCase() == trimmedUser.toLowerCase(),
    );
    if (candidates.isEmpty || candidates.first.password != password) {
      return const ActionResult.err(
        'Username atau password salah, atau akun tidak aktif.',
      );
    }
    final user = candidates.first;
    if (!user.active) {
      return const ActionResult.err(
        'Akun Anda nonaktif. Hubungi Owner untuk mengaktifkan kembali akun.',
      );
    }
    _currentUserId = user.id;
    _sessionExpiredBanner = null;
    _resetInactivityTimer();
    _persist();
    notifyListeners();
    return ActionResult.ok('Selamat datang, ${user.name}');
  }

  void logout() {
    _inactivityTimer?.cancel();
    stopLiveSimulation();
    _currentUserId = null;
    // Note per SKPL KF-12 & B06: logout does NOT cancel device maintenance locks!
    _persist();
    notifyListeners();
  }

  ActionResult previewRole(UserRole role) {
    final preferredUsername = role.code;
    final exact = _users.where(
      (u) => u.username == preferredUsername && u.active && u.role == role,
    );
    final fallback = _users.where((u) => u.active && u.role == role);
    final target = exact.isNotEmpty
        ? exact.first
        : (fallback.isNotEmpty ? fallback.first : null);
    if (target == null) {
      return const ActionResult.err('Tidak ada akun aktif untuk peran ini.');
    }
    _currentUserId = target.id;
    _resetInactivityTimer();
    _persist();
    notifyListeners();
    return ActionResult.ok('Pratinjau sebagai ${role.label}');
  }

  // KF-03: Device Selection
  void selectDevice(String id) {
    if (_devices.any((d) => d.id == id)) {
      _selectedDeviceId = id;
      _persist();
      notifyListeners();
    }
  }

  // KF-04: Device Management (Owner only)
  ActionResult addDevice({
    required String id,
    required String name,
    required String location,
    required String plantType,
    required int tankVolumeLiters,
  }) {
    if (!isOwner) {
      return const ActionResult.err('Fitur ini hanya untuk Owner.');
    }
    final cleanId = id.trim();
    final cleanName = name.trim();
    final cleanLoc = location.trim();
    final cleanPlant = plantType.trim().isEmpty ? 'Melon' : plantType.trim();

    if (cleanName.isEmpty || cleanLoc.isEmpty) {
      return const ActionResult.err('Nama dan lokasi tidak boleh kosong.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]{3,40}$').hasMatch(cleanId)) {
      return const ActionResult.err(
        'ID perangkat minimal 3 karakter (huruf, angka, tanda hubung, garis bawah).',
      );
    }
    if (_devices.any((d) => d.id.toLowerCase() == cleanId.toLowerCase())) {
      return const ActionResult.err(
        'ID perangkat sudah digunakan. Gunakan ID yang berbeda.',
      );
    }

    final newDevice = IoTDevice(
      id: cleanId,
      name: cleanName,
      location: cleanLoc,
      online: false,
      ppm: 0,
      temp: 0,
      water: 0,
      firmware: 'v1.0.0',
      lastUpdate: DateTime.now(),
      mode: DeviceMode.auto,
      actuators: const [false, false, false, false],
      limits: SensorLimits.defaults(),
      maintenance: false,
      calibration: const DeviceCalibration(),
      plantType: cleanPlant,
      tankVolumeLiters: tankVolumeLiters > 0 ? tankVolumeLiters : 200,
    );
    _devices.add(newDevice);
    if (_selectedDeviceId.isEmpty) {
      _selectedDeviceId = newDevice.id;
    }
    _record('Perangkat', 'Menambahkan perangkat $cleanName', newDevice.id);
    _persist();
    notifyListeners();
    return const ActionResult.ok('Perangkat simulasi disimpan');
  }

  ActionResult updateDevice({
    required String id,
    required String name,
    required String location,
    required String plantType,
    required int tankVolumeLiters,
  }) {
    if (!isOwner) {
      return const ActionResult.err('Fitur ini hanya untuk Owner.');
    }
    final existing = deviceById(id);
    if (existing == null) {
      return const ActionResult.err('Perangkat tidak ditemukan.');
    }
    final cleanName = name.trim();
    final cleanLoc = location.trim();
    if (cleanName.isEmpty || cleanLoc.isEmpty) {
      return const ActionResult.err('Nama dan lokasi tidak boleh kosong.');
    }
    final updated = existing.copyWith(
      name: cleanName,
      location: cleanLoc,
      plantType: plantType.trim().isEmpty ? 'Melon' : plantType.trim(),
      tankVolumeLiters:
          tankVolumeLiters > 0 ? tankVolumeLiters : existing.tankVolumeLiters,
    );
    _replaceDevice(updated);
    _record('Perangkat', 'Memperbarui informasi ${updated.name}', updated.id);
    _persist();
    notifyListeners();
    return const ActionResult.ok('Perangkat simulasi disimpan');
  }

  ActionResult deleteDevice(String id) {
    if (!isOwner) {
      return const ActionResult.err('Fitur ini hanya untuk Owner.');
    }
    final existing = deviceById(id);
    if (existing == null) {
      return const ActionResult.err('Perangkat tidak ditemukan.');
    }
    if (existing.maintenance) {
      return const ActionResult.err(
        'Selesaikan mode perawatan sebelum menghapus perangkat.',
      );
    }
    _record('Perangkat', 'Menghapus perangkat ${existing.name}', existing.id);
    _devices.removeWhere((d) => d.id == id);
    _readings.removeWhere((r) => r.deviceId == id);
    _notifications.removeWhere((n) => n.deviceId == id);
    if (_selectedDeviceId == id) {
      _selectedDeviceId = _devices.isNotEmpty ? _devices.first.id : '';
    }
    _persist();
    notifyListeners();
    return const ActionResult.ok('Perangkat dihapus');
  }

  // Connection simulation (Detail Perangkat)
  ActionResult toggleDeviceOnline(String id) {
    final dev = deviceById(id);
    if (dev == null) {
      return const ActionResult.err('Perangkat tidak ditemukan.');
    }
    final nextOnline = !dev.online;
    var updated = dev.copyWith(
      online: nextOnline,
      actuators: const [false, false, false, false],
      lastUpdate: nextOnline ? DateTime.now() : dev.lastUpdate,
      ppm: nextOnline && dev.ppm == 0 ? 1900 : dev.ppm,
      temp: nextOnline && dev.temp == 0 ? 26.2 : dev.temp,
      water: nextOnline && dev.water == 0 ? 70 : dev.water,
    );

    // Per calibration.js: going offline clears draft and settles pending as timeout
    if (!nextOnline) {
      var cal = updated.calibration.copyWith(clearDraft: true);
      if (cal.pending != null) {
        final pending = cal.pending!;
        final entry = CalibrationRecord(
          time: DateTime.now(),
          requestId: pending.requestId,
          status: 'Timeout',
          value: pending.value,
          previous: pending.previous,
          userName: pending.userName,
          userRoleCode: pending.userRoleCode,
          note:
              'Koneksi perangkat terputus saat menunggu konfirmasi; status perangkat perlu diperiksa ulang. Parameter terakhir yang dikonfirmasi tetap ditampilkan.',
        );
        cal = cal.copyWith(
          clearPending: true,
          history: [entry, ...cal.history],
          result: CalibrationBannerResult(ok: false, text: entry.note),
        );
      }
      updated = updated.copyWith(calibration: cal);
      _pushNotification(
        deviceId: updated.id,
        title: 'Perangkat tidak terhubung',
        text:
            '${updated.name} terputus dalam simulasi. Kontrol dan perubahan pengaturan dinonaktifkan.',
        type: NotificationType.offline,
        severity: NotificationSeverity.critical,
      );
    }

    _replaceDevice(updated);
    _record(
      'Perangkat',
      'Koneksi disimulasikan ${nextOnline ? 'online' : 'offline'}',
      updated.id,
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Status koneksi simulasi diperbarui');
  }

  // KF-05: Mode & Actuator Controls
  void setManualDurationSeconds(int seconds) {
    _manualDurationSeconds = seconds;
    notifyListeners();
  }

  ActionResult changeDeviceMode(String id, DeviceMode nextMode) {
    final dev = deviceById(id);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    if (!dev.online) {
      return const ActionResult.err(
        'Perangkat offline. Mode tidak dapat diubah.',
      );
    }
    if (dev.maintenance) {
      return const ActionResult.err(
        'Perangkat sedang dalam mode perawatan. Perpindahan mode dikunci.',
      );
    }
    if (dev.mode == nextMode) {
      return const ActionResult.ok();
    }
    final updated = dev.copyWith(
      mode: nextMode,
      actuators: const [false, false, false, false],
      lastAckText:
          'ACK ESP (${AppFormatters.timeHm(DateTime.now())}): Mode ${nextMode.label} aktif, seluruh aktuator dimatikan.',
    );
    _replaceDevice(updated);
    _record(
      'Mode',
      'Mode ${nextMode == DeviceMode.auto ? 'otomatis' : 'manual'} diaktifkan',
      updated.id,
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Mode diperbarui dalam simulasi');
  }

  ActionResult toggleActuator(String id, int index) {
    final dev = deviceById(id);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    if (!dev.online) {
      return const ActionResult.err(
        'Perangkat offline. Kontrol tidak dapat dikirim.',
      );
    }
    if (dev.maintenance) {
      return const ActionResult.err(
        'Perangkat sedang dalam mode perawatan. Kontrol manual dikunci.',
      );
    }
    if (dev.mode != DeviceMode.manual) {
      return const ActionResult.err(
        'Kontrol manual dikunci saat mode otomatis. Pilih mode Manual terlebih dahulu.',
      );
    }
    if (index < 0 || index >= 4) {
      return const ActionResult.err('Aktuator tidak valid.');
    }

    final turningOn = !dev.actuators[index];
    // Water-level safety interlock (DPPL KF-05): block Pompa A/B & Solenoid distribusi if water low
    if (turningOn && dev.isWaterLow && index != 2) {
      return const ActionResult.err(
        'Kontrol ditolak (Interlock): Level air tandon rendah! Buka Solenoid pengisian terlebih dahulu.',
      );
    }

    final nextActuators = List<bool>.from(dev.actuators);
    nextActuators[index] = turningOn;
    final verb = index < 2
        ? (turningOn ? 'dinyalakan' : 'dimatikan')
        : (turningOn ? 'dibuka' : 'ditutup');
    final durationHint =
        turningOn ? ' (batas aman ${_manualDurationSeconds}d)' : '';

    final updated = dev.copyWith(
      actuators: nextActuators,
      lastAckText:
          'ACK ESP (${AppFormatters.timeHm(DateTime.now())}): ${IoTDevice.actuatorNames[index]} $verb$durationHint.',
    );
    _replaceDevice(updated);
    _record(
      'Kontrol',
      '${IoTDevice.actuatorNames[index]} $verb$durationHint',
      updated.id,
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Status aktuator simulasi diperbarui');
  }

  // KF-06: Thresholds / Setpoints
  ActionResult saveThresholds(String id, SensorLimits limits) {
    final dev = deviceById(id);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    if (!dev.online) {
      return const ActionResult.err(
        'Perangkat offline. Hubungkan kembali sebelum menyimpan pengaturan.',
      );
    }
    if (dev.maintenance) {
      return const ActionResult.err(
        'Perangkat sedang dalam mode perawatan. Perubahan ambang batas dikunci.',
      );
    }
    if (limits.minPpm < 0 ||
        limits.maxPpm > 5000 ||
        limits.minPpm >= limits.maxPpm ||
        limits.targetPpm < limits.minPpm ||
        limits.targetPpm > limits.maxPpm) {
      return const ActionResult.err(
        'Periksa rentang nutrisi: batas bawah < batas atas dan target harus di dalam rentang.',
      );
    }
    if (limits.tolerancePpm < 1 || limits.tolerancePpm > 500) {
      return const ActionResult.err(
        'Toleransi histeresis harus antara 1 sampai 500 ppm.',
      );
    }
    if (limits.tempMin < 0 ||
        limits.tempMax > 60 ||
        limits.tempMin >= limits.tempMax) {
      return const ActionResult.err(
        'Periksa rentang suhu: batas bawah harus lebih kecil dari batas atas (0–60 °C).',
      );
    }
    if (limits.waterMin < 0 ||
        limits.waterMax > 100 ||
        limits.waterMin >= limits.waterMax) {
      return const ActionResult.err(
        'Periksa level air: batas pengisian harus lebih rendah dari batas berhenti mengisi (0–100%).',
      );
    }

    final updated = dev.copyWith(limits: limits);
    _replaceDevice(updated);
    _record(
      'Ambang batas',
      'Mengubah pengaturan sensor; target nutrisi ${AppFormatters.integer(limits.targetPpm)} ppm',
      updated.id,
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Pengaturan simulasi disimpan');
  }

  // KF-07 & KF-08: Maintenance & TDS Calibration
  ActionResult enterMaintenance(String id) {
    final dev = deviceById(id);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    if (!dev.online) {
      return const ActionResult.err(
        'Perangkat offline. Mode perawatan tidak dapat dikonfirmasi.',
      );
    }
    if (dev.maintenance) return const ActionResult.ok();

    final updated = dev.copyWith(
      maintenance: true,
      actuators: const [false, false, false, false],
      calibration: dev.calibration.copyWith(clearResult: true),
    );
    _replaceDevice(updated);
    _record('Kalibrasi', 'Memulai perawatan perangkat (simulasi)', updated.id);
    _persist();
    notifyListeners();
    return const ActionResult.ok('Mode perawatan aktif; seluruh aktuator dimatikan');
  }

  ActionResult exitMaintenance(String id) {
    final dev = deviceById(id);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    if (!dev.online) {
      return const ActionResult.err(
        'Perangkat offline. Penyelesaian perawatan tidak dapat dikonfirmasi.',
      );
    }
    if (!dev.maintenance) return const ActionResult.ok();
    if (dev.calibration.pending != null || dev.calibration.draft != null) {
      return const ActionResult.err(
        'Selesaikan atau batalkan draf/perintah kalibrasi yang masih tertunda terlebih dahulu.',
      );
    }
    final active = dev.calibration.activeTds;
    if (active != null && !active.verified) {
      return const ActionResult.err(
        'Verifikasi parameter aktif terlebih dahulu; jika gagal, lakukan kalibrasi ulang.',
      );
    }

    // Per SKPL KF-07 & B08: returns to MANUAL mode with all actuators OFF
    final updated = dev.copyWith(
      maintenance: false,
      mode: DeviceMode.manual,
      actuators: const [false, false, false, false],
    );
    _replaceDevice(updated);
    _record(
      'Kalibrasi',
      'Menyelesaikan perawatan; kembali ke mode manual aman (simulasi)',
      updated.id,
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok(
      'Perawatan selesai; perangkat dalam mode manual aman',
    );
  }

  ActionResult captureCalibrationSample({
    required String deviceId,
    required double referencePpm,
    required String scale,
    required bool probeReady,
  }) {
    final dev = deviceById(deviceId);
    final user = currentUser;
    if (dev == null || user == null) {
      return const ActionResult.err('Perangkat atau sesi tidak valid.');
    }
    if (!dev.online || !dev.maintenance) {
      return const ActionResult.err(
        'Aktifkan mode perawatan pada perangkat online terlebih dahulu.',
      );
    }
    if (dev.calibration.pending != null || dev.calibration.draft != null) {
      return const ActionResult.err(
        'Masih ada draf atau perintah kalibrasi yang menunggu.',
      );
    }
    if (!probeReady) {
      return const ActionResult.err(
        'Konfirmasikan persiapan pengukuran terlebih dahulu.',
      );
    }
    if (referencePpm <= 0 ||
        referencePpm > 10000 ||
        (scale != '500' && scale != '700')) {
      return const ActionResult.err(
        'Isi nilai standar positif (0,01–10.000) dan pilih skala PPM yang sesuai.',
      );
    }

    final observed = (referencePpm * 0.96 * 100).round() / 100.0;
    final tempC = dev.temp > 0 ? dev.temp : 26.5;
    final adcMv =
        ((referencePpm * 1.15).clamp(180.0, 2650.0) * 10).round() / 10.0;
    final prevFactor = dev.calibration.activeTds?.value.factor ?? 1.0;
    final newFactor =
        ((referencePpm / observed) * prevFactor * 1000).round() / 1000.0;

    final calVal = CalibrationValue(
      reference: referencePpm,
      scale: scale,
      observed: observed,
      token: 'Faktor ${newFactor.toStringAsFixed(3)} · contoh ESP',
      adcMv: adcMv,
      tempC: tempC,
      factor: newFactor,
    );

    final draft = CalibrationDraft(
      value: calVal,
      previous: dev.calibration.activeTds?.value,
      userName: user.name,
      userRoleCode: user.role.code,
    );

    _replaceDevice(
      dev.copyWith(
        calibration: dev.calibration.copyWith(
          draft: draft,
          clearResult: true,
        ),
      ),
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Pembacaan kalibrasi simulasi siap dikirim');
  }

  ActionResult discardCalibrationDraft(String deviceId) {
    final dev = deviceById(deviceId);
    if (dev == null || dev.calibration.draft == null) {
      return const ActionResult.err('Tidak ada draf kalibrasi.');
    }
    final draft = dev.calibration.draft!;
    final entry = CalibrationRecord(
      time: DateTime.now(),
      requestId: 'Belum dikirim',
      status: 'Dibatalkan',
      value: draft.value,
      previous: draft.previous,
      userName: draft.userName,
      userRoleCode: draft.userRoleCode,
      note: 'Hasil belum dikirim; parameter sebelumnya tidak berubah.',
    );

    _replaceDevice(
      dev.copyWith(
        calibration: dev.calibration.copyWith(
          clearDraft: true,
          history: [entry, ...dev.calibration.history],
          result: const CalibrationBannerResult(
            ok: false,
            text: 'Hasil dibatalkan. Parameter aktif tidak berubah.',
          ),
        ),
      ),
    );
    _persist();
    notifyListeners();
    return const ActionResult.ok('Draf kalibrasi dibatalkan');
  }

  ActionResult sendCalibrationToEsp(String deviceId) {
    final dev = deviceById(deviceId);
    if (dev == null || dev.calibration.draft == null) {
      return const ActionResult.err('Tidak ada draf untuk dikirim.');
    }
    if (!dev.online || !dev.maintenance || dev.calibration.pending != null) {
      return const ActionResult.err('Tidak dapat mengirim kalibrasi saat ini.');
    }
    final draft = dev.calibration.draft!;
    final reqId =
        'CAL-${DateTime.now().millisecondsSinceEpoch}-${++_commandSequence}';
    final pending = CalibrationPending(
      requestId: reqId,
      deviceId: dev.id,
      value: draft.value,
      previous: draft.previous,
      userName: draft.userName,
      userRoleCode: draft.userRoleCode,
    );

    _replaceDevice(
      dev.copyWith(
        calibration: dev.calibration.copyWith(
          clearDraft: true,
          pending: pending,
          clearResult: true,
        ),
      ),
    );
    _persist();
    notifyListeners();
    return ActionResult.ok('Perintah $reqId dikirim; menunggu konfirmasi ESP');
  }

  /// outcome: 'ack' | 'reject' | 'timeout'
  ActionResult settleCalibration(String deviceId, String outcome) {
    final dev = deviceById(deviceId);
    if (dev == null || dev.calibration.pending == null) {
      return const ActionResult.err('Tidak ada perintah menunggu.');
    }
    final pending = dev.calibration.pending!;
    if (pending.deviceId != dev.id) {
      return const ActionResult.err('ID perangkat tidak sesuai.');
    }
    if (outcome == 'ack' && (!dev.online || !dev.maintenance)) {
      return const ActionResult.err(
        'Perangkat offline atau tidak dalam perawatan; ACK ditolak.',
      );
    }

    final now = DateTime.now();
    final (status, note) = switch (outcome) {
      'ack' => (
          'Tersimpan',
          'ESP simulasi mengonfirmasi penyimpanan ke NVS. Lakukan verifikasi sebelum keluar dari perawatan.',
        ),
      'reject' => (
          'Ditolak',
          'ESP simulasi menolak penyimpanan; parameter lama dipertahankan.',
        ),
      _ => (
          'Timeout',
          'Tidak ada konfirmasi penyimpanan; status perangkat perlu diperiksa ulang. Parameter terakhir yang dikonfirmasi tetap ditampilkan.',
        ),
    };

    final entry = CalibrationRecord(
      time: now,
      requestId: pending.requestId,
      status: status,
      value: pending.value,
      previous: pending.previous,
      userName: pending.userName,
      userRoleCode: pending.userRoleCode,
      note: note,
    );

    final nextActive = outcome == 'ack'
        ? ActiveCalibration(
            value: pending.value,
            time: now,
            requestId: pending.requestId,
            verified: false,
          )
        : dev.calibration.activeTds;

    _replaceDevice(
      dev.copyWith(
        calibration: dev.calibration.copyWith(
          activeTds: nextActive,
          clearPending: true,
          history: [entry, ...dev.calibration.history],
          result: CalibrationBannerResult(ok: outcome == 'ack', text: note),
        ),
      ),
    );
    _record(
      'Kalibrasi',
      'Sensor TDS: ${status.toLowerCase()} (simulasi)',
      dev.id,
    );
    _persist();
    notifyListeners();
    return ActionResult.ok(note);
  }

  ActionResult verifyActiveCalibration(String deviceId, bool passed) {
    final dev = deviceById(deviceId);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    final active = dev.calibration.activeTds;
    if (!dev.online ||
        !dev.maintenance ||
        dev.calibration.pending != null ||
        dev.calibration.draft != null ||
        active == null) {
      return const ActionResult.err('Verifikasi tidak dapat dilakukan saat ini.');
    }

    final updatedActive = active.copyWith(verified: passed);
    final updatedHistory = dev.calibration.history.map((r) {
      if (r.requestId == active.requestId) {
        return r.copyWith(verified: passed);
      }
      return r;
    }).toList();

    _replaceDevice(
      dev.copyWith(
        calibration: dev.calibration.copyWith(
          activeTds: updatedActive,
          history: updatedHistory,
        ),
      ),
    );
    _record(
      'Kalibrasi',
      'Verifikasi Sensor TDS ${passed ? 'lulus' : 'gagal'} (simulasi)',
      dev.id,
    );
    _persist();
    notifyListeners();
    return ActionResult.ok(
      passed
          ? 'Verifikasi lulus simulasi'
          : 'Verifikasi gagal. Lakukan kalibrasi ulang.',
    );
  }

  // KF-09: History Filtering & Logging
  List<SensorReading> filteredReadings({
    required String deviceFilter,
    required String range, // day | three | all
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    final now = DateTime.now();
    return _readings.where((r) {
      if (deviceFilter != 'all' && r.deviceId != deviceFilter) return false;
      if (range == 'day' &&
          r.time.isBefore(now.subtract(const Duration(hours: 24)))) {
        return false;
      }
      if (range == 'three' &&
          r.time.isBefore(now.subtract(const Duration(hours: 72)))) {
        return false;
      }
      if (dateFrom != null) {
        final start = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
        if (r.time.isBefore(start)) return false;
      }
      if (dateTo != null) {
        final end = DateTime(
          dateTo.year,
          dateTo.month,
          dateTo.day,
          23,
          59,
          59,
          999,
        );
        if (r.time.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  void logExport(String formatLabel, int rowCount, String deviceFilter) {
    _record(
      'Riwayat',
      'Mengunduh $formatLabel riwayat sensor ($rowCount baris)',
      deviceFilter == 'all' ? _selectedDeviceId : deviceFilter,
    );
    _persist();
    notifyListeners();
  }

  // KF-10: Notifications
  void markNotificationRead(int id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].read) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
      _persist();
      notifyListeners();
    }
  }

  void markAllNotificationsRead() {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _persist();
    notifyListeners();
  }

  // KF-12: Profile & Password
  ActionResult updateOwnProfile({
    required String name,
    required String username,
    required String phone,
  }) {
    final user = currentUser;
    if (user == null) return const ActionResult.err('Sesi tidak aktif.');
    final cleanName = name.trim();
    final cleanUser = username.trim();
    final cleanPhone = phone.trim();
    if (cleanName.isEmpty || cleanPhone.isEmpty) {
      return const ActionResult.err('Nama dan nomor telepon tidak boleh kosong.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]{3,30}$').hasMatch(cleanUser)) {
      return const ActionResult.err(
        'Username harus 3–30 karakter (huruf, angka, titik, garis bawah, tanda hubung).',
      );
    }
    if (_users.any(
      (u) =>
          u.username.toLowerCase() == cleanUser.toLowerCase() &&
          u.id != user.id,
    )) {
      return const ActionResult.err('Username sudah digunakan.');
    }

    final idx = _users.indexWhere((u) => u.id == user.id);
    _users[idx] = user.copyWith(
      name: cleanName,
      username: cleanUser,
      phone: cleanPhone,
    );
    _record('Profil', 'Memperbarui profil sendiri', '—');
    _persist();
    notifyListeners();
    return const ActionResult.ok('Profil diperbarui');
  }

  ActionResult changeOwnPassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    final user = currentUser;
    if (user == null) return const ActionResult.err('Sesi tidak aktif.');
    if (currentPassword != user.password) {
      return const ActionResult.err('Password saat ini tidak sesuai.');
    }
    if (newPassword.length < 8) {
      return const ActionResult.err('Password baru minimal 8 karakter.');
    }
    if (newPassword != confirmPassword) {
      return const ActionResult.err('Konfirmasi password baru tidak sama.');
    }
    if (newPassword == currentPassword) {
      return const ActionResult.err(
        'Password baru harus berbeda dari password saat ini.',
      );
    }
    final idx = _users.indexWhere((u) => u.id == user.id);
    _users[idx] = user.copyWith(password: newPassword);
    _record('Profil', 'Mengubah password akun sendiri', '—');
    _persist();
    notifyListeners();
    return const ActionResult.ok('Password berhasil diperbarui');
  }

  // KF-13: User Management (Owner only)
  ActionResult addUser({
    required String name,
    required String username,
    required String phone,
    required UserRole role,
    required bool active,
    required String password,
  }) {
    if (!isOwner) return const ActionResult.err('Fitur ini hanya untuk Owner.');
    final cleanName = name.trim();
    final cleanUser = username.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty || cleanPhone.isEmpty) {
      return const ActionResult.err('Nama dan nomor telepon tidak boleh kosong.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]{3,30}$').hasMatch(cleanUser)) {
      return const ActionResult.err(
        'Username harus 3–30 karakter (huruf, angka, titik, garis bawah, tanda hubung).',
      );
    }
    if (_users.any(
      (u) => u.username.toLowerCase() == cleanUser.toLowerCase(),
    )) {
      return const ActionResult.err(
        'Username sudah digunakan. Pilih username lain.',
      );
    }
    if (password.length < 8) {
      return const ActionResult.err('Password awal minimal 8 karakter.');
    }

    final nextId =
        _users.isEmpty ? 1 : (_users.map((u) => u.id).reduce(math.max) + 1);
    _users.add(
      AppUser(
        id: nextId,
        name: cleanName,
        username: cleanUser,
        role: role,
        active: active,
        phone: cleanPhone,
        password: password,
      ),
    );
    _record('Pengguna', 'Menambahkan akun $cleanName', '—');
    _persist();
    notifyListeners();
    return const ActionResult.ok('Data pengguna simulasi disimpan');
  }

  ActionResult updateUser({
    required int id,
    required String name,
    required String username,
    required String phone,
    required UserRole role,
    required bool active,
  }) {
    if (!isOwner) return const ActionResult.err('Fitur ini hanya untuk Owner.');
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return const ActionResult.err('Pengguna tidak ditemukan.');
    final existing = _users[idx];

    final cleanName = name.trim();
    final cleanUser = username.trim();
    final cleanPhone = phone.trim();

    if (cleanName.isEmpty || cleanPhone.isEmpty) {
      return const ActionResult.err('Nama dan nomor telepon tidak boleh kosong.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]{3,30}$').hasMatch(cleanUser)) {
      return const ActionResult.err(
        'Username harus 3–30 karakter (huruf, angka, titik, garis bawah, tanda hubung).',
      );
    }
    if (_users.any(
      (u) => u.username.toLowerCase() == cleanUser.toLowerCase() && u.id != id,
    )) {
      return const ActionResult.err(
        'Username sudah digunakan. Pilih username lain.',
      );
    }
    if (isLastActiveOwner(existing) && (role != UserRole.owner || !active)) {
      return const ActionResult.err(
        'Owner aktif terakhir harus tetap aktif dengan peran Owner.',
      );
    }

    _users[idx] = existing.copyWith(
      name: cleanName,
      username: cleanUser,
      phone: cleanPhone,
      role: role,
      active: active,
    );
    _record('Pengguna', 'Memperbarui akun $cleanName', '—');
    if (_currentUserId == id && !active) {
      _currentUserId = null;
    }
    _persist();
    notifyListeners();
    return const ActionResult.ok('Data pengguna simulasi disimpan');
  }

  ActionResult deleteUser(int id) {
    if (!isOwner) return const ActionResult.err('Fitur ini hanya untuk Owner.');
    final idx = _users.indexWhere((u) => u.id == id);
    if (idx == -1) return const ActionResult.err('Pengguna tidak ditemukan.');
    final target = _users[idx];
    if (isLastActiveOwner(target)) {
      return const ActionResult.err('Owner aktif terakhir tidak dapat dihapus.');
    }
    _record('Pengguna', 'Menghapus akun ${target.name}', '—');
    _users.removeAt(idx);
    if (_currentUserId == id) {
      _currentUserId = null;
    }
    _persist();
    notifyListeners();
    return const ActionResult.ok('Pengguna dihapus');
  }

  // Live Telemetry & Autodosing Simulator + Random Dummy Data Button
  ActionResult randomizeDummyData({String? deviceId}) {
    final targetId = deviceId ?? _selectedDeviceId;
    final dev = deviceById(targetId);
    if (dev == null) {
      return const ActionResult.err('Perangkat tidak ditemukan.');
    }

    final now = DateTime.now();
    // Generate realistic random PPM (1550 .. 2350), Temp (23.0 .. 31.8), and discrete Water (Air Penuh vs Air Mau Habis)
    final randomPpm = 1550 + _rng.nextInt(801);
    final randomTemp = double.parse(
      (23.0 + _rng.nextDouble() * 8.8).toStringAsFixed(1),
    );
    // 70% Air Penuh (100), 30% Air Mau Habis (0) — or flip occasionally so user sees both states easily
    final randomWater = _rng.nextInt(10) < 3 ? 0 : 100;

    final nextAct = List<bool>.from(dev.actuators);
    if (dev.online && !dev.maintenance && dev.mode == DeviceMode.auto) {
      if (randomWater < 50) {
        // Air Mau Habis -> Interlock shuts off dosing pumps, opens refill solenoid
        nextAct[0] = false;
        nextAct[1] = false;
        nextAct[2] = true;
        nextAct[3] = false;
      } else {
        nextAct[2] = false;
        if (randomPpm < dev.limits.targetPpm - dev.limits.tolerancePpm) {
          nextAct[0] = true;
          nextAct[1] = true;
        } else {
          nextAct[0] = false;
          nextAct[1] = false;
        }
      }
    }

    final updated = dev.copyWith(
      online: true,
      ppm: randomPpm,
      temp: randomTemp,
      water: randomWater,
      actuators: nextAct,
      lastUpdate: now,
    );
    _replaceDevice(updated);

    _readings.add(
      SensorReading(
        deviceId: updated.id,
        time: now,
        ppm: randomPpm,
        temp: randomTemp,
        water: randomWater,
      ),
    );

    if (updated.isWaterLow) {
      _pushNotification(
        deviceId: updated.id,
        title: 'Peringatan: Air Mau Habis',
        text:
            '${updated.name}: Sensor pelampung mendeteksi Air Mau Habis. Pompa dosing dikunci otomatis.',
        type: NotificationType.sensor,
        severity: NotificationSeverity.critical,
      );
    } else if (updated.isPpmLow) {
      _pushNotification(
        deviceId: updated.id,
        title: 'Nutrisi di bawah batas',
        text:
            '${updated.name}: Pembacaan ${AppFormatters.integer(randomPpm)} ppm di bawah batas ${AppFormatters.integer(updated.limits.minPpm)} ppm.',
        type: NotificationType.sensor,
        severity: NotificationSeverity.warning,
      );
    } else if (updated.isPpmHigh) {
      _pushNotification(
        deviceId: updated.id,
        title: 'Nutrisi melebihi batas atas',
        text:
            '${updated.name}: Pembacaan ${AppFormatters.integer(randomPpm)} ppm melebihi batas ${AppFormatters.integer(updated.limits.maxPpm)} ppm.',
        type: NotificationType.sensor,
        severity: NotificationSeverity.critical,
      );
    }

    _record(
      'Kontrol',
      'Simulasi data dummy: ${AppFormatters.integer(randomPpm)} ppm, ${AppFormatters.decimal(randomTemp)} °C, ${updated.waterStatusLabel}',
      updated.id,
    );
    _persist();
    notifyListeners();
    return ActionResult.ok(
      'Data dummy baru: ${AppFormatters.integer(randomPpm)} ppm · ${AppFormatters.decimal(randomTemp)} °C · ${updated.waterStatusLabel}',
    );
  }

  ActionResult toggleWaterLevelStatus(String deviceId) {
    final dev = deviceById(deviceId);
    if (dev == null) return const ActionResult.err('Perangkat tidak ditemukan.');
    final nextWater = dev.isWaterLow ? 100 : 0;
    final nextAct = List<bool>.from(dev.actuators);
    if (nextWater < 50) {
      // Air Mau Habis -> turn off pumps & distribution solenoid for safety
      nextAct[0] = false;
      nextAct[1] = false;
      nextAct[3] = false;
      if (dev.mode == DeviceMode.auto && dev.online && !dev.maintenance) {
        nextAct[2] = true;
      }
    } else if (dev.mode == DeviceMode.auto) {
      nextAct[2] = false;
    }

    final now = DateTime.now();
    final updated = dev.copyWith(
      water: nextWater,
      actuators: nextAct,
      lastUpdate: now,
    );
    _replaceDevice(updated);
    _readings.add(
      SensorReading(
        deviceId: updated.id,
        time: now,
        ppm: updated.ppm,
        temp: updated.temp,
        water: nextWater,
      ),
    );
    _record(
      'Kontrol',
      'Status level air disimulasikan menjadi ${updated.waterStatusLabel}',
      updated.id,
    );
    _persist();
    notifyListeners();
    return ActionResult.ok('Status level air: ${updated.waterStatusLabel}');
  }

  void toggleLiveSimulation() {
    if (_liveSimulationEnabled) {
      stopLiveSimulation();
    } else {
      _liveSimulationEnabled = true;
      _telemetryTimer?.cancel();
      _telemetryTimer = Timer.periodic(
        const Duration(seconds: 4),
        (_) => _tickSimulation(),
      );
      notifyListeners();
    }
  }

  void stopLiveSimulation() {
    _liveSimulationEnabled = false;
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    notifyListeners();
  }

  void _tickSimulation() {
    final now = DateTime.now();
    bool changed = false;

    for (int i = 0; i < _devices.length; i++) {
      final d = _devices[i];
      if (!d.online || d.maintenance) continue;

      int nextPpm = d.ppm + (_rng.nextInt(45) - 22);
      double nextTemp = double.parse(
        (d.temp + (_rng.nextDouble() * 0.5 - 0.25))
            .clamp(22.0, 33.5)
            .toStringAsFixed(1),
      );
      // Discrete float switch: Air Penuh (100) or Air Mau Habis (0)
      int nextWater = d.isWaterLow
          ? (_rng.nextInt(10) < 6 ? 100 : 0)
          : (_rng.nextInt(10) < 2 ? 0 : 100);
      final nextAct = List<bool>.from(d.actuators);

      if (d.mode == DeviceMode.auto) {
        if (nextWater < 50) {
          nextAct[0] = false;
          nextAct[1] = false;
          nextAct[2] = true; // Auto refill solenoid ON
          nextAct[3] = false;
        } else {
          nextAct[2] = false;
          if (nextPpm < d.limits.targetPpm - d.limits.tolerancePpm) {
            nextAct[0] = true;
            nextAct[1] = true;
            nextPpm += 35;
          } else if (nextPpm >= d.limits.targetPpm) {
            nextAct[0] = false;
            nextAct[1] = false;
          }
        }
      }

      nextPpm = nextPpm.clamp(1200, 2600);
      _devices[i] = d.copyWith(
        ppm: nextPpm,
        temp: nextTemp,
        water: nextWater,
        actuators: nextAct,
        lastUpdate: now,
      );

      _readings.add(
        SensorReading(
          deviceId: d.id,
          time: now,
          ppm: nextPpm,
          temp: nextTemp,
          water: nextWater,
        ),
      );
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _inactivityTimer?.cancel();
    super.dispose();
  }
}
