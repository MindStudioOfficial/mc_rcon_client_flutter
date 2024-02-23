import 'package:flutter/material.dart';

class MinecraftMessageParser {
  static String colorCodePrefix = '§';

  static const Map<String, Color> colorCodes = {
    '0': Color(0xff000000),
    '1': Color(0xff0000aa),
    '2': Color(0xff00aa00),
    '3': Color(0xff00aaaa),
    '4': Color(0xffaa0000),
    '5': Color(0xffaa00aa),
    '6': Color(0xffffaa00),
    '7': Color(0xffaaaaaa),
    '8': Color(0xff555555),
    '9': Color(0xff5555ff),
    'a': Color(0xff55ff55),
    'b': Color(0xff55ffff),
    'c': Color(0xffff5555),
    'd': Color(0xffff55ff),
    'e': Color(0xffffff55),
    'f': Color(0xffffffff),
  };

  // §r resets the color

  static List<(String, Color)> parse(String message) {
    final result = <(String, Color)>[];
    final parts = message.split(colorCodePrefix);

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      if (part.isEmpty) {
        continue;
      }
      if (i == 0) {
        result.add((part, colorCodes['f']!));
      } else {
        final colorCode = part.substring(0, 1);
        final rest = part.substring(1);
        final color = colorCodes[colorCode] ?? colorCodes['f']!;
        result.add((rest, color));
      }
    }
    return result;
  }
}
