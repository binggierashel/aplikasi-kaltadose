import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

enum BadgeTone { mint, offline, warning, owner, danger, heroOnline, heroOffline }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.mint,
    this.showDot = false,
  });

  final String label;
  final BadgeTone tone;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.mint => (AppColors.mint, AppColors.green),
      BadgeTone.offline => (AppColors.offlineBg, AppColors.muted),
      BadgeTone.warning => (AppColors.orangeBg, AppColors.orange),
      BadgeTone.owner => (AppColors.blueBg, AppColors.blue),
      BadgeTone.danger => (AppColors.redBg, AppColors.red),
      BadgeTone.heroOnline => (
          const Color(0x28FFFFFF),
          const Color(0xFFE9F5DF),
        ),
      BadgeTone.heroOffline => (
          const Color(0x24FFFFFF),
          const Color(0xFFD1DBD6),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
