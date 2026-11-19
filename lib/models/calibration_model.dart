class CalibrationValue {
  const CalibrationValue({
    required this.reference,
    required this.scale,
    required this.observed,
    required this.token,
    this.adcMv = 1482.5,
    this.tempC = 26.5,
    this.factor = 1.042,
  });

  final double reference;
  final String scale;
  final double observed;
  final String token;
  final double adcMv;
  final double tempC;
  final double factor;

  String get formattedSummary =>
      'Standar ${reference == reference.roundToDouble() ? reference.round() : reference.toStringAsFixed(2)} ppm · Skala $scale · $token';

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'scale': scale,
        'observed': observed,
        'token': token,
        'adcMv': adcMv,
        'tempC': tempC,
        'factor': factor,
      };

  factory CalibrationValue.fromJson(Map<String, dynamic> json) =>
      CalibrationValue(
        reference: (json['reference'] as num).toDouble(),
        scale: json['scale'] as String,
        observed: (json['observed'] as num).toDouble(),
        token: json['token'] as String? ?? 'Koefisien contoh dari ESP',
        adcMv: (json['adcMv'] as num?)?.toDouble() ?? 1482.5,
        tempC: (json['tempC'] as num?)?.toDouble() ?? 26.5,
        factor: (json['factor'] as num?)?.toDouble() ?? 1.042,
      );
}

class ActiveCalibration {
  const ActiveCalibration({
    required this.value,
    required this.time,
    required this.requestId,
    required this.verified,
  });

  final CalibrationValue value;
  final DateTime time;
  final String requestId;
  final bool verified;

  ActiveCalibration copyWith({
    CalibrationValue? value,
    DateTime? time,
    String? requestId,
    bool? verified,
  }) {
    return ActiveCalibration(
      value: value ?? this.value,
      time: time ?? this.time,
      requestId: requestId ?? this.requestId,
      verified: verified ?? this.verified,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value.toJson(),
        'time': time.toIso8601String(),
        'requestId': requestId,
        'verified': verified,
      };

  factory ActiveCalibration.fromJson(Map<String, dynamic> json) =>
      ActiveCalibration(
        value: CalibrationValue.fromJson(
          json['value'] as Map<String, dynamic>,
        ),
        time: DateTime.parse(json['time'] as String),
        requestId: json['requestId'] as String,
        verified: json['verified'] as bool? ?? false,
      );
}

class CalibrationDraft {
  const CalibrationDraft({
    required this.value,
    required this.userName,
    required this.userRoleCode,
    this.previous,
  });

  final CalibrationValue value;
  final CalibrationValue? previous;
  final String userName;
  final String userRoleCode;

  Map<String, dynamic> toJson() => {
        'value': value.toJson(),
        'previous': previous?.toJson(),
        'userName': userName,
        'userRoleCode': userRoleCode,
      };

  factory CalibrationDraft.fromJson(Map<String, dynamic> json) =>
      CalibrationDraft(
        value: CalibrationValue.fromJson(
          json['value'] as Map<String, dynamic>,
        ),
        previous: json['previous'] != null
            ? CalibrationValue.fromJson(
                json['previous'] as Map<String, dynamic>,
              )
            : null,
        userName: json['userName'] as String,
        userRoleCode: json['userRoleCode'] as String,
      );
}

class CalibrationPending {
  const CalibrationPending({
    required this.requestId,
    required this.deviceId,
    required this.value,
    required this.userName,
    required this.userRoleCode,
    this.previous,
  });

  final String requestId;
  final String deviceId;
  final CalibrationValue value;
  final CalibrationValue? previous;
  final String userName;
  final String userRoleCode;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'deviceId': deviceId,
        'value': value.toJson(),
        'previous': previous?.toJson(),
        'userName': userName,
        'userRoleCode': userRoleCode,
      };

  factory CalibrationPending.fromJson(Map<String, dynamic> json) =>
      CalibrationPending(
        requestId: json['requestId'] as String,
        deviceId: json['deviceId'] as String,
        value: CalibrationValue.fromJson(
          json['value'] as Map<String, dynamic>,
        ),
        previous: json['previous'] != null
            ? CalibrationValue.fromJson(
                json['previous'] as Map<String, dynamic>,
              )
            : null,
        userName: json['userName'] as String,
        userRoleCode: json['userRoleCode'] as String,
      );
}

