// this class is used for localizations
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MyLocalizations {
  static MyLocalizations of(BuildContext context) {
    return Localizations.of<MyLocalizations>(context, MyLocalizations);
  }

  String getText(String key) => language[key];
}

Map<String, dynamic> language;

class MyLocalizationsDelegate extends LocalizationsDelegate<MyLocalizations> {
  const MyLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<MyLocalizations> load(Locale locale) async {
    String string = await rootBundle.loadString("assets/strings/${locale.languageCode}.json");
    language = json.decode(string);
    return SynchronousFuture<MyLocalizations>(MyLocalizations());
  }

  @override
  bool shouldReload(MyLocalizationsDelegate old) => false;
}