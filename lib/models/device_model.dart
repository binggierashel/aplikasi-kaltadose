import 'calibration_model.dart';

enum DeviceMode { auto, manual }

extension DeviceModeExt on DeviceMode {
  String get label => this == DeviceMode.auto ? 'Otomatis' : 'Manual';
  String get code => this == DeviceMode.auto ? 'auto' : 'manual';

  static DeviceMode fromCode(String? code) =>
      code == 'manual' ? DeviceMode.manual : DeviceMode.auto;
}

class SensorLimits {
  const SensorLimits({
    required this.minPpm,
    required this.maxPpm,
    required this.targetPpm,
    required this.tolerancePpm,
    required this.tempMin,
    required this.tempMax,
    required this.waterMin,
    required this.waterMax,
  });

  final int minPpm;
  final int maxPpm;
  final int targetPpm;
  final int tolerancePpm;
  final double tempMin;
  final double tempMax;
  final int waterMin;
  final int waterMax;

  factory SensorLimits.defaults() => const SensorLimits(
        minPpm: 1800,
        maxPpm: 2200,
        targetPpm: 2000,
        tolerancePpm: 50,
        tempMin: 20.0,
        tempMax: 32.0,
        waterMin: 25,
        waterMax: 80,
      );

  SensorLimits copyWith({
    int? minPpm,
    int? maxPpm,
    int? targetPpm,
    int? tolerancePpm,
    double? tempMin,
    double? tempMax,
    int? waterMin,
    int? waterMax,
  }) {
    return SensorLimits(
      minPpm: minPpm ?? this.minPpm,
      maxPpm: maxPpm ?? this.maxPpm,
      targetPpm: targetPpm ?? this.targetPpm,
      tolerancePpm: tolerancePpm ?? this.tolerancePpm,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      waterMin: waterMin ?? this.waterMin,
      waterMax: waterMax ?? this.waterMax,
    );
  }

  Map<String, dynamic> toJson() => {
        'minPpm': minPpm,
        'maxPpm': maxPpm,
        'targetPpm': targetPpm,
        'tolerancePpm': tolerancePpm,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'waterMin': waterMin,
        'waterMax': waterMax,
      };

  factory SensorLimits.fromJson(Map<String, dynamic> json) => SensorLimits(
        minPpm: (json['minPpm'] as num?)?.toInt() ?? 1800,
        maxPpm: (json['maxPpm'] as num?)?.toInt() ?? 2200,
        targetPpm: (json['targetPpm'] as num?)?.toInt() ?? 2000,
        tolerancePpm: (json['tolerancePpm'] as num?)?.toInt() ?? 50,
        tempMin: (json['tempMin'] as num?)?.toDouble() ?? 20.0,
        tempMax: (json['tempMax'] as num?)?.toDouble() ?? 32.0,
        waterMin: (json['waterMin'] as num?)?.toInt() ?? 25,
        waterMax: (json['waterMax'] as num?)?.toInt() ?? 80,
      );
}

