import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class KaltaFarmBrand extends StatelessWidget {
  const KaltaFarmBrand({
    super.key,
    this.iconSize = 34,
    this.fontSize = 20,
    this.textColor = AppColors.ink,
  });

  final double iconSize;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14164F43),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.jpeg',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.forest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.eco_rounded,
                  size: iconSize * 0.56,
                  color: AppColors.lime,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppFonts.manrope(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
                color: textColor,
              ),
              children: const [
                TextSpan(text: 'Kalta Dose'),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: AppColors.brandDot),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