class CalibrationRecord {
  const CalibrationRecord({
    required this.time,
    required this.requestId,
    required this.status,
    required this.value,
    required this.userName,
    required this.userRoleCode,
    required this.note,
    this.previous,
    this.verified,
  });

  final DateTime time;
  final String requestId;
  final String status; // Tersimpan | Ditolak | Timeout | Dibatalkan
  final CalibrationValue value;
  final CalibrationValue? previous;
  final String userName;
  final String userRoleCode;
  final bool? verified;
  final String note;

  CalibrationRecord copyWith({bool? verified}) {
    return CalibrationRecord(
      time: time,
      requestId: requestId,
      status: status,
      value: value,
      previous: previous,
      userName: userName,
      userRoleCode: userRoleCode,
      verified: verified ?? this.verified,
      note: note,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'requestId': requestId,
        'status': status,
        'value': value.toJson(),
        'previous': previous?.toJson(),
        'userName': userName,
        'userRoleCode': userRoleCode,
        'verified': verified,
        'note': note,
      };

  factory CalibrationRecord.fromJson(Map<String, dynamic> json) =>
      CalibrationRecord(
        time: DateTime.parse(json['time'] as String),
        requestId: json['requestId'] as String,
        status: json['status'] as String,
        value: CalibrationValue.fromJson(
          json['value'] as Map<String, dynamic>,
        ),
        previous: json['previous'] != null
            ? CalibrationValue.fromJson(
                json['previous'] as Map<String, dynamic>,
              )
            : null,
        userName: json['userName'] as String,
        userRoleCode: json['userRoleCode'] as String,
        verified: json['verified'] as bool?,
        note: json['note'] as String? ?? '',
      );
}

class CalibrationBannerResult {
  const CalibrationBannerResult({required this.ok, required this.text});

  final bool ok;
  final String text;

  Map<String, dynamic> toJson() => {'ok': ok, 'text': text};

  factory CalibrationBannerResult.fromJson(Map<String, dynamic> json) =>
      CalibrationBannerResult(
        ok: json['ok'] as bool? ?? false,
        text: json['text'] as String? ?? '',
      );
}

class DeviceCalibration {
  const DeviceCalibration({
    this.activeTds,
    this.pending,
    this.draft,
    this.history = const [],
    this.result,
  });

  final ActiveCalibration? activeTds;
  final CalibrationPending? pending;
  final CalibrationDraft? draft;
  final List<CalibrationRecord> history;
  final CalibrationBannerResult? result;

  DeviceCalibration copyWith({
    ActiveCalibration? activeTds,
    bool clearActiveTds = false,
    CalibrationPending? pending,
    bool clearPending = false,
    CalibrationDraft? draft,
    bool clearDraft = false,
    List<CalibrationRecord>? history,
    CalibrationBannerResult? result,
    bool clearResult = false,
  }) {
    return DeviceCalibration(
      activeTds: clearActiveTds ? null : (activeTds ?? this.activeTds),
      pending: clearPending ? null : (pending ?? this.pending),
      draft: clearDraft ? null : (draft ?? this.draft),
      history: history ?? this.history,
      result: clearResult ? null : (result ?? this.result),
    );
  }

  Map<String, dynamic> toJson() => {
        'activeTds': activeTds?.toJson(),
        'pending': pending?.toJson(),
        'draft': draft?.toJson(),
        'history': history.map((e) => e.toJson()).toList(),
        'result': result?.toJson(),
      };

  factory DeviceCalibration.fromJson(Map<String, dynamic> json) =>
      DeviceCalibration(
        activeTds: json['activeTds'] != null
            ? ActiveCalibration.fromJson(
                json['activeTds'] as Map<String, dynamic>,
              )
            : null,
        pending: json['pending'] != null
            ? CalibrationPending.fromJson(
                json['pending'] as Map<String, dynamic>,
              )
            : null,
        draft: json['draft'] != null
            ? CalibrationDraft.fromJson(json['draft'] as Map<String, dynamic>)
            : null,
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) => CalibrationRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        result: json['result'] != null
            ? CalibrationBannerResult.fromJson(
                json['result'] as Map<String, dynamic>,
              )
            : null,
      );
}
