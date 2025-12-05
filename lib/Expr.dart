import 'package:flutter/material.dart';

class BcEqString {
  final String text;
  final int length;

  static BcEqString single(String text) => BcEqString(text: text, length: 1);
  static BcEqString dual(String text) => BcEqString(text: text, length: 2);
  static BcEqString triple(String text) => BcEqString(text: text, length: 3);

  const BcEqString({required this.text, required this.length});

  @override
  String toString() => text;
}

class ExprListOpCallback {
  static ExprListOpCallback SUCCESS = ExprListOpCallback(successful: true);
  static ExprListOpCallback APPEND = ExprListOpCallback(append: true);

  final bool successful;
  final bool append;

  ExprListOpCallback operator&(ExprListOpCallback other) => ExprListOpCallback(
      append: this.append && other.append,
      successful: this.successful && other.successful
  );

  const ExprListOpCallback({this.append = false, this.successful = false});
}

class Expr {
  String? text;
  bool closed;
  final List<Expr>? children;

  Expr({this.text, this.children, required this.closed});

  bool isLevelZero() => false;
  bool get hasChildren => (children != null);
  /// the expression can be the first element of level expr
  bool canFirst() => true;
  /// the expression can be the element before [next]
  bool canBefore(Expr next) => true;
  /// the expression can be the element after [last]
  bool canAfter(Expr last) => true;
  bool canAppend(Expr next) => (canBefore(next) && next.canAfter(this));
  List<Expr> prefix(Expr last) => [];
  List<Expr> suffix(Expr next) => [];
  List<Expr> appendNext(Expr next) => [this] + suffix(next) + next.prefix(this) + [next];
  List<Expr> appendAsFirst() => [this];

  /// adds an expression, return [true] if append the expression its parent.
  ExprListOpCallback addExpr(Expr expr) {
    if (children == null || closed) return ExprListOpCallback.APPEND;
    bool canAdd = false;
    if (children!.isEmpty) {
      canAdd = expr.canFirst();
      if (canAdd) children!.addAll(expr.appendAsFirst());
    } else if (children!.last.addExpr(expr).append) {
      canAdd = children!.last.canAppend(expr);
      if (canAdd) {
        Expr last = children!.removeLast();
        children!.addAll(last.appendNext(expr));
      }
    }
    return ExprListOpCallback(successful: canAdd, append: false);
  }

  /// returns [TextSpan] of text of this Expression with nullable [style]
  TextSpan getTextSpan({TextStyle? style}) {
    List<InlineSpan> output = [];
    if (children != null) output.addAll(children!.map<InlineSpan>((child) => child.getTextSpan(style: style)));
    output = <InlineSpan>[TextSpan(text: text ?? "", style: style)] + output;
    return TextSpan(style: style, children: output);
  }

  /// returns [String] of text of this expression and the concatenation of [children]
  String getText() {
    String output = "";
    if (children != null) output = children!.map<String>((child) => child.getText()).join("");
    if (text != null) output = text! + output;
    return output;
  }

  /// returns [String] of the tree of [text] and [runtimeType] of this expression and
  /// shows the [level] with dashes (-)
  ///
  /// |9+(8+7) RootExpr
  ///
  /// |-9 NumExpr
  ///
  /// |-+ OpExpr
  ///
  /// |-(8+7) LevelExpr
  ///
  /// |--( OpenBracketExpr
  ///
  /// |--8 NumExpr
  ///
  /// |--+ OpExpr
  ///
  /// |--7 NumExpr
  ///
  /// |--) CloseBracketExpr
  String getTree({required int level}) {
    String output = "|${"-" * level}${getText()}  [${runtimeType.toString()}; closed: $closed]\n";
    if (children != null) output = output + children!.map<String>((child) => child.getTree(level: level+1)).join("");
    return output;
  }

  /// gets the equation for bc computation
  String getBcEq() => (getChildrenBcEq()?.join("") ?? "") + (getSingleBcEq()?.toString() ?? "");

  /// gets the equation for bc computation of children
  List<BcEqString>? getChildrenBcEq() {
    if (children == null) return null;
    if (children!.isEmpty) return [];
    List<BcEqString> items = [];
    for (int i=0;i<children!.length;i++) {
      BcEqString? bcEqString = getBcEqAtIndex(i);
      if (bcEqString == null) return null;
      items.add(bcEqString);
      i += bcEqString.length - 1;
    }
    return items;
  }

