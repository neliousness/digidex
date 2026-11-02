import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'comic.dart';

/// [name] with a line-break opportunity before a bracket that follows a
/// word, so "Aegiochusmon(Holy)" can wrap as "Aegiochusmon / (Holy)".
String breakableName(String name) => name.replaceAllMapped(RegExp(r'(?<=\S)\('), (_) => '​(');

/// The largest display size, up to [maxSize], at which the longest word of
/// [text] fits in [width], so names wrap between words, never inside one.
double fitLongestWord(String text, {required double maxSize, required double width}) {
  final longest = text.split(RegExp(r'[\s(\-​]+')).fold<int>(0, (m, w) => w.length > m ? w.length : m);
  if (longest == 0) return maxSize;
  // Bricolage Grotesque 800 caps, slanted: up to ~0.8em per letter (M, W).
  final fit = width / (longest * 0.8);
  return fit < maxSize ? fit : maxSize;
}

/// Whether to run decorative motion (spins, ripples, card flights).
bool comicMotion(BuildContext context) => !MediaQuery.disableAnimationsOf(context);

/// Halftone dots: radius [dotRadius] on a [spacing] grid, ink at [opacity].
class HalftonePainter extends CustomPainter {
  final double dotRadius;
  final double spacing;
  final double opacity;

  const HalftonePainter({this.dotRadius = 1.8, this.spacing = 9, this.opacity = 0.15});

  /// Pixels per logical pixel in the tile: sharp on 3x screens, scaled down elsewhere.
  static const double _tileScale = 3;
  static final Map<(double, double, double), ui.Image> _tiles = {};

  /// One cell of the pattern, a dot centred in a [spacing]-square, drawn once.
  /// Repeating it as a shader is a single textured fill; drawing the dots one
  /// by one made Impeller build thousands of circles every frame.
  static ui.Image _tile(double dotRadius, double spacing, double opacity) => _tiles.putIfAbsent((dotRadius, spacing, opacity), () {
    final px = (spacing * _tileScale).round();
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawCircle(Offset(px / 2, px / 2), dotRadius * _tileScale, Paint()..color = Comic.ink.withValues(alpha: opacity));
    return recorder.endRecording().toImageSync(px, px);
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (spacing <= 0 || size.isEmpty) return;
    final tile = _tile(dotRadius, spacing, opacity);
    // Scale the tile back to exactly [spacing] logical pixels so the grid
    // lines up with the old dots (centred at spacing / 2).
    final scale = spacing / tile.width;
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..shader = ImageShader(tile, TileMode.repeated, TileMode.repeated, Matrix4.diagonal3Values(scale, scale, 1).storage);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(HalftonePainter old) => old.dotRadius != dotRadius || old.spacing != spacing || old.opacity != opacity;
}

/// A colour fill with halftone dots over it.
class Halftone extends StatelessWidget {
  final Color color;
  final Widget? child;
  final double dotRadius;
  final double spacing;
  final double opacity;

  const Halftone({super.key, required this.color, this.child, this.dotRadius = 1.8, this.spacing = 9, this.opacity = 0.15});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: CustomPaint(
        isComplex: true,
        painter: HalftonePainter(dotRadius: dotRadius, spacing: spacing, opacity: opacity),
        child: child ?? const SizedBox.expand(),
      ),
    );
  }
}

/// Slants display text like the design's synthesized italic (Bricolage
/// Grotesque has no italic face).
class Slant extends StatelessWidget {
  final Widget child;

