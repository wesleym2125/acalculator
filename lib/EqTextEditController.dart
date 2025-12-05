import 'package:flutter/material.dart';

class EqTextEditController extends TextEditingController {
  int indexingLevel = 0;
  TextSpan? currentEq;

  void setCurrenEq(TextSpan textSpan) {
    this.currentEq = textSpan;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) => TextSpan(
      text: (currentEq != null) ? null : text,
      children: (currentEq != null) ? [currentEq!] : null,
      style: style
  );
}

class EqTextEditScrollController extends ScrollController {
  bool _willJump = false;

  void willJump() => _willJump = true;

  void jumpToEnd() {
    if (hasClients && _willJump) {
      jumpTo(position.maxScrollExtent);
      _willJump = false;
    }
  }
}