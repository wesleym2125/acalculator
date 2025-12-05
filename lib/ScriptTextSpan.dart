import 'package:flutter/material.dart';

class ScriptTextSpan {
  final String text;
  final int? level;
  static List<double> sups_dy = [0, -8, -12];
  static List<double> subs_dy = [0, 4];
  const ScriptTextSpan({required this.text, this.level});

  InlineSpan span(TextStyle? style, int level) {
    if (level > 2) level = 2;
    if (level < -1) level = -1;
    if (level > 0) {
      return WidgetSpan(
          child: Transform.translate(offset: Offset(1, sups_dy[level!]), child: Text(text, style: style?.apply(heightFactor: 5/8 * level!)))
      );
    } else if (level < 0) {
      return WidgetSpan(
          child: Transform.translate(offset: Offset(1, subs_dy[-level!]), child: Text(text, style: style?.apply(heightFactor: 5/8 * (-level!))))
      );
    }
    return TextSpan(text: text);
  }
}
