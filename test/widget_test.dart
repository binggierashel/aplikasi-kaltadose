import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:kalta_farm/app.dart';
import 'package:kalta_farm/models/device_model.dart';
import 'package:kalta_farm/models/user_model.dart';
import 'package:kalta_farm/state/app_state.dart';

void main() {
  setUp(() {
    AppState.disableDiskPersistenceForTests = true;
  });

  group('AppState Business Rules (SKPL KF-01 s.d. KF-13)', () {
    test('KF-01: Login rejects wrong password & inactive account, accepts Owner/Petani', () async {
      final state = AppState();
      addTearDown(state.dispose);
      await state.init();

      expect(state.login('owner', 'wrong').ok, isFalse);
      expect(state.login('ahmad', 'demo12345').ok, isFalse);

      expect(state.login('petani', 'petani123').ok, isTrue);
      expect(state.isOwner, isFalse);

      state.logout();
      expect(state.isLoggedIn, isFalse);

      expect(state.login('owner', 'owner123').ok, isTrue);
      expect(state.isOwner, isTrue);
    });

    test('KF-04 & KF-13: RBAC & last active Owner protection', () async {
      final state = AppState();
      addTearDown(state.dispose);
      await state.init();

      // Petani blocked from managing users and devices
      state.login('petani', 'petani123');
      expect(
        state.addDevice(
          id: 'ESP32S3-99',
          name: 'Test',
          location: 'Blok Z',
          plantType: 'Melon',
          tankVolumeLiters: 100,
        ).ok,
        isFalse,
      );
      expect(state.deleteUser(2).ok, isFalse);

      // Owner cannot delete, deactivate, or demote the last active Owner
      state.login('owner', 'owner123');
      final owner = state.users.firstWhere((u) => u.username == 'owner');
      expect(state.deleteUser(owner.id).ok, isFalse);
      expect(
        state.updateUser(
          id: owner.id,
          name: owner.name,
          username: owner.username,
          phone: owner.phone,
          role: UserRole.petani,
          active: true,
        ).ok,
        isFalse,
      );
      expect(
        state.updateUser(
          id: owner.id,
          name: owner.name,
          username: owner.username,
          phone: owner.phone,
          role: UserRole.owner,
          active: false,
        ).ok,
        isFalse,
      );
    });

    test('KF-05 & KF-06: Mode switch, manual actuator toggle, and threshold validation', () async {
      final state = AppState();
      addTearDown(state.dispose);
      await state.init();
      state.login('petani', 'petani123');

      final devId = state.selectedDeviceId;
      // Default mode is auto -> actuator toggle blocked
      expect(state.toggleActuator(devId, 0).ok, isFalse);

      // Switch to manual -> actuator toggle succeeds
      expect(state.changeDeviceMode(devId, DeviceMode.manual).ok, isTrue);
      expect(state.toggleActuator(devId, 0).ok, isTrue);
      expect(state.selectedDevice!.actuators[0], isTrue);

      // Switch back to auto -> turns off all actuators
      expect(state.changeDeviceMode(devId, DeviceMode.auto).ok, isTrue);
      expect(state.selectedDevice!.actuators, everyElement(isFalse));

      // Invalid threshold range rejected
      expect(
        state.saveThresholds(
          devId,
          const SensorLimits(
            minPpm: 2200,
            maxPpm: 1800,
            targetPpm: 2000,
            tolerancePpm: 50,
            tempMin: 20,
            tempMax: 32,
            waterMin: 25,
            waterMax: 80,
          ),
        ).ok,
        isFalse,
      );
    });

    test('KF-07 & KF-08: Maintenance lock & TDS Calibration full workflow', () async {
      final state = AppState();
      addTearDown(state.dispose);
      await state.init();
      state.login('owner', 'owner123');

      final devId = state.selectedDeviceId;

      // Enter maintenance -> locks mode, thresholds, and device deletion
      expect(state.enterMaintenance(devId).ok, isTrue);
      expect(state.changeDeviceMode(devId, DeviceMode.manual).ok, isFalse);
      expect(state.deleteDevice(devId).ok, isFalse);

      // Capture draft -> send -> ACK -> must verify before exiting maintenance
      expect(
        state.captureCalibrationSample(
          deviceId: devId,
          referencePpm: 1413,
          scale: '500',
          probeReady: true,
        ).ok,
        isTrue,
      );
      expect(state.selectedDevice!.calibration.draft, isNotNull);
      expect(state.selectedDevice!.calibration.activeTds, isNull);

      expect(state.sendCalibrationToEsp(devId).ok, isTrue);
      expect(state.selectedDevice!.calibration.pending, isNotNull);

      expect(state.settleCalibration(devId, 'ack').ok, isTrue);
      expect(state.selectedDevice!.calibration.activeTds, isNotNull);
      expect(state.selectedDevice!.calibration.activeTds!.verified, isFalse);

      // Cannot exit before verification passes
      expect(state.exitMaintenance(devId).ok, isFalse);

      // Pass verification -> exit returns to MANUAL mode with actuators OFF
      expect(state.verifyActiveCalibration(devId, true).ok, isTrue);
      expect(state.exitMaintenance(devId).ok, isTrue);
      expect(state.selectedDevice!.maintenance, isFalse);
      expect(state.selectedDevice!.mode, DeviceMode.manual);
      expect(state.selectedDevice!.actuators, everyElement(isFalse));

      // Test discrete water level (Air Penuh / Air Mau Habis) & Random Dummy Data button
      expect(
        state.selectedDevice!.waterStatusLabel,
        isIn(['Air Penuh', 'Air Mau Habis']),
      );
      expect(state.toggleWaterLevelStatus(devId).ok, isTrue);
      expect(
        state.selectedDevice!.waterStatusLabel,
        isIn(['Air Penuh', 'Air Mau Habis']),
      );
      expect(state.randomizeDummyData(deviceId: devId).ok, isTrue);
      expect(
        state.selectedDevice!.waterStatusLabel,
        isIn(['Air Penuh', 'Air Mau Habis']),
      );
    });
  });

  group('UI Widget Smoke Tests', () {
    testWidgets('Login as Owner and navigate all main tabs cleanly', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState();
      addTearDown(state.dispose);
      await state.init();

      await tester.pumpWidget(KaltaFarmApp(initialState: state));
      await tester.pumpAndSettle();

      // Login screen shows botanical story and demo buttons
      expect(find.text('Selamat datang kembali'), findsOneWidget);
      await tester.ensureVisible(find.text('Owner'));
      await tester.tap(find.text('Owner'));
      await tester.pump();
      await tester.ensureVisible(find.text('Masuk ke aplikasi'));
      await tester.tap(find.text('Masuk ke aplikasi'));
      await tester.pumpAndSettle();

      // Dashboard loaded
      expect(find.text('Kebun dalam pantauan'), findsOneWidget);
      expect(find.text('Greenhouse Melon 01'), findsWidgets);

      // Navigate tabs
      await tester.tap(find.text('Perangkat').last);
      await tester.pumpAndSettle();
      expect(find.text('Perangkat kebun'), findsOneWidget);

      await tester.tap(find.text('Kontrol').last);
      await tester.pumpAndSettle();
      expect(find.text('Kontrol aktuator'), findsOneWidget);

      await tester.tap(find.text('Riwayat').last);
      await tester.pumpAndSettle();
      expect(find.text('Riwayat sensor'), findsOneWidget);

      await tester.tap(find.text('Menu').last);
      await tester.pumpAndSettle();
      expect(find.text('Menu aplikasi'), findsOneWidget);
      expect(find.text('Kelola pengguna'), findsOneWidget);
    });
  });
}
