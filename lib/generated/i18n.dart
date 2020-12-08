// DO NOT EDIT. This is code generated via package:gen_lang/generate.dart

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
    return Intl.message("${turn}'s turn", name: 'turn_of_x', args: [turn]);
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
    return Intl.message("change board style", name: 'choose_style');
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
    return Intl.message("depth", name: 'difficulty');
  }

  String get difficulties {
    return Intl.message("auto,2,3,4,5", name: 'difficulties');
  }

  String get fen_options {
    return Intl.message("to clipboard,from clipboard", name: 'fen_options');
  }

  String get bot_vs_bot {
    return Intl.message("bot vs. bot", name: 'bot_vs_bot');
  }

  String get copy_fen {
    return Intl.message("copy fen", name: 'copy_fen');
  }

  String get privacy_url {
    return Intl.message("https://l-chess.flycricket.io/privacy.html", name: 'privacy_url');
  }

  String get terms_url {
    return Intl.message("https://l-chess.flycricket.io/terms.html", name: 'terms_url');
  }

  String get privacy_title {
    return Intl.message("privacy policy", name: 'privacy_title');
  }

  String get loading_moves_web {
    return Intl.message("loading moves...", name: 'loading_moves_web');
  }

  String get online_game_options {
    return Intl.message("online game", name: 'online_game_options');
  }

  String get join_code {
    return Intl.message("join game", name: 'join_code');
  }

  String get create_code {
    return Intl.message("create game", name: 'create_code');
  }

  String get local {
    return Intl.message("[local game]", name: 'local');
  }

  String get warning {
    return Intl.message("warning!", name: 'warning');
  }

  String get game_reset_join_code_warning {
    return Intl.message("By creating a new game code, you will reset your local board and leave a running online game. A friend can join your game via the generated code. The creator of the game is always white.", name: 'game_reset_join_code_warning');
  }

  String get proceed {
    return Intl.message("proceed", name: 'proceed');
  }

  String get leave_online_game {
    return Intl.message("leave game", name: 'leave_online_game');
  }

  String get enter_game_id {
    return Intl.message("enter a game id", name: 'enter_game_id');
  }

  String get game_id_not_found {
    return Intl.message("game id not found", name: 'game_id_not_found');
  }

  String get game_id_ex {
    return Intl.message("ex.: KDFGHQ", name: 'game_id_ex');
  }

  String get join {
    return Intl.message("join", name: 'join');
  }

  String get deleting_as_host_info {
    return Intl.message("Since you are hosting the game, leaving it means deleting it.", name: 'deleting_as_host_info');
  }

  String get switch_colors {
    return Intl.message("turn board", name: 'switch_colors');
  }

  String get availability_other_devices {
    return Intl.message("platforms", name: 'availability_other_devices');
  }

  String get android {
    return Intl.message("android", name: 'android');
  }

  String get web {
    return Intl.message("web", name: 'web');
  }

  String get website_url {
    return Intl.message("https://chess-45a81.web.app/#/", name: 'website_url');
  }

  String get playstore_url {
    return Intl.message("https://play.google.com/store/apps/details?id=com.lurzapps.chess", name: 'playstore_url');
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
