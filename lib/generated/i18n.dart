// DO NOT EDIT. This is code generated via package:gen_lang/generate.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'messages_all.dart';

class S {
 
  static const GeneratedLocalizationsDelegate delegate = GeneratedLocalizationsDelegate();

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }
  
  static Future<S> load(Locale locale) {
    final String name = locale.countryCode == null ? locale.languageCode : locale.toString();

    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((bool _) {
      Intl.defaultLocale = localeName;
      return new S();
    });
  }
  
  String get app_name {
    return Intl.message("Chess", name: 'app_name');
  }

  String get cancel {
    return Intl.message("cancel", name: 'cancel');
  }

  String get choose_promotion {
    return Intl.message("choose promotion", name: 'choose_promotion');
  }

  String get checkmate {
    return Intl.message("checkmate", name: 'checkmate');
  }

  String get draw {
    return Intl.message("draw", name: 'draw');
  }

  String get error {
    return Intl.message("error", name: 'error');
  }

  String get draw_desc {
    return Intl.message("The game finished with a draw!", name: 'draw_desc');
  }

  String get replay {
    return Intl.message("replay", name: 'replay');
  }

  String get ok {
    return Intl.message("ok", name: 'ok');
  }

  String get white {
    return Intl.message("white", name: 'white');
  }

  String get black {
    return Intl.message("black", name: 'black');
  }

  String check_mate_desc(loser, winner) {
    return Intl.message("${loser} is in checkmate. ${winner} won.", name: 'check_mate_desc', args: [loser, winner]);
  }

  String turn_of_x(turn) {
    return Intl.message("it's ${turn}'s turn", name: 'turn_of_x', args: [turn]);
  }

  String get replay_desc {
    return Intl.message("Are you sure to restart the game and reset the board?", name: 'replay_desc');
  }

  String get undo_impossible {
    return Intl.message("can't perform undo", name: 'undo_impossible');
  }

  String get undo {
    return Intl.message("undo", name: 'undo');
  }

  String get choose_style {
    return Intl.message("choose board style", name: 'choose_style');
  }

  String get bot_on {
    return Intl.message("bot on", name: 'bot_on');
  }

  String get bot_off {
    return Intl.message("bot off", name: 'bot_off');
  }

  String moves_done(progress) {
    return Intl.message("${progress} boards processed", name: 'moves_done', args: [progress]);
  }

  String get difficulty {
    return Intl.message("difficulty", name: 'difficulty');
  }

  String get difficulties {
    return Intl.message("easy,medium,normal,hard", name: 'difficulties');
  }

  String get fen_options {
    return Intl.message("to clipboard,from clipboard", name: 'fen_options');
  }

  String get bot_vs_bot {
    return Intl.message("bot vs. bot", name: 'bot_vs_bot');
  }


}

class GeneratedLocalizationsDelegate extends LocalizationsDelegate<S> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
			Locale("en", ""),
			Locale("de", ""),

    ];
  }

  LocaleListResolutionCallback listResolution({Locale fallback}) {
    return (List<Locale> locales, Iterable<Locale> supported) {
      if (locales == null || locales.isEmpty) {
        return fallback ?? supported.first;
      } else {
        return _resolve(locales.first, fallback, supported);
      }
    };
  }

  LocaleResolutionCallback resolution({Locale fallback}) {
    return (Locale locale, Iterable<Locale> supported) {
      return _resolve(locale, fallback, supported);
    };
  }

  Locale _resolve(Locale locale, Locale fallback, Iterable<Locale> supported) {
    if (locale == null || !isSupported(locale)) {
      return fallback ?? supported.first;
    }

    final Locale languageLocale = Locale(locale.languageCode, "");
    if (supported.contains(locale)) {
      return locale;
    } else if (supported.contains(languageLocale)) {
      return languageLocale;
    } else {
      final Locale fallbackLocale = fallback ?? supported.first;
      return fallbackLocale;
    }
  }

  @override
  Future<S> load(Locale locale) {
    return S.load(locale);
  }

  @override
  bool isSupported(Locale locale) =>
    locale != null && supportedLocales.contains(locale);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;
}

// ignore_for_file: unnecessary_brace_in_string_interps
