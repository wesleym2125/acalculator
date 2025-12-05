import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ScriptTextSpan.dart';

enum CalculatorType {
  SCIENTIFIC, FINANCIAL
}

enum CalculatorButtonType {
  CLEAR, FUNCTIONAL, NUMERIC, EQUAL, SHIFTOFF, SHIFTON
}

extension CalculatorButtonTheme on CalculatorButtonType {
  Color get textColor {
    switch (this) {
      case CalculatorButtonType.CLEAR:
        return Colors.red;
      case CalculatorButtonType.EQUAL || CalculatorButtonType.SHIFTON:
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CalculatorButtonType.CLEAR || CalculatorButtonType.FUNCTIONAL || CalculatorButtonType.SHIFTOFF:
        return Color(0xffeeeeee);
      case CalculatorButtonType.NUMERIC:
        return Colors.white;
      case CalculatorButtonType.EQUAL || CalculatorButtonType.SHIFTON:
        return Colors.redAccent;
    }
  }
}

class CalculatorButton extends StatelessWidget {
  final List<ScriptTextSpan> text;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final CalculatorButtonType type;
  final double? fontSize;
  const CalculatorButton({super.key, required this.text, required this.onPressed, this.onLongPress, required this.type, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: () {
      HapticFeedback.lightImpact();
      onPressed!();
    },
        onLongPress: (onLongPress != null) ? () {
      HapticFeedback.lightImpact();
      onLongPress!();
        } : null,
        clipBehavior: ClipOval().clipBehavior,
        style: TextButton.styleFrom(backgroundColor: type.backgroundColor),
        child: RichText(
          text: TextSpan(
            children: text.map((e) => e.span(TextStyle(fontSize: fontSize), e.level ?? 0)).toList(),
            style: TextStyle(color: type.textColor, fontSize: (fontSize != null) ? fontSize : 24),
          ),
    ));
  }
}

abstract class ButtonItem {
  final List<ScriptTextSpan> text;
  final void Function()? onPressed;
  final void Function()? onLongPress;
  final CalculatorButtonType type;
  final double? fontSize;
  const ButtonItem({required this.text, required this.type, this.onPressed, this.onLongPress, this.fontSize});
  Widget get widget {
    return CalculatorButton(text: text, onPressed: onPressed, onLongPress: onLongPress, type: type, fontSize: fontSize);
  }
}

class ClearButtonItem extends ButtonItem {
  const ClearButtonItem({required super.onPressed}) : super(text: const [ScriptTextSpan(text: "AC")], type: CalculatorButtonType.CLEAR);
}

class NumberButtonItem extends ButtonItem {
  final String number;
  NumberButtonItem({required this.number, required super.onPressed}) : super(text: [ScriptTextSpan(text: number)], type: CalculatorButtonType.NUMERIC);
}

class FunctionButtonItem extends ButtonItem {
  const FunctionButtonItem({required super.text, required super.onPressed, super.onLongPress, super.fontSize}) : super(type: CalculatorButtonType.FUNCTIONAL);
}

class OperationButtonItem extends FunctionButtonItem {
  const OperationButtonItem({required super.text, required super.onPressed, super.onLongPress}) : super(fontSize: 28.0);
}

class EqualButtonItem extends ButtonItem {
  const EqualButtonItem({required super.onPressed, super.onLongPress}) : super(text: const [ScriptTextSpan(text: "=")], type: CalculatorButtonType.EQUAL, fontSize: 28.0);
}

class PlaceholderButtonItem extends ButtonItem {
  PlaceholderButtonItem() : super(text: [ScriptTextSpan(text: "")], type: CalculatorButtonType.CLEAR);

  @override
  Widget get widget {
    return Container();
  }

}