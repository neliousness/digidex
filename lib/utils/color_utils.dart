import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class ColorUtils {
  static Color darken(Color c, [int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(c.alpha, (c.red * f).round(), (c.green * f).round(), (c.blue * f).round());
  }

  static Color getColor(PaletteGenerator generator, bool isVibrant) {
    if (isVibrant) {
      if (generator.vibrantColor != null) {
        return generator.vibrantColor!.color;
      } else {
        if (generator.darkVibrantColor != null) {
          return generator.darkVibrantColor!.color;
        } else {
          return Colors.black;
        }
      }
    } else {
      if (generator.dominantColor != null) {
        return generator.dominantColor!.color;
      } else {
        return Colors.black;
      }
    }
  }
}