  const Slant({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Transform(transform: Matrix4.skewX(-0.21), alignment: Alignment.center, child: child);
}

/// Display text with a white fill, an ink stroke and a hard ink shadow.
class OutlinedText extends StatelessWidget {
  final String text;
  final double size;
  final double stroke;
  final double shadow;
  final Color fill;
  final TextAlign textAlign;
  final double height;
  final int? maxLines;

  const OutlinedText(
    this.text, {
    super.key,
    required this.size,
    this.stroke = 1.5,
    this.shadow = 3,
    this.fill = Comic.white,
    this.textAlign = TextAlign.left,
    this.height = 0.95,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final upper = text.toUpperCase();
    final base = Comic.displayStyle(size, height: height);
    Text layer(TextStyle style) =>
        Text(upper, style: style, textAlign: textAlign, maxLines: maxLines, overflow: maxLines == null ? null : TextOverflow.ellipsis);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 2
      ..strokeJoin = StrokeJoin.round
      ..color = Comic.ink;
    return Slant(
      child: Stack(
        children: [
          // Hard shadow: the outlined glyphs again, offset, in ink.
          Transform.translate(
            offset: Offset(shadow, shadow),
            child: layer(base.copyWith(foreground: outline)),
          ),
          Transform.translate(
            offset: Offset(shadow, shadow),
            child: layer(base.copyWith(color: Comic.ink)),
          ),
          layer(base.copyWith(foreground: outline)),
          layer(base.copyWith(color: fill)),
        ],
      ),
    );
  }
}

/// A small label box: ink with yellow/white text, or bordered, slightly rotated.
class ComicTag extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;
  final double rotation;
  final bool bordered;
  final double fontSize;
  final EdgeInsets padding;
  final double weight;

  const ComicTag(
    this.text, {
    super.key,
    this.background = Comic.ink,
    this.color = Comic.yellow,
    this.rotation = 0,
    this.bordered = false,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.weight = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * 3.1415926535 / 180,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: bordered ? Border.all(color: Comic.ink, width: 3) : null,
        ),
        child: Padding(
          padding: bordered ? padding - const EdgeInsets.symmetric(vertical: 2) : padding,
          child: Text(
            text.toUpperCase(),
            style: Comic.sansStyle(fontSize, weight: weight, color: color, letterSpacing: fontSize * 0.06, height: 1.2),
          ),
        ),
      ),
    );
  }
}

/// A bordered surface with a hard offset shadow.
class ComicPanel extends StatelessWidget {
  final Widget child;
  final Color color;
  final double border;
  final double radius;
  final double shadow;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;

  const ComicPanel({
    super.key,
    required this.child,
    this.color = Comic.white,
    this.border = 4,
    this.radius = 16,
    this.shadow = 5,
    this.shadowColor = Comic.ink,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Comic.ink, width: border),
        boxShadow: shadow > 0 ? [BoxShadow(color: shadowColor, offset: Offset(shadow, shadow))] : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The round white button with an ink ring and shadow (back, search, heart).
class ComicRoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color iconColor;
  final double size;

  const ComicRoundButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.color = Comic.white,
    this.iconColor = Comic.ink,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Comic.ink, width: 3),
            boxShadow: const [BoxShadow(color: Comic.ink, offset: Offset(3, 3))],
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
      ),
    );
  }
}

/// A full-width comic button (e.g. "See all 98 evolutions").
class ComicButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double height;
  final double fontSize;

  const ComicButton(this.label, {super.key, this.onPressed, this.color = Comic.white, this.height = 54, this.fontSize = 18});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: ComicPanel(
          color: color,
          radius: 14,
          child: SizedBox(
            height: height - 8,
            child: Center(
              child: Slant(child: Text(label.toUpperCase(), style: Comic.displayStyle(fontSize))),
            ),
          ),
        ),
      ),
    );
  }
}

/// The section heading tag ("STAGE", "FIELDS · 6").
class SectionTag extends StatelessWidget {
  final String text;

  const SectionTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ComicTag(text, rotation: -2, fontSize: 13, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
  );
}

/// The bottom ad frame: a 66px white bar with a 5px ink top border, shown
/// only while it has something in it.
class AdBar extends StatelessWidget {
  final Widget child;

  const AdBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Comic.white,
        border: Border(top: BorderSide(color: Comic.ink, width: 5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(height: 61, child: Center(child: child)),
      ),
    );
  }
}
