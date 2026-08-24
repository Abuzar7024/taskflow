import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Which illustration to draw. One flat, geometric visual language shared by
/// empty states, errors and the profile header.
enum AppArt { tasks, projects, workspace, user, success, error, offline, inbox }

/// Small custom vector objects, drawn rather than shipped as assets.
///
/// They stay legible at any size, follow the theme, and add nothing to the
/// bundle. Deliberately abstract: shapes and a single accent, never a stock
/// scene or a mascot.
class AppIllustration extends StatelessWidget {
  const AppIllustration({super.key, required this.art, this.size = 96});

  final AppArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).c;
    final accent = switch (art) {
      AppArt.success => c.success,
      AppArt.error => c.error,
      AppArt.offline => c.warning,
      _ => c.primary,
    };

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArtPainter(
          art: art,
          accent: accent,
          surface: c.wash(accent),
          line: c.borderStrong,
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter({
    required this.art,
    required this.accent,
    required this.surface,
    required this.line,
  });

  final AppArt art;
  final Color accent;
  final Color surface;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100; // Draw on a 100x100 grid, then scale.
    final fill = Paint()..color = surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * u
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.round
      ..color = line;

    switch (art) {
      case AppArt.tasks:
        _rrect(canvas, 18 * u, 16 * u, 64 * u, 68 * u, 8 * u, fill);
        for (var i = 0; i < 3; i++) {
          final y = (32 + i * 18) * u;
          canvas.drawCircle(Offset(32 * u, y), 4 * u, Paint()..color = accent);
          canvas.drawLine(
            Offset(42 * u, y),
            Offset((i == 2 ? 62 : 70) * u, y),
            i == 0 ? stroke : soft,
          );
        }
      case AppArt.projects:
        _rrect(canvas, 14 * u, 30 * u, 72 * u, 52 * u, 8 * u, fill);
        // Folder tab.
        _rrect(canvas, 14 * u, 22 * u, 34 * u, 14 * u, 5 * u, Paint()..color = accent);
        canvas.drawLine(Offset(28 * u, 52 * u), Offset(72 * u, 52 * u), soft);
        canvas.drawLine(Offset(28 * u, 64 * u), Offset(58 * u, 64 * u), stroke);
      case AppArt.workspace:
        _rrect(canvas, 12 * u, 20 * u, 76 * u, 50 * u, 7 * u, fill);
        canvas.drawLine(Offset(12 * u, 34 * u), Offset(88 * u, 34 * u), soft);
        canvas.drawCircle(Offset(22 * u, 27 * u), 3 * u, Paint()..color = accent);
        _rrect(canvas, 24 * u, 46 * u, 24 * u, 14 * u, 4 * u, Paint()..color = accent);
        canvas.drawLine(Offset(56 * u, 50 * u), Offset(76 * u, 50 * u), soft);
        canvas.drawLine(Offset(56 * u, 58 * u), Offset(68 * u, 58 * u), soft);
        canvas.drawLine(Offset(38 * u, 70 * u), Offset(62 * u, 70 * u), stroke);
      case AppArt.user:
        canvas.drawCircle(Offset(50 * u, 50 * u), 34 * u, fill);
        canvas.drawCircle(Offset(50 * u, 40 * u), 12 * u, Paint()..color = accent);
        final body = Path()
          ..moveTo(28 * u, 76 * u)
          ..arcToPoint(Offset(72 * u, 76 * u), radius: Radius.circular(24 * u));
        canvas.drawPath(body, Paint()..color = accent);
      case AppArt.inbox:
        _rrect(canvas, 16 * u, 34 * u, 68 * u, 44 * u, 8 * u, fill);
        final flap = Path()
          ..moveTo(16 * u, 40 * u)
          ..lineTo(50 * u, 60 * u)
          ..lineTo(84 * u, 40 * u);
        canvas.drawPath(flap, stroke);
        canvas.drawCircle(Offset(74 * u, 30 * u), 8 * u, Paint()..color = accent);
      case AppArt.success:
        canvas.drawCircle(Offset(50 * u, 50 * u), 32 * u, fill);
        final tick = Path()
          ..moveTo(36 * u, 51 * u)
          ..lineTo(46 * u, 61 * u)
          ..lineTo(65 * u, 40 * u);
        canvas.drawPath(tick, stroke..strokeWidth = 4 * u);
      case AppArt.error:
        canvas.drawCircle(Offset(50 * u, 50 * u), 32 * u, fill);
        canvas.drawLine(Offset(50 * u, 34 * u), Offset(50 * u, 54 * u),
            stroke..strokeWidth = 4 * u);
        canvas.drawCircle(Offset(50 * u, 65 * u), 3 * u, Paint()..color = accent);
      case AppArt.offline:
        canvas.drawCircle(Offset(50 * u, 50 * u), 32 * u, fill);
        for (var i = 0; i < 3; i++) {
          final r = (10 + i * 9) * u;
          canvas.drawArc(
            Rect.fromCircle(center: Offset(50 * u, 62 * u), radius: r),
            3.6,
            1.9,
            false,
            soft,
          );
        }
        canvas.drawCircle(Offset(50 * u, 62 * u), 3.5 * u, Paint()..color = accent);
        // The slash that marks the connection as down.
        canvas.drawLine(Offset(32 * u, 74 * u), Offset(68 * u, 30 * u),
            stroke..strokeWidth = 3.4 * u);
    }
  }

  void _rrect(Canvas canvas, double x, double y, double w, double h,
      double r, Paint paint) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.art != art || old.accent != accent || old.surface != surface;
}
