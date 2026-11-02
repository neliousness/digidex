import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Design tokens for the "Comic Hand + Rings" design.
class Comic {
  static const Color ink = Color(0xFF0B0B14);
  static const Color yellow = Color(0xFFFFE14D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFF3D3D4A);
  static const Color body = Color(0xFF2A2A36);
  static const Color adGrey = Color(0xFFF2F2F2);

  /// The comic swatches. Every Digimon's colour is snapped to one of these.
  static const List<Color> swatches = [
    Color(0xFFFF8A1F), // orange
    Color(0xFF00B7FF), // blue
    Color(0xFFFF3D7F), // red-pink
    Color(0xFF7CF05A), // green
    Color(0xFFA66BFF), // purple
    Color(0xFFFFE14D), // yellow
    Color(0xFF00E0C6), // teal
    Color(0xFFFF6FB5), // pink
  ];

  static const String display = 'BricolageGrotesque';
  static const String sans = 'DMSans';

  /// Display type: Bricolage Grotesque 800, uppercase (callers upper-case).
  static TextStyle displayStyle(double size, {Color color = ink, double height = 1}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        height: height,
        color: color,
        fontWeight: FontWeight.w800,
        fontVariations: [const FontVariation('wght', 800), FontVariation('opsz', size.clamp(12, 96).toDouble())],
      );

  /// Body type: DM Sans at weight [weight] (400, 500, 700 or 800).
  static TextStyle sansStyle(double size, {double weight = 400, Color color = ink, double? height, double letterSpacing = 0}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        height: height,
        color: color,
        letterSpacing: letterSpacing,
        fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
        fontVariations: [FontVariation('wght', weight), FontVariation('opsz', size.clamp(9, 40).toDouble())],
      );

  /// The light tint used behind the detail hero: [color] mixed ~35% with white.
  static Color light(Color color) => Color.lerp(Colors.white, color, 0.6)!;

  /// The swatch at [index], wrapping, for cycling colours by position.
  static Color cycle(int index) => swatches[index % swatches.length];

  /// A stable swatch for a Digimon whose art has no strong colour. Never
  /// yellow, which would vanish on the yellow Home and Browse grounds.
  static Color forId(int id) {
    const options = [0, 1, 2, 3, 4, 6, 7];
    return swatches[options[id.abs() % options.length]];
  }

  static Color attributeColor(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'vaccine':
        return swatches[1];
      case 'data':
        return swatches[6];
      case 'virus':
        return swatches[2];
      case 'free':
        return swatches[3];
      case 'variable':
        return swatches[4];
      default:
        return white;
    }
  }
}

/// Picks the comic swatch that best matches the colours of a cut-out image.
class ComicColor {
  // Hues of [Comic.swatches], precomputed so this runs in an isolate without dart:ui.
  static const List<double> _swatchHues = [28.7, 196.9, 339.6, 106.4, 263.9, 49.9, 173.0, 330.8];

  static const int _yellow = 5, _orange = 0;

  /// Index into [Comic.swatches] for the most common colour among the opaque,
  /// saturated pixels of [rgba], or null if the art is mostly grey/white/black.
  ///
  /// Yellow pixels don't vote: yellow highlights (horns, gloves, beaks) would
  /// otherwise win for most Digimon, and yellow is the Home/Browse ground, so
  /// a yellow card would disappear on it. Mostly-yellow art gets orange.
  static int? swatchIndex(Uint8List rgba) {
    final votes = List<int>.filled(Comic.swatches.length, 0);
    var opaque = 0;
    // Every 2nd pixel is plenty for a colour vote and halves the cost.
    for (var p = 0; p + 3 < rgba.length; p += 8) {
      if (rgba[p + 3] < 230) continue;
      opaque++;
      final r = rgba[p] / 255, g = rgba[p + 1] / 255, b = rgba[p + 2] / 255;
      final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final delta = max - min;
      if (max < 0.3 || delta / max < 0.25) continue;
      double hue;
      if (max == r) {
        hue = 60 * (((g - b) / delta) % 6);
      } else if (max == g) {
        hue = 60 * ((b - r) / delta + 2);
      } else {
        hue = 60 * ((r - g) / delta + 4);
      }
      votes[nearestHue(hue)]++;
    }
    if (opaque == 0) return null;
    final enough = opaque * 0.06;
    var best = -1;
    for (var i = 0; i < votes.length; i++) {
      if (i == _yellow) continue;
      if (best == -1 || votes[i] > votes[best]) best = i;
    }
    if (votes[best] >= enough) return best;
    return votes[_yellow] >= enough ? _orange : null;
  }

  /// Index of the swatch whose hue is closest to [hue] (degrees).
  static int nearestHue(double hue) {
    var best = 0;
    var bestDistance = 361.0;
    for (var i = 0; i < _swatchHues.length; i++) {
      final d = (hue - _swatchHues[i]).abs();
      final distance = d > 180 ? 360 - d : d;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }
}
