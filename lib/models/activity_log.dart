class ActivityLog {
  const ActivityLog({
    required this.time,
    required this.deviceId,
    required this.userName,
    required this.category,
    required this.text,
  });

  final DateTime time;
  final String deviceId;
  final String userName;
  final String category; // Kontrol, Mode, Ambang batas, Kalibrasi, Pengguna, Perangkat, Profil, Riwayat
  final String text;

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'deviceId': deviceId,
        'userName': userName,
        'category': category,
        'text': text,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        time: DateTime.parse(json['time'] as String),
        deviceId: json['deviceId'] as String? ?? '—',
        userName: json['userName'] as String? ?? 'Sistem',
        category: json['category'] as String? ?? 'Sistem',
        text: json['text'] as String? ?? '',
      );
}
