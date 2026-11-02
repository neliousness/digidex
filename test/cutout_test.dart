import 'dart:math' as math;
import 'dart:typed_data';

import 'package:digidexplus/art/art_service.dart';
import 'package:digidexplus/art/cutout.dart';
import 'package:digidexplus/theme/comic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A [size]×[size] RGBA image filled by [color] (x, y) → [r, g, b].
Uint8List paint(int size, List<int> Function(int x, int y) color) {
  final out = Uint8List(size * size * 4);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final c = color(x, y);
      final p = (y * size + x) * 4;
      out[p] = c[0];
      out[p + 1] = c[1];
      out[p + 2] = c[2];
      out[p + 3] = 255;
    }
  }
  return out;
}

List<int> pixel(Uint8List rgba, int size, int x, int y) {
  final p = (y * size + x) * 4;
  return [rgba[p], rgba[p + 1], rgba[p + 2], rgba[p + 3]];
}

void main() {
  group('Cutout.removeBackground', () {
    test('keeps white enclosed by the outline and removes the outside', () {
      // White background, a black ring (radius 12–14), white inside the ring.
      const size = 40;
      final rgba = paint(size, (x, y) {
        final d = math.sqrt(math.pow(x - 20, 2) + math.pow(y - 20, 2));
        return d >= 12 && d <= 14 ? [0, 0, 0] : [255, 255, 255];
      });

      final out = Cutout.removeBackground(rgba, size, size);

      expect(pixel(out, size, 0, 0)[3], 0, reason: 'corner is background');
      expect(pixel(out, size, 3, 20)[3], 0, reason: 'outside the ring is background');
      expect(pixel(out, size, 20, 20), [255, 255, 255, 255], reason: 'white inside the outline stays opaque white');
      expect(pixel(out, size, 20, 7), [0, 0, 0, 255], reason: 'the ring itself is untouched');
    });

    test('a semi-white edge pixel gets the right alpha and the white un-mixed', () {
      // Black square at x,y 15..24; one grey (200) pixel just left of it at (14, 20),
      // next to the white background, so it falls in the soft edge band.
      const size = 40;
      final rgba = paint(size, (x, y) {
        if (x >= 15 && x <= 24 && y >= 15 && y <= 24) return [0, 0, 0];
        if (x == 14 && y == 20) return [200, 200, 200];
        return [255, 255, 255];
      });

      final out = Cutout.removeBackground(rgba, size, size);
      final edge = pixel(out, size, 14, 20);

      // alpha = (255 - 200) / 85 = 0.647; rgb = (200 - (1 - 0.647) * 255) / 0.647 = 170.
      expect(edge[3], (55 / 85 * 255).round());
      expect(edge.sublist(0, 3), [170, 170, 170]);
      expect(pixel(out, size, 20, 20), [0, 0, 0, 255]);
    });

    test('an all-white image becomes fully transparent without crashing', () {
      const size = 16;
      final out = Cutout.removeBackground(paint(size, (x, y) => [255, 255, 255]), size, size);
      expect(out.every((b) => b == 0), isTrue);
      expect(ComicColor.swatchIndex(out), isNull);
      final sticker = Cutout.sticker(out, size, size, rim: 3);
      expect(sticker.rgba.every((b) => b == 0), isTrue);
    });
  });

  group('Cutout.sticker', () {
    test('adds a white rim of the given width around the art', () {
      // A single opaque red pixel in the middle of a transparent 21×21 image.
      const size = 21;
      final rgba = Uint8List(size * size * 4);
      final c = (10 * size + 10) * 4;
      rgba[c] = 255;
      rgba[c + 3] = 255;

      final s = Cutout.sticker(rgba, size, size, rim: 3);
      const pad = 4;
      expect(s.width, size + 2 * pad);
      List<int> at(int x, int y) => pixel(s.rgba, s.width, x + pad, y + pad);

      expect(at(10, 10), [255, 0, 0, 255], reason: 'art stays on top');
      expect(at(12, 10), [255, 255, 255, 255], reason: '2px away is inside the rim');
      expect(at(15, 10)[3], 0, reason: '5px away is outside the rim');
    });
  });

  group('ComicColor', () {
    test('snaps a strongly coloured cut-out to the nearest swatch', () {
      final orange = paint(8, (x, y) => [250, 140, 40]);
      final blue = paint(8, (x, y) => [10, 170, 240]);
      expect(ComicColor.swatchIndex(orange), 0);
      expect(ComicColor.swatchIndex(blue), 1);
    });

    test('yellow highlights do not win; all-yellow art gets orange', () {
      // Purple body with a yellow area twice its size (like Gabumon's horn and fur).
      final mixed = paint(12, (x, y) => x < 4 ? [160, 100, 250] : [255, 215, 60]);
      expect(ComicColor.swatchIndex(mixed), 4, reason: 'purple');
      expect(ComicColor.swatchIndex(paint(8, (x, y) => [255, 220, 70])), 0, reason: 'orange, never yellow');
    });

    test('mostly grey or white art has no swatch', () {
      expect(ComicColor.swatchIndex(paint(8, (x, y) => [180, 180, 185])), isNull);
    });
  });

  test('processArt turns a white-background PNG into a sticker and a colour', () {
    // Green disc on white, as the API serves it.
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    img.fillCircle(image, x: 16, y: 16, radius: 8, color: img.ColorRgb8(110, 230, 80));
    final result = processArt(img.encodePng(image))!;

    final sticker = img.decodePng(result.png)!;
    expect(sticker.width, 32 + 2 * 3, reason: 'rim of 2px (min) plus 1px padding on each side');
    expect(sticker.getPixel(0, 0).a, 0, reason: 'background removed');
    expect(sticker.getPixel(19, 19).a, 255, reason: 'disc kept');
    expect(result.swatch, 3, reason: 'green');
    expect(processArt(Uint8List.fromList([1, 2, 3])), isNull, reason: 'not an image');
  });
}
