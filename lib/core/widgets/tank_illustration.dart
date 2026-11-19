import 'package:material_ui/material_ui.dart';

class TankIllustration extends StatelessWidget {
  const TankIllustration({
    super.key,
    this.width = 124,
    this.height = 90,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _TankArtPainter()),
    );
  }
}

class _TankArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240.0;
    final sy = size.height / 160.0;
    final s = (sx + sy) / 2.0;

    // Ground line
    canvas.drawLine(
      Offset(33 * sx, 140 * sy),
      Offset(217 * sx, 140 * sy),
      Paint()
        ..color = const Color(0xFF82A58A)
        ..strokeWidth = 1.5 * s
        ..style = PaintingStyle.stroke,
    );

    // Tank body
    final bodyPath = Path()
      ..moveTo(68 * sx, 68 * sy)
      ..lineTo(68 * sx, 123 * sy)
      ..cubicTo(68 * sx, 135 * sy, 160 * sx, 135 * sy, 160 * sx, 123 * sy)
      ..lineTo(160 * sx, 68 * sy);

    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFEAF2D9)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFF8EB59A)
        ..strokeWidth = 2.0 * s
        ..style = PaintingStyle.stroke,
    );

    // Top rim ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(114 * sx, 68 * sy),
        width: 92 * sx,
        height: 24 * sy,
      ),
      Paint()..color = const Color(0xFFF5F8E8),
    );

    // Nutrient liquid fill
    final liquidPath = Path()
      ..moveTo(71 * sx, 93 * sy)
      ..quadraticBezierTo(116 * sx, 110 * sy, 157 * sx, 93 * sy)
      ..lineTo(157 * sx, 123 * sy)
      ..quadraticBezierTo(115 * sx, 143 * sy, 71 * sx, 123 * sy)
      ..close();
    canvas.drawPath(liquidPath, Paint()..color = const Color(0xFF8EBBA1));

    // Liquid surface ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(114 * sx, 93 * sy),
        width: 86 * sx,
        height: 20 * sy,
      ),
      Paint()..color = const Color(0xFFB5D2BB),
    );

    // Right lime dosing pipe & valve
    final rightPipe = Path()
      ..moveTo(157 * sx, 111 * sy)
      ..lineTo(187 * sx, 111 * sy)
      ..lineTo(187 * sx, 51 * sy)
      ..lineTo(135 * sx, 51 * sy);
    canvas.drawPath(
      rightPipe,
      Paint()
        ..color = const Color(0xFFDCEB9C)
        ..strokeWidth = 7.0 * s
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(176 * sx, 78 * sy, 23 * sx, 16 * sy),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFFDCEB9C),
    );

    // Melon stems
    final stemPaint = Paint()
      ..color = const Color(0xFF77A87D)
      ..strokeWidth = 3.0 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(97 * sx, 67 * sy),
      Offset(97 * sx, 40 * sy),
      stemPaint,
    );
    canvas.drawLine(
      Offset(127 * sx, 67 * sy),
      Offset(127 * sx, 38 * sy),
      stemPaint,
    );

    // Leaves
    final leafPaint = Paint()..color = const Color(0xFFB6D48B);
    final leaves = Path()
      ..moveTo(98 * sx, 51 * sy)
      ..quadraticBezierTo(72 * sx, 51 * sy, 80 * sx, 31 * sy)
      ..quadraticBezierTo(103 * sx, 30 * sy, 98 * sx, 51 * sy)
      ..close()
      ..moveTo(98 * sx, 45 * sy)
      ..quadraticBezierTo(123 * sx, 43 * sy, 117 * sx, 23 * sy)
      ..quadraticBezierTo(94 * sx, 24 * sy, 98 * sx, 45 * sy)
      ..close()
      ..moveTo(127 * sx, 46 * sy)
      ..quadraticBezierTo(105 * sx, 45 * sy, 107 * sx, 25 * sy)
      ..quadraticBezierTo(130 * sx, 26 * sy, 127 * sx, 46 * sy)
      ..close()
      ..moveTo(127 * sx, 41 * sy)
      ..quadraticBezierTo(148 * sx, 40 * sy, 147 * sx, 21 * sy)
      ..quadraticBezierTo(124 * sx, 21 * sy, 127 * sx, 41 * sy)
      ..close();
    canvas.drawPath(leaves, leafPaint);

    // Left peristaltic pump & pipe
    final leftPipe = Path()
      ..moveTo(40 * sx, 51 * sy)
      ..lineTo(40 * sx, 126 * sy)
      ..lineTo(68 * sx, 126 * sy)
      ..moveTo(40 * sx, 50 * sy)
      ..lineTo(66 * sx, 50 * sy);
    canvas.drawPath(
      leftPipe,
      Paint()
        ..color = const Color(0xFFA9C7AD)
        ..strokeWidth = 4.0 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(23 * sx, 58 * sy, 32 * sx, 30 * sy),
        Radius.circular(7 * s),
      ),
      Paint()..color = const Color(0xFFC7DDA8),
    );
    canvas.drawCircle(
      Offset(39 * sx, 73 * sy),
      7 * s,
      Paint()
        ..color = const Color(0xFF164F43)
        ..strokeWidth = 2.0 * s
        ..style = PaintingStyle.stroke,
    );

    // Bubbles
    final bubblePaint = Paint()..color = const Color(0xFFEAF2D9);
    canvas.drawCircle(Offset(102 * sx, 107 * sy), 2.3 * s, bubblePaint);
    canvas.drawCircle(Offset(130 * sx, 119 * sy), 3.0 * s, bubblePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