  BcEqString? getBcEqAtIndex(int index) {
    BcEqString? bcEqString;
    if (index + 2 < children!.length) {
      bcEqString = children![index].getTripleBcEq(children![index+1], children![index+2]);
      if (bcEqString != null) return bcEqString;
    }
    if (index + 1 < children!.length) {
      bcEqString = children![index].getDoubleBcEq(children![index+1]);
      if (bcEqString != null) return bcEqString;
    }
    return children![index].getSingleBcEq();
  }

  /// gets the equation for bc computation that spans 1 [Expr]
  BcEqString? getSingleBcEq() => null;

  /// gets the equation for bc computation that spans 2 [Expr]s
  BcEqString? getDoubleBcEq(Expr next1) => getR1BcEq(next1) ?? next1.get1RBcEq(this) ;

  /// gets the equation for bc computation that spans 2 [Expr]s
  /// that the first [Expr] as the operation
  BcEqString? getR1BcEq(Expr next1) => null;

  /// gets the equation for bc computation that spans 2 [Expr]s
  /// that the second [Expr] as the operation
  BcEqString? get1RBcEq(Expr last1) => null;

  /// gets the equation for bc computation that spans 3 [Expr]s
  BcEqString? getTripleBcEq(Expr next1, Expr next2) => getR12BcEq(next1, next2) ?? next1.get1R2BcEq(this, next2);

  /// gets the equation for bc computation that spans 3 [Expr]s
  /// that the first [Expr] as the operation
  BcEqString? getR12BcEq(Expr next1, Expr next2) => null;

  /// gets the equation for bc computation that spans 3 [Expr]s
  /// that the second [Expr] as the operation
  BcEqString? get1R2BcEq(Expr last1, Expr next1) => null;

  /// completes the operation to remove 1 character and
  /// returns the number of elements needed to remove
  int backspace() => 0;
}

/// represents the root expression
class RootExpr extends Expr {
  RootExpr() : super(children: [], closed: false);

  /// clear all expressions
  void clear() { children!.clear(); }

  @override
  ExprListOpCallback addExpr(Expr expr) {
    ExprListOpCallback callback = super.addExpr(expr);
    print(getTree());
    return callback;
  }

  @override
  String getTree({int level = 0}) => super.getTree(level: level);
  @override
  bool isLevelZero() => true;
  @override
  bool canBefore(Expr next) => false;
  @override
  bool canAfter(Expr last) => false;
  @override
  bool canFirst() => false;
  @override
  int backspace() {
    super.backspace();
    return 0;
  }

  void addCoverFunc(FuncLevelExpr expr) {
    expr.putExpr(children! + [CloseBracketExpr()]);
    expr.closed = true;
    clear();
    addExpr(expr);
  }
}

/// represents the operations (+, -, *, /, ^)
class OpExpr extends Expr {
  final String? bcSymbol;

  OpExpr({required super.text, this.bcSymbol}) : super(closed: true);

  // operations cannot be the first expression
  @override
  bool canFirst() => false;

  @override
  bool canBefore(Expr next) => (next is! CloseBracketExpr || next is! OpExpr);

  @override
  bool canAfter(Expr last) => last is! OpenBracketExpr && last is! OpExpr;

  @override
  List<Expr> appendNext(Expr next) => [this, next];

  @override
  BcEqString? getSingleBcEq() => (bcSymbol != null) ? BcEqString.single(bcSymbol!) : null;
}

class AddOpExpr extends OpExpr { AddOpExpr({super.text = "+", super.bcSymbol = "+"}); }
class SubOpExpr extends OpExpr {
  SubOpExpr({super.text = "-", super.bcSymbol = "-"});

  @override
  bool canAfter(Expr last) => (last is OpExpr && last is! SubOpExpr) || super.canAfter(last);
}
class MulOpExpr extends OpExpr { MulOpExpr({super.text = "\u00D7", super.bcSymbol = "*"}); }
class DivOpExpr extends OpExpr { DivOpExpr({super.text = "\u00F7", super.bcSymbol = "/"}); }
class PowOpExpr extends OpExpr { PowOpExpr({super.text = "^", super.bcSymbol = "^"}); }
class ModOpExpr extends OpExpr { ModOpExpr({super.text = " mod ", super.bcSymbol = "%"}); }

/// represents the expression of negative sign at beginning
class NegExpr extends FuncLevelExpr { NegExpr() : super(text: "-"); }

/// represents the expression of values (e.g. e, pi)
class ValueExpr extends Expr {
  final Map<String, String> singleExpr = {
    "e": "e(1)",
    "\u03C0": "4*a(1)"
  };

  ValueExpr({required super.text}) : super(closed: true);

