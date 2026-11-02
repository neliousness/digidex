import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/comic.dart';

/// A ring's ripple-in state: scale and opacity.
class Ripple {
  final double scale;
  final double opacity;

  const Ripple(this.scale, this.opacity);

  static const Ripple settled = Ripple(1, 1);

  static const Cubic _ease = Cubic(0.2, 0.9, 0.25, 1.2);

  /// The design's ripple: scale .55 → 1.07 (at 60%) → 1, fading in by 60%.
  /// As in CSS keyframes, the easing applies within each keyframe segment.
  static Ripple at(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.6) {
      final e = _ease.transform(t / 0.6);
      return Ripple(0.55 + 0.52 * e, e.clamp(0.0, 1.0));
    }
    return Ripple(1.07 - 0.07 * _ease.transform((t - 0.6) / 0.4), 1);
  }
}

enum RingsStyle { home, detail }

/// Draws the rings behind the drawn card (home) or the detail art. Radii are
/// the design's (390px wide), multiplied by [scale].
class RingsPainter extends CustomPainter {
  final RingsStyle style;
  final Offset center;
  final double scale;
  final Color color;

  /// The colour ring's ripple (outer on home).
  final Ripple outer;

  /// The white disc's ripple (home only).
  final Ripple disc;

  /// Spin of the dashed ring, 0..1 = one turn.
  final double spin;

  /// Counter-spin of the small dashed ring (home only), 0..1 = one turn.
  final double spinBack;

  const RingsPainter({
    required this.style,
    required this.center,
    required this.scale,
    required this.color,
    this.outer = Ripple.settled,
    this.disc = Ripple.settled,
    this.spin = 0,
    this.spinBack = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final home = style == RingsStyle.home;
    final ringRadius = (home ? 262 : 180) * scale;
    _colourRing(canvas, ringRadius, outer);
    _dashed(canvas, (home ? 229 : 152) * scale, 4 * scale, 14 * scale, 12 * scale, spin, round: false);
    if (home) {
      _disc(canvas, 200 * scale, disc);
      _dashed(canvas, 184 * scale, 3 * scale, 4 * scale, 10 * scale, -spinBack, round: true);
    }
  }

  void _colourRing(Canvas canvas, double r, Ripple ripple) {
    if (ripple.opacity <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(ripple.scale);
    final layer = ripple.opacity < 1;
    if (layer) canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, ripple.opacity));
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28 * scale
        ..color = Comic.ink,
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18 * scale
        ..color = color,
    );
    if (layer) canvas.restore();
    canvas.restore();
  }

  void _disc(Canvas canvas, double r, Ripple ripple) {
    if (ripple.opacity <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(ripple.scale);
    canvas.drawCircle(Offset.zero, r, Paint()..color = Comic.white.withValues(alpha: ripple.opacity));
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * scale
        ..color = Comic.ink.withValues(alpha: ripple.opacity),
    );
    canvas.restore();
  }

  /// Dashed rings drawn once each, then only rotated. Drawing every dash as
  /// its own arc made Impeller re-tessellate ~140 strokes every frame.
  static final Map<(double, double, double, double, bool), ui.Image> _dashedRings = {};

  static ui.Image _dashedRing(double r, double width, double dash, double gap, bool round) => _dashedRings.putIfAbsent((r, width, dash, gap, round), () {
    final pixelRatio = ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 3;
    final half = r + width;
    final px = (2 * half * pixelRatio).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = round ? StrokeCap.round : StrokeCap.butt
      ..color = Comic.ink;
    final count = (2 * math.pi * r / (dash + gap)).floor();
    final step = 2 * math.pi / count;
    final sweep = step * dash / (dash + gap);
    final rect = Rect.fromCircle(center: Offset(half, half), radius: r);
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * step, sweep, false, paint);
    }
    return recorder.endRecording().toImageSync(px, px);
  });

  void _dashed(Canvas canvas, double r, double width, double dash, double gap, double turns, {required bool round}) {
    // On the first frame the screen can still measure 0.
    if (r <= 0 || dash + gap <= 0) return;
    final image = _dashedRing(r, width, dash, gap, round);
    final half = r + width;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(turns * 2 * math.pi);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Rect.fromCircle(center: Offset.zero, radius: half),
      Paint()..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(RingsPainter old) =>
      old.center != center ||
      old.scale != scale ||
      old.color != color ||
      old.spin != spin ||
      old.spinBack != spinBack ||
      old.outer.scale != outer.scale ||
      old.outer.opacity != outer.opacity ||
      old.disc.scale != disc.scale ||
      old.disc.opacity != disc.opacity;
}
