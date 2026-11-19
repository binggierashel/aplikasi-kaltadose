import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum NoticeTone { info, warning, error, success }

class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.tone = NoticeTone.info,
    this.icon,
  });

  final String text;
  final NoticeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, defaultIcon) = switch (tone) {
      NoticeTone.info => (
          AppColors.mint,
          AppColors.forest,
          Icons.info_outline_rounded,
        ),
      NoticeTone.success => (
          AppColors.mint,
          AppColors.forest,
          Icons.check_circle_outline_rounded,
        ),
      NoticeTone.warning => (
          AppColors.warningBg,
          AppColors.warningText,
          Icons.info_outline_rounded,
        ),
      NoticeTone.error => (
          AppColors.redBg,
          AppColors.red,
          Icons.error_outline_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon ?? defaultIcon, size: 17, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: fg,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MaintenanceGlobalBanner extends StatelessWidget {
  const MaintenanceGlobalBanner({
    super.key,
    required this.deviceNames,
    required this.onOpenMaintenance,
  });

  final List<String> deviceNames;
  final VoidCallback onOpenMaintenance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: AppColors.warningText,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perawatan aktif: ${deviceNames.join(', ')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warningText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Kontrol operasional, perpindahan mode, dan perubahan ambang batas perangkat ini dikunci untuk semua pengguna. Pembacaan saat kalibrasi bukan kondisi tandon.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.warningText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: OutlinedButton(
              onPressed: onOpenMaintenance,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.warningText,
                side: const BorderSide(color: AppColors.warningBorder),
              ),
              child: const Text(
                'Buka perawatan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
