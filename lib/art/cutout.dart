import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Removes the solid white background from Digi-API artwork.
///
/// Every API image is a 320×320 PNG on white. Only near-white pixels that are
/// connected to the image border are background, so white inside the outline
/// (eyes, white bodies, robes) stays opaque. Pure Dart, so it can run in an
/// isolate.
class Cutout {
  /// min(R,G,B) at or above this is a background candidate.
  static const int whiteThreshold = 236;

  /// Width of the soft edge, in pixels, around the removed background.
  static const int edgeBand = 2;

  /// Alpha in the edge band goes from 0 (white) to 1 at this distance from white.
  static const double edgeRange = 85;

  /// Returns a copy of [rgba] (4 bytes per pixel) with the background removed
  /// and white un-mixed from the soft edge, so no white halo is left.
  static Uint8List removeBackground(Uint8List rgba, int width, int height) {
    final n = width * height;
    final minC = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final p = i * 4;
      minC[i] = math.min(rgba[p], math.min(rgba[p + 1], rgba[p + 2]));
    }

    // Background: 4-connected near-white pixels reachable from the border.
    final bg = Uint8List(n);
    final queue = Int32List(n);
    var head = 0, tail = 0;
    void seed(int i) {
      if (bg[i] == 0 && minC[i] >= whiteThreshold) {
        bg[i] = 1;
        queue[tail++] = i;
      }
    }

    for (var x = 0; x < width; x++) {
      seed(x);
      seed((height - 1) * width + x);
    }
    for (var y = 0; y < height; y++) {
      seed(y * width);
      seed(y * width + width - 1);
    }
    while (head < tail) {
      final i = queue[head++];
      final x = i % width, y = i ~/ width;
      if (x > 0) seed(i - 1);
      if (x < width - 1) seed(i + 1);
      if (y > 0) seed(i - width);
      if (y < height - 1) seed(i + width);
    }

    // Edge band: pixels within [edgeBand] 4-connected steps of the background.
    final band = _dilate(bg, width, height, edgeBand);

    final out = Uint8List(n * 4);
    for (var i = 0; i < n; i++) {
      final p = i * 4;
      double a;
      if (bg[i] == 1) {
        a = 0;
      } else if (band[i] == 1) {
        a = math.min(1, ((255 - minC[i]) / edgeRange).clamp(0, 1).toDouble());
      } else {
        a = 1;
      }
      if (a == 0) continue; // fully transparent, stays 0,0,0,0
      if (a == 1) {
        out[p] = rgba[p];
        out[p + 1] = rgba[p + 1];
        out[p + 2] = rgba[p + 2];
        out[p + 3] = 255;
        continue;
      }
      final safe = math.max(a, 0.001);
      for (var c = 0; c < 3; c++) {
        out[p + c] = ((rgba[p + c] - (1 - a) * 255) / safe).clamp(0, 255).round();
      }
      out[p + 3] = (a * 255).round();
    }
    return out;
  }

  /// Pixels that are not in [mask] but within [steps] 4-connected steps of it
  /// (the same as scipy's binary_dilation with the default cross, minus [mask]).
  static Uint8List _dilate(Uint8List mask, int width, int height, int steps) {
    var current = Uint8List.fromList(mask);
    for (var s = 0; s < steps; s++) {
      final next = Uint8List.fromList(current);
      for (var i = 0; i < mask.length; i++) {
        if (current[i] == 1) continue;
        final x = i % width, y = i ~/ width;
        if ((x > 0 && current[i - 1] == 1) ||
            (x < width - 1 && current[i + 1] == 1) ||
            (y > 0 && current[i - width] == 1) ||
            (y < height - 1 && current[i + width] == 1)) {
          next[i] = 1;
        }
      }
      current = next;
    }
    for (var i = 0; i < mask.length; i++) {
      if (mask[i] == 1) current[i] = 0;
    }
    return current;
  }

  /// Bakes a die-cut sticker: a white rim [rim] pixels wide under the art,
  /// following its outline. The canvas grows by [rim] + 1 on each side so the
  /// rim is never cut off. Returns the new RGBA bytes and size.
  static ({Uint8List rgba, int width, int height}) sticker(Uint8List rgba, int width, int height, {required int rim}) {
    final pad = rim + 1;
    final w = width + 2 * pad, h = height + 2 * pad;
    final n = w * h;
    const inf = 1 << 20;

    // Chamfer (3-4) distance, in thirds of a pixel, to the nearest art pixel.
    final dist = Int32List(n)..fillRange(0, n, inf);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (rgba[(y * width + x) * 4 + 3] >= 128) dist[(y + pad) * w + x + pad] = 0;
      }
    }
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        var d = dist[i];
        if (x > 0) d = math.min(d, dist[i - 1] + 3);
        if (y > 0) {
          d = math.min(d, dist[i - w] + 3);
          if (x > 0) d = math.min(d, dist[i - w - 1] + 4);
          if (x < w - 1) d = math.min(d, dist[i - w + 1] + 4);
        }
        dist[i] = d;
      }
    }
    for (var y = h - 1; y >= 0; y--) {
      for (var x = w - 1; x >= 0; x--) {
        final i = y * w + x;
        var d = dist[i];
        if (x < w - 1) d = math.min(d, dist[i + 1] + 3);
        if (y < h - 1) {
          d = math.min(d, dist[i + w] + 3);
          if (x < w - 1) d = math.min(d, dist[i + w + 1] + 4);
          if (x > 0) d = math.min(d, dist[i + w - 1] + 4);
        }
        dist[i] = d;
      }
    }

    final out = Uint8List(n * 4);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final o = i * 4;
        // White rim, anti-aliased over its last half pixel.
        final rimA = (rim + 0.5 - dist[i] / 3).clamp(0.0, 1.0);
        final sx = x - pad, sy = y - pad;
        var ar = 0.0, ag = 0.0, ab = 0.0, aa = 0.0;
        if (sx >= 0 && sy >= 0 && sx < width && sy < height) {
          final s = (sy * width + sx) * 4;
          aa = rgba[s + 3] / 255;
          ar = rgba[s].toDouble();
          ag = rgba[s + 1].toDouble();
          ab = rgba[s + 2].toDouble();
        }
        // Art over white: colour = art·a + 255·rim·(1-a), alpha = a + rim·(1-a).
        final outA = aa + rimA * (1 - aa);
        if (outA <= 0) continue;
        out[o] = ((ar * aa + 255 * rimA * (1 - aa)) / outA).round().clamp(0, 255);
        out[o + 1] = ((ag * aa + 255 * rimA * (1 - aa)) / outA).round().clamp(0, 255);
        out[o + 2] = ((ab * aa + 255 * rimA * (1 - aa)) / outA).round().clamp(0, 255);
        out[o + 3] = (outA * 255).round();
      }
    }
    return (rgba: out, width: w, height: h);
  }

  /// Decodes [png], removes the background and returns RGBA bytes, or null if
  /// the bytes aren't an image.
  static ({Uint8List rgba, int width, int height})? decode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final rgbaImage = decoded.numChannels == 4 && decoded.format == img.Format.uint8 ? decoded : decoded.convert(format: img.Format.uint8, numChannels: 4, alpha: 255);
    final raw = rgbaImage.getBytes(order: img.ChannelOrder.rgba);
    return (rgba: removeBackground(raw, rgbaImage.width, rgbaImage.height), width: rgbaImage.width, height: rgbaImage.height);
  }

  static Uint8List encodePng(Uint8List rgba, int width, int height) {
    final image = img.Image.fromBytes(width: width, height: height, bytes: rgba.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
    return img.encodePng(image, level: 6);
  }
}
