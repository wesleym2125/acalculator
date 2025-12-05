import 'dart:math';

import 'package:flutter/material.dart';

import 'Expr.dart';

Map<String, String> operations = {
  "+": "+",
  "-": "-",
  "\u00D7": "*",
  "\u00F7": "/",
  "%": "/100",
  "^": "^"
};

Map<String, List<String>> binOperations = <String, List<String>>{

};

Map<String, String> funcBc = {
  "sin": "s",
  "cos": "c",
  "tan": "t",
  "log2": "l2",
  "log10": "l10",
  "ln": "l"
};

Map<String, String> valueExprToBc = {
  "e": "e(1)",
  "\u03C0": "4*a(1)" // arctan(1) = pi/4
};

String? uniFuncToBc(Expr target) {
  if (funcBc.containsKey(target.text)) {
    return funcBc[target.text!];
  }
  return null;
}

String? uniOpToBc(Expr target) {
  if (target is OpExpr && operations.containsKey(target.text!)) {
    return operations[target.text!];
  }
  return "";
}

String? triOpToBc(Expr target, Expr next1, Expr next2) {
  if (binOperations.containsKey(next1.text!)) {
    List<String> texts = binOperations[next1.text!] ?? ["", "", ""];
    return texts[0] + exprToBcEq(target) + texts[1] + exprToBcEq(next2) + texts[2];
  }
  return null;
}

String? triExprToBc(Expr target, Expr? next1, Expr? next2) {
  if (next1 == null || next2 == null) return null;
  if (next1 is OpExpr) return triOpToBc(target, next1, next2);
  return null;
}

String? binExprToBc(Expr target, Expr? next1) {
  if (next1 == null) return null;
  return null;
}

String? uniExprToBc(Expr target) {
  if (target is NumExpr) return target.text!;
  if (target is ValueExpr) return valueExprToBc[target.text!];
  if (target is OpExpr) return uniOpToBc(target);
  if (target is FuncLevelExpr) return uniFuncToBc(target);
  return null;
}

String exprToBcEq(Expr expr) {
  List<String> output = [];
  if (expr.hasChildren) {
    int n = expr.children!.length;
    for (int i=0;i<n;i++) {
      String? text = triExprToBc(
          expr.children![i],
          (i + 1 < n) ? expr.children![i+1] : null,
          (i + 2 < n) ? expr.children![i+2] : null
      );
      if (text != null) {
        output.add(text);
        i += 2;
        continue;
      }
      text = binExprToBc(
          expr.children![i],
          (i + 1 < n) ? expr.children![i+1] : null,
      );
      if (text != null) {
        output.add(text);
        i += 1;
        continue;
      }
      text = uniExprToBc(expr.children![i]);
      output.add(text ?? "");
    }
  } else {
    output.add(uniExprToBc(expr) ?? "");
  }
  return output.join("");
}

String stringToBcEquation(String text) {
  text = text
      .replaceAll("e", "e(1)")
      .replaceAll("\u03C0", "4*a(1)")
      .replaceAll("%", "/100")
      .replaceAll("//", "%")
      .replaceAll("\u00F7", "/")
      .replaceAll("\u00D7", "*")
      .replaceAll("\u221A(", "sqrt(")
      .replaceAll("E", "*10^")
      .replaceAll("ln(", "l(")
      .replaceAll("log10(", "1/l(10)*")
      .replaceAll("log2(", "1/l(2)*")
      .replaceAll("sin(", "s(")
      .replaceAll("cos(", "c(")
      .replaceAll("tan(", "t(")
      .replaceAll("tan(", "t(");
  int level = 0;
  for (int i=0;i<text.length;i++) {
    if (text[i] == "(") level++;
    if (text[i] == ")") level--;
  }
  text = text + (")" * level);
  return text;
}

String removeTrailingZeroes(String text) {
  text.trim();
  while (text.endsWith("0")) {
    text = text.substring(0, text.length-1);
  }
  return text;
}

String roundBcOutput(String text, int digits) {
  print("=$text");
  text = text.replaceAll("\n", "");
  List<String> decimalSplit = text.split(".");
  if (decimalSplit.length < 2) return decimalSplit[0];
  decimalSplit[1] = removeTrailingZeroes(decimalSplit[1]);
  if (decimalSplit[1].isEmpty) return decimalSplit[0];
  if (decimalSplit[1].length > digits) decimalSplit[1] = decimalSplit[1].substring(0, digits);
  return decimalSplit.join(".");
}

String addBracket(String originalText) {
  if (originalText.isEmpty) return "(";
  String lastChar = originalText.substring(originalText.length - 1);
  if (operations.containsKey(lastChar)) {
    return "$originalText(";
  }
  int level = 0;
  for (int i=0;i<originalText.length;i++) {
    if (originalText[i] == "(") {
      level++;
    } else if (originalText[i] == ")") {
      level--;
    }
  }
  if (lastChar == "(") {
    return "$originalText(";
  } else if (lastChar == ")") {
    return (level > 0) ? "$originalText)" : "$originalText\u00D7(";
  }
  return (level > 0) ? "$originalText)" : "$originalText(";
}

String writeTextField(String originalText, String append) {
  if (append == "()") return addBracket(originalText);
  if (validAppendOp(originalText, append)) {
    return originalText + append;
  }
  return originalText;
}

bool validAppendOp(String originalText, String append) {
  bool canAppend = true;
  String lastChar = (originalText.isEmpty) ? "" : originalText.substring(originalText.length - 1);
  if (originalText.isEmpty) {
    if (append != "-" && operations.containsKey(append)) {
      canAppend = false;
    }
    if (append == "E") {
      canAppend = false;
    }
    if (append[0] == "^") {
      canAppend = false;
    }
  } else if (operations.containsKey(lastChar)) {
    if (operations.containsKey(append)) {
      canAppend = false;
    }
  }
  return canAppend;
}

enum FormulaType {
  EMPTY, EQUATION
}

FormulaType getEquationType(String? text) {
  if (text == null || text.isEmpty) return FormulaType.EMPTY;
  return FormulaType.EMPTY;
}