class IoTDevice {
  const IoTDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.online,
    required this.ppm,
    required this.temp,
    required this.water,
    required this.firmware,
    required this.lastUpdate,
    required this.mode,
    required this.actuators,
    required this.limits,
    required this.maintenance,
    required this.calibration,
    this.plantType = 'Melon',
    this.tankVolumeLiters = 200,
    this.lastAckText,
  });

  final String id;
  final String name;
  final String location;
  final bool online;
  final int ppm;
  final double temp;
  final int water;
  final String firmware;
  final DateTime lastUpdate;
  final DeviceMode mode;

  /// [0] Pompa nutrisi A, [1] Pompa nutrisi B, [2] Solenoid pengisian, [3] Solenoid distribusi
  final List<bool> actuators;
  final SensorLimits limits;
  final bool maintenance;
  final DeviceCalibration calibration;
  final String plantType;
  final int tankVolumeLiters;
  final String? lastAckText;

  static const List<String> actuatorNames = [
    'Pompa nutrisi A',
    'Pompa nutrisi B',
    'Solenoid pengisian',
    'Solenoid distribusi',
  ];

  static const List<String> actuatorDescriptions = [
    'Dosing larutan nutrisi A',
    'Dosing larutan nutrisi B',
    'Aliran air masuk ke tandon',
    'Aliran larutan ke tanaman',
  ];

  bool get isWaterLow => water < 50;
  String get waterStatusLabel => isWaterLow ? 'Air Mau Habis' : 'Air Penuh';
  bool get isPpmLow => ppm > 0 && ppm < limits.minPpm;
  bool get isPpmHigh => ppm > limits.maxPpm;

  String get ppmStatusLabel {
    if (!online && ppm == 0) return 'Belum ada data';
    if (ppm < limits.minPpm) return 'Di bawah batas';
    if (ppm > limits.maxPpm) return 'Di atas batas';
    return 'Optimal';
  }

  IoTDevice copyWith({
    String? id,
    String? name,
    String? location,
    bool? online,
    int? ppm,
    double? temp,
    int? water,
    String? firmware,
    DateTime? lastUpdate,
    DeviceMode? mode,
    List<bool>? actuators,
    SensorLimits? limits,
    bool? maintenance,
    DeviceCalibration? calibration,
    String? plantType,
    int? tankVolumeLiters,
    String? lastAckText,
    bool clearLastAck = false,
  }) {
    return IoTDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      online: online ?? this.online,
      ppm: ppm ?? this.ppm,
      temp: temp ?? this.temp,
      water: water ?? this.water,
      firmware: firmware ?? this.firmware,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      mode: mode ?? this.mode,
      actuators: actuators ?? List<bool>.from(this.actuators),
      limits: limits ?? this.limits,
      maintenance: maintenance ?? this.maintenance,
      calibration: calibration ?? this.calibration,
      plantType: plantType ?? this.plantType,
      tankVolumeLiters: tankVolumeLiters ?? this.tankVolumeLiters,
      lastAckText: clearLastAck ? null : (lastAckText ?? this.lastAckText),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'online': online,
        'ppm': ppm,
        'temp': temp,
        'water': water,
        'firmware': firmware,
        'lastUpdate': lastUpdate.toIso8601String(),
        'mode': mode.code,
        'actuators': actuators,
        'limits': limits.toJson(),
        'maintenance': maintenance,
        'calibration': calibration.toJson(),
        'plantType': plantType,
        'tankVolumeLiters': tankVolumeLiters,
        'lastAckText': lastAckText,
      };

  factory IoTDevice.fromJson(Map<String, dynamic> json) => IoTDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        location: json['location'] as String,
        online: json['online'] as bool? ?? false,
        ppm: (json['ppm'] as num?)?.toInt() ?? 0,
        temp: (json['temp'] as num?)?.toDouble() ?? 0.0,
        water: (json['water'] as num?)?.toInt() ?? 0,
        firmware: json['firmware'] as String? ?? 'v1.0.0',
        lastUpdate: DateTime.parse(json['lastUpdate'] as String),
        mode: DeviceModeExt.fromCode(json['mode'] as String?),
        actuators: (json['actuators'] as List<dynamic>?)
                ?.map((e) => e as bool)
                .toList() ??
            [false, false, false, false],
        limits: SensorLimits.fromJson(
          json['limits'] as Map<String, dynamic>,
        ),
        maintenance: json['maintenance'] as bool? ?? false,
        calibration: DeviceCalibration.fromJson(
          json['calibration'] as Map<String, dynamic>,
        ),
        plantType: json['plantType'] as String? ?? 'Melon',
        tankVolumeLiters: (json['tankVolumeLiters'] as num?)?.toInt() ?? 200,
        lastAckText: json['lastAckText'] as String?,
      );
}
