enum SensorMetricType { ppm, temp, water }

extension SensorMetricTypeExt on SensorMetricType {
  String get label => switch (this) {
        SensorMetricType.ppm => 'Nutrisi / TDS',
        SensorMetricType.temp => 'Suhu larutan',
        SensorMetricType.water => 'Level air',
      };

  String get unit => switch (this) {
        SensorMetricType.ppm => 'ppm',
        SensorMetricType.temp => '°C',
        SensorMetricType.water => 'Status',
      };
}

class SensorReading {
  const SensorReading({
    required this.deviceId,
    required this.time,
    required this.ppm,
    required this.temp,
    required this.water,
  });

  final String deviceId;
  final DateTime time;
  final int ppm;
  final double temp;

  /// Discrete water level: >= 50 means 'Air Penuh' (100), < 50 means 'Air Mau Habis' (0).
  final int water;

  bool get isWaterLow => water < 50;
  String get waterStatusLabel => isWaterLow ? 'Air Mau Habis' : 'Air Penuh';

  double valueFor(SensorMetricType type) => switch (type) {
        SensorMetricType.ppm => ppm.toDouble(),
        SensorMetricType.temp => temp,
        SensorMetricType.water => isWaterLow ? 0.0 : 100.0,
      };

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'time': time.toIso8601String(),
        'ppm': ppm,
        'temp': temp,
        'water': isWaterLow ? 0 : 100,
      };

  factory SensorReading.fromJson(Map<String, dynamic> json) => SensorReading(
        deviceId: json['deviceId'] as String,
        time: DateTime.parse(json['time'] as String),
        ppm: (json['ppm'] as num).toInt(),
        temp: (json['temp'] as num).toDouble(),
        water: ((json['water'] as num).toInt() < 50) ? 0 : 100,
      );
}
