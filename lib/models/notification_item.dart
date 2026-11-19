enum NotificationType { offline, sensor }

enum NotificationSeverity { info, warning, critical }

extension NotificationSeverityExt on NotificationSeverity {
  String get label => switch (this) {
        NotificationSeverity.info => 'INFO',
        NotificationSeverity.warning => 'PERINGATAN',
        NotificationSeverity.critical => 'KRITIS',
      };

  String get code => name;

  static NotificationSeverity fromCode(String? code) => switch (code) {
        'critical' => NotificationSeverity.critical,
        'warning' => NotificationSeverity.warning,
        _ => NotificationSeverity.info,
      };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.text,
    required this.time,
    required this.read,
    required this.type,
    required this.severity,
  });

  final int id;
  final String deviceId;
  final String title;
  final String text;
  final DateTime time;
  final bool read;
  final NotificationType type;
  final NotificationSeverity severity;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      deviceId: deviceId,
      title: title,
      text: text,
      time: time,
      read: read ?? this.read,
      type: type,
      severity: severity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'title': title,
        'text': text,
        'time': time.toIso8601String(),
        'read': read,
        'type': type.name,
        'severity': severity.code,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        deviceId: json['deviceId'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
        time: DateTime.parse(json['time'] as String),
        read: json['read'] as bool? ?? false,
        type: json['type'] == 'offline'
            ? NotificationType.offline
            : NotificationType.sensor,
        severity: NotificationSeverityExt.fromCode(json['severity'] as String?),
      );
}
