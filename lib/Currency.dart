import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

class Currency {
  final String countryName;
  final String currencyName;
  final String currencyCode;
  final int currencyNumber;
  final int minorUnit;

  const Currency({required this.countryName, required this.currencyName, required this.currencyCode, required this.currencyNumber, required this.minorUnit});
}

class CurrencyManager {
  static Future<int> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    int? settingCurrency = await prefs.getInt("currency");
    if (settingCurrency == null) {
      // Hong Kong Dollar
      settingCurrency = 344;
      savePref(344);
      return 344;
    }
    return settingCurrency;
  }

  static Future<List<Currency>> getCurrencyList() async {
    String text = await rootBundle.loadString('assets/data/currency-list.xml');
    final document = XmlDocument.parse(text);
    print(document.findAllElements("CcyNtry").length);
    return document.findAllElements("CcyNtry").map((e) => Currency(
        countryName: e.getElement("CtryNm")?.innerText ?? "",
      currencyName: e.getElement("CcyNm")?.innerText ?? "",
      currencyCode: e.getElement("Ccy")?.innerText ?? "",
      currencyNumber: int.parse(e.getElement("CcyNbr")?.innerText ?? "0"),
        minorUnit: 2
    )).toList();
  }

  static void setCurrency(Currency? newDefault) {
    if (newDefault != null) {
      savePref(newDefault!.currencyNumber);
    }
  }

  static Future<void> savePref(int? currencyNumber) async {
    if (currencyNumber != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt("default_currency", currencyNumber);
    }
  }

  static Future<Currency> getSetting() async {
    List<Currency> currencies = await getCurrencyList();
    int settingCurrency = await loadPrefs();
    for (Currency currency in currencies) {
      if (currency.currencyNumber == settingCurrency) {
        return currency;
      }
    }
    return Currency(countryName: "HONG KONG", currencyName: "Hong Kong Dollar", currencyCode: "HKD", currencyNumber: 344, minorUnit: 2);
  }
}

class SelectCurrencyPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SelectCurrencyPageState();
}

class _SelectCurrencyPageState extends State<SelectCurrencyPage> {
  List<Currency> currency_list = [];

  Future<void> getCurrencyList() async {
    currency_list = await CurrencyManager.getCurrencyList();
  }

  @override
  void initState() {
    super.initState();
    getCurrencyList().then((value) {setState(() {
      print(currency_list);
    });});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Currency"),
      ),
      body: ListView(
        children: currency_list.map<Widget>((e) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ListTile(
            onTap: () {
              Navigator.of(context).pop([e]);
            },
              title: Text(e.currencyName),
              subtitle: Text(e.currencyCode)),
        )).toList() + <Widget>[
              Container(
                color: Color(0x22888888),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text("The currency code and list complies with ISO 4217:2015 [https://www.iso.org/iso-4217-currency-codes.html]"),
                      ],
                    ),
                  ),
                ),
              )
        ],
      )
    );
  }

}