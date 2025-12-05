import 'dart:convert';
import 'dart:math';

import 'package:acalculator/CalculatorButton.dart';
import 'package:acalculator/Expr.dart';
import 'package:acalculator/SettingsPage.dart';
import 'package:acalculator/StringProcess.dart';
import 'package:acalculator/Currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'EqTextEditController.dart';
import 'ScriptTextSpan.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      routes: <String, WidgetBuilder>{},
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('app.channel.shared.data');
  late Process process;
  EqTextEditController eqTextFieldController = EqTextEditController();
  EqTextEditScrollController textFieldScrollController = EqTextEditScrollController();
  String result = "";
  bool showAnswer = false;
  String dataShared = "";
  bool numberMode = true;
  CurrencyManager? currencyManager;
  Currency? defaultCurrency;
  bool isIndexing = false;
  bool shiftMode = false;
  bool cleared = false;
  RootExpr rootExpr = RootExpr();

  Future<Process> startBc() async {
    process = await Process.start("bc", ["-l", "-q"]);
    stdout.write(process.stdout);
    process.stdout.transform(utf8.decoder).forEach(display);
    return process;
  }
  List<ButtonItem> numberModeItems = [];
  List<ButtonItem> scientificMode1Items = [];
  List<ButtonItem> scientificMode2Items = [];

  void loadButtonItems() {
    numberModeItems = [
      ClearButtonItem(onPressed: allClear),
      FunctionButtonItem(text: [ScriptTextSpan(text: "+/-")], onPressed: () { coverExpr(NegExpr());}),
      FunctionButtonItem(text: [ScriptTextSpan(text: "%")], onPressed: () { appendExpr(PercentExpr());}),
      OperationButtonItem(text: [ScriptTextSpan(text: "\u00F7")], onPressed: () {appendExpr(DivOpExpr());}),
      NumberButtonItem(number: "7", onPressed: () { appendExpr(DigitExpr(text: "7")); }),
      NumberButtonItem(number: "8", onPressed: () { appendExpr(DigitExpr(text: "8")); }),
      NumberButtonItem(number: "9", onPressed: () { appendExpr(DigitExpr(text: "9")); }),
      OperationButtonItem(text: [ScriptTextSpan(text: "\u00D7")], onPressed: () {appendExpr(MulOpExpr());}),
      NumberButtonItem(number: "4", onPressed: () { appendExpr(DigitExpr(text: "4")); }),
      NumberButtonItem(number: "5", onPressed: () { appendExpr(DigitExpr(text: "5")); }),
      NumberButtonItem(number: "6", onPressed: () { appendExpr(DigitExpr(text: "6")); }),
      OperationButtonItem(text: [ScriptTextSpan(text: "-")], onPressed: () { appendExpr(SubOpExpr()); }),
      NumberButtonItem(number: "1", onPressed: () { appendExpr(DigitExpr(text: "1")); }),
      NumberButtonItem(number: "2", onPressed: () { appendExpr(DigitExpr(text: "2")); }),
      NumberButtonItem(number: "3", onPressed: () { appendExpr(DigitExpr(text: "3")); }),
      OperationButtonItem(text: [ScriptTextSpan(text: "+")], onPressed: () { appendExpr(AddOpExpr()); }),
      NumberButtonItem(number: "EE", onPressed: () { appendExpr(SciNotaExpr()); }),
      NumberButtonItem(number: "0", onPressed: () { appendExpr(DigitExpr(text: "0")); }),
      NumberButtonItem(number: ".", onPressed: () { appendExpr(DeciExpr()); }),
      EqualButtonItem(onPressed: calculate)
    ];
    scientificMode1Items = [
      FunctionButtonItem(
          text: [ScriptTextSpan(text: "(")],
          onPressed: () {
            appendExpr(OpenBracketExpr());
            backToNumberMode();
          }),
      FunctionButtonItem(
          text: [ScriptTextSpan(text: ")")],
          onPressed: () {
            appendExpr(CloseBracketExpr());
            backToNumberMode();
          }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "sin")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "sin"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "cos")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "cos"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "tan")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "tan"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "sinh")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "sinh"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "cosh")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "cosh"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "tanh")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "tanh"));
        backToNumberMode();
      }),
      FunctionButtonItem(
          text: [ScriptTextSpan(text: "x"), ScriptTextSpan(text: "2", level: 1)],
          onPressed: () {
            appendExpr(OpExpr(text: "^"));
            appendExpr(NumExpr(text: "2"));
            backToNumberMode();
          }),
      FunctionButtonItem(
          text: [ScriptTextSpan(text: "x"), ScriptTextSpan(text: "y", level: 1)],
          onPressed: () {
            appendExpr(OpExpr(text: "^"));
            backToNumberMode();
          }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "e"), ScriptTextSpan(text: "x", level: 1)], onPressed: () {
        appendExpr(OpExpr(text: "\u00D7"));
        appendExpr(ValueExpr(text: "e"));
        appendExpr(OpExpr(text: "^"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "\u221A")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "\u221A"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "1/x")], onPressed: () {
        placeBeforeSubExpr("(1\u00F7");
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "ln")], onPressed: () {
        appendExpr(FuncLevelExpr(text: "ln"));
        backToNumberMode();
      }),
      NumberButtonItem(number: "Rand#", onPressed: () {
        appendExpr(NumExpr(text: Random().nextDouble().toString()));
        backToNumberMode();
      }),
      NumberButtonItem(number: "e", onPressed: () {
        appendExpr(ValueExpr(text: "e"));
        backToNumberMode();
      }),
      NumberButtonItem(number: "\u03C0", onPressed: () {
        appendExpr(ValueExpr(text: "\u03C0"));
        backToNumberMode();
      }),
    ];
    scientificMode2Items = [
      FunctionButtonItem(text: [ScriptTextSpan(text: "Rad")], onPressed: () { appendText("!"); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "x!")], onPressed: () { appendText("!"); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "sin"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("asin("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "cos"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("acos("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "tan"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("atan("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "sinh"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("asinh("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "cosh"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("acosh("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "tanh"), ScriptTextSpan(text: "-1", level: 1)], onPressed: () { appendText("atanh("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "x"), ScriptTextSpan(text: "3", level: 1)], onPressed: () { appendText("^3"); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "\u221B")], onPressed: () { appendText("\u221B"); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "mod")], onPressed: () { appendText(" mod "); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "2"), ScriptTextSpan(text: "x", level: 1)], onPressed: () { placeBeforeSubExpr("2^("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "log"), ScriptTextSpan(text: "2", level: -1)], onPressed: () { appendText("log_2("); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "nCr")], onPressed: () { appendText("c"); }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "10"), ScriptTextSpan(text: "x", level: 1)], onPressed: () {
        appendExpr(OpExpr(text: "\u00D7"));
        appendExpr(NumExpr(text: "10"));
        appendExpr(OpExpr(text: "^"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "log"), ScriptTextSpan(text: "10", level: -1)], onPressed: () {
        appendExpr(FuncLevelExpr(text: "log10"));
        backToNumberMode();
      }),
      FunctionButtonItem(text: [ScriptTextSpan(text: "x"), ScriptTextSpan(text: "y", level: 1), ScriptTextSpan(text: " mod")], onPressed: () { appendText(" mod "); } ),
    ];
  }

  @override
  void initState() {
    super.initState();
    CurrencyManager.getSetting().then((value) {setState(() {
      defaultCurrency = value;
    });});
    eqTextFieldController.addListener(() {
      setState(() {
        showAnswer = false;
      });
    });
    getSharedText();
    startBc();
    loadButtonItems();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      textFieldScrollController.jumpToEnd();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    eqTextFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<ButtonItem> _buttonItems = [];
    if (numberMode) {
      _buttonItems = numberModeItems;
    } else if (shiftMode) {
      _buttonItems = scientificMode2Items;
    } else {
      _buttonItems = scientificMode1Items;
    }
    isIndexing = eqTextFieldController.text.endsWith("^") || eqTextFieldController.text.endsWith("^(");
    return Scaffold(
        resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.currency_yen),
              title: Text("Default Currency"),
              trailing: Text(defaultCurrency?.currencyCode ?? "HKD"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SelectCurrencyPage())).then((value) => {
                  if (value != null) {
                    setState(() {
                      print("Set the default currency as ${value[0].currencyCode}");
                      CurrencyManager.setCurrency(defaultCurrency);
                      defaultCurrency = value[0];
                    })
                  }
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Setting"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettingPage()));
              }
            )
          ],
        )
      ),
      appBar: AppBar(
        actions: [IconButton(
            iconSize: 24,
            padding: const EdgeInsets.all(16.0),
            onPressed: () {}, icon: Icon(Icons.history)),
          IconButton(
            iconSize: 24,
            padding: const EdgeInsets.all(16.0),
            onPressed: () {}, icon: Icon(Icons.rotate_left))],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Spacer(flex: 2),
                      NotificationListener(
                        onNotification: (notification) {
                          textFieldScrollController.jumpToEnd();
                          return true;
                        },
                        child: SizeChangedLayoutNotifier(
                          child: TextField(
                            scrollController: textFieldScrollController,
                            enableIMEPersonalizedLearning: false,
                            controller: eqTextFieldController,
                            decoration: InputDecoration.collapsed(hintText: ""),
                            autocorrect: false,
                            smartQuotesType: SmartQuotesType.disabled,
                            smartDashesType: SmartDashesType.disabled,
                            style: (showAnswer) ? Theme.of(context).textTheme.headlineMedium?.apply(color: Color(0xFF777777)) : Theme.of(context).textTheme.displayMedium,
                            textAlign: TextAlign.end,
                            textCapitalization: TextCapitalization.none,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.go,
                            autofocus: false,
                            onSubmitted: (text) {
                              calculate();
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r','))
                            ],
                            onChanged: (text) {
                              setState(() {
                                showAnswer = false;
                              });
                            },
                          ),
                        ),
                      ),
                      (showAnswer) ? SelectableText(
                        result,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.displayLarge,
                        maxLines: 1
                      ) : SizedBox(height: 0),
                      Spacer(flex: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(iconSize: 24,
                              padding: const EdgeInsets.all(16.0),onPressed: () {}, icon: Icon(Icons.straighten)),
                          IconButton(
                              iconSize: 24,
                              padding: const EdgeInsets.all(16.0),
                              onPressed: () {}, icon: Icon(Icons.currency_exchange)),
                          InkWell(
                            onLongPress: () {

                            },
                            child: IconButton(
                                iconSize: 24,
                                padding: const EdgeInsets.all(16.0),
                                onPressed: () {
                                  setState(() {
                                    numberMode = !numberMode;
                                  });
                                }, icon: Icon(Icons.calculate_outlined)),
                          ),
                          (isIndexing) ? IconButton(onPressed: () {
                            setState(() {
                              int lastIndex = eqTextFieldController.text.lastIndexOf("^");
                              eqTextFieldController.text = eqTextFieldController.text.substring(0, lastIndex);
                            });
                          }, style: IconButton.styleFrom(backgroundColor: Colors.red),
                              icon: Icon(Icons.superscript), color: Colors.white) : SizedBox(width: 0),
                          Spacer(),
                          IconButton(
                              iconSize: 24,
                              padding: const EdgeInsets.all(16.0),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                backspace();
                          }, icon: Icon(Icons.backspace_outlined)),

                        ],
                      )
                    ],
                  ),
                )
            ),
            (numberMode) ? GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0),
                shrinkWrap: true,
                padding: const EdgeInsets.all(12.0),
                children: _buttonItems.map((item) => item.widget).toList()) :
            GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.705),
                shrinkWrap: true,
                padding: const EdgeInsets.all(12.0),
                children: <Widget>[
                  CalculatorButton(text: [ScriptTextSpan(text: "shift")], onPressed: () {setState(() {
                    shiftMode = !shiftMode;
                  });}, type: (shiftMode) ? CalculatorButtonType.SHIFTON : CalculatorButtonType.SHIFTOFF)
                ] + _buttonItems.map<Widget>((item) => item.widget).toList()),
          ]),
      )
    );
  }
  
  void backToNumberMode() {
    setState(() {
      numberMode = true;
      shiftMode = false;
    });
  }

  Future<void> calculate() async {
    var text = eqTextFieldController.text;
    process.stdin.writeln("quit");
    await startBc();
    String bcEq = rootExpr.getBcEq();
    print(bcEq);
    process.stdin.writeln(bcEq);
    if (text.isEmpty) process.stdin.writeln("\" \"");
  }

  void display(String text) {
    setState(() {
      showAnswer = true;
      result = roundBcOutput(text, 9);
    });
  }

  Future<void> getSharedText() async {
    try {
      var sharedData = await platform.invokeMethod("getSharedText");
      if (sharedData != null) {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => SettingPage()));
      }
    } catch (e) {}
  }

  void backspace() {
    setState(() {
      rootExpr.backspace();
      eqTextFieldController.text = rootExpr.getText();
    });
  }

  void allClear() {
    setState(() {
      rootExpr.clear();
      updateTextField("");
      calculate();
      cleared = true;
    });
  }

  void updateTextField(String text) {
    eqTextFieldController.currentEq = rootExpr.getTextSpan();
    eqTextFieldController.text = text;
  }

  void appendText(String text) {
    print(text);
    eqTextFieldController.text = writeTextField(eqTextFieldController.text, text);
  }

  void appendExpr(Expr expr) {
    NumExpr? previous = (showAnswer && result.isNotEmpty && !cleared) ? NumExpr(text: result) : null;
    cleared = false;
    if (previous != null) {
      rootExpr.clear();
    }
    if (expr is ValueExpr) {
      if (previous != null) {
        rootExpr.addExpr(previous);
        rootExpr.addExpr(OpExpr(text: "\u00D7"));
      }
      rootExpr.addExpr(expr);
    } else if (expr is FuncLevelExpr && previous != null) {
      rootExpr.clear();
      rootExpr.addExpr(previous);
      rootExpr.addCoverFunc(expr);
    } else if (expr is OpExpr) {
      if (previous != null) rootExpr.addExpr(previous);
      rootExpr.addExpr(expr);
    } else {
      rootExpr.addExpr(expr);
    }
    updateTextField(rootExpr.getText());
    textFieldScrollController.willJump();
  }

  void coverExpr(FuncLevelExpr expr) {
    rootExpr.addCoverFunc(expr);
    updateTextField(rootExpr.getText());
    textFieldScrollController.willJump();
  }

  void placeBeforeSubExpr(String text, {String? appendAfter}) {
    if (appendAfter != null) {
      appendText(appendAfter);
    }
  }
}