  @override
  BcEqString? getSingleBcEq() =>
      (text != null && singleExpr.containsKey(text!)) ?
      BcEqString.single(singleExpr[text!]!) :
      null;

  @override
  List<Expr> appendNext(Expr next) {
    List<Expr> output = [this];
    if (next is ValueExpr) output.add(OpExpr(text: "\u00D7"));
    output.add(next);
    return output;
  }

  @override
  List<Expr> prefix(Expr last) =>
      (last is ValueExpr || last is CloseBracketExpr) ?
      [OpExpr(text: "\u00D7")] : [];
}

/// represents the expression of numbers, both integers and decimals
class NumExpr extends ValueExpr {
  bool? mustInt;
  NumExpr({required super.text, this.mustInt});
  bool getMustInt() => mustInt ?? false;
  bool isInteger() => text?.contains(".") ?? false;

  @override
  int backspace() {
    if (text!.length > 1) {
      text = text!.substring(0, text!.length - 1);
      return 0;
    }
    return 1;
  }

  @override
  List<Expr> appendNext(Expr next) {
    if (next is DigitExpr || next is DeciExpr) {
      text = text! + next.text!;
      return [this];
    }
    return super.appendNext(next);
  }

  @override
  BcEqString? getSingleBcEq() => BcEqString.single(text!);
}

/// represents a single digit (e.g. 1-9)
class DigitExpr extends NumExpr {
  DigitExpr({required super.text});
}

/// represents a decimal point (.)
class DeciExpr extends NumExpr {
  @override
  bool canAfter(Expr last) => (last is! NumExpr) || last.getMustInt();

  DeciExpr({super.text = "."});
}

/// represents the expression of value that is a function
class SingleOpExpr extends OpExpr {
  final List<String> separators;

  SingleOpExpr({required super.text, required this.separators});

  @override
  BcEqString? get1RBcEq(Expr last1) => BcEqString.dual(separators[0] + last1.getBcEq() + separators[1]);
}

/// represents the expression of percentage sign (%)
///
/// Equivalent to *1/100
/// must be put after [ValueExpr]
class PercentExpr extends SingleOpExpr {
  PercentExpr() : super(text: "%", separators: ["", "/100"]);
}

/// represents the factorial expression
class FactorialExpr extends SingleOpExpr {
  FactorialExpr() : super(text: "!", separators: ["f(", ")"]);
}

/// Represents the expression of scientific notation
///
/// The expression before and after SciNotaExpr must be [IntExpr]
/// * [IntExpr]E[IntExpr] (e.g. 1E50)
class SciNotaExpr extends OpExpr {
  @override
  bool canFirst() => false;
  @override
  bool canAfter(Expr last) => (last is NumExpr) && last.isInteger();
  @override
  bool canBefore(Expr next) => (next is NumExpr) && next.isInteger();

  SciNotaExpr() : super(text: "E");

  @override
  List<Expr> appendNext(Expr next) {
    (next as NumExpr).mustInt = true;
    return [this, next];
  }
}

/// represents the expression with brackets (...)
class LevelExpr extends Expr {
  LevelExpr({super.text, required super.children}) : super(closed: false);

  @override
  TextSpan getTextSpan({TextStyle? style}) {
    List<InlineSpan> textSpans = [super.getTextSpan(style: style)];
    if (!closed) {
      textSpans.add(TextSpan(text: ")", style: style?.apply(color: Colors.grey)));
    }
    return TextSpan(style: style, children: textSpans);
  }
}

/// Represents the expression of a function
class FuncLevelExpr extends LevelExpr {
  FuncLevelExpr({required super.text}) : super(children: [
    OpenBracketExpr()
  ]);

  /// put the list of expression [exprs] to [children]
  void putExpr(List<Expr> exprs) {
    children!.addAll(exprs);
  }
}

/// Represents the expression of bracket.
///
/// * Open Bracket [OpenBracketExpr]
/// * Close Bracket [CloseBracketExpr]
class BracketExpr extends Expr {
  BracketExpr({required super.text}) : super(closed: true);

  @override
  appendAsFirst() => [OpenBracketExpr()];

  @override
  BcEqString? getSingleBcEq() => BcEqString.single(text!);
}

/// Represents the expression of open bracket.
class OpenBracketExpr extends BracketExpr {
  @override
  bool canFirst() => true;

  OpenBracketExpr() : super(text: "(");
}

/// Represents the expression of close bracket.
class CloseBracketExpr extends BracketExpr {
  @override
  bool canFirst() => false;
  @override
  bool canAfter(Expr last) => (last is! OpExpr);

  CloseBracketExpr() : super(text: ")");
}