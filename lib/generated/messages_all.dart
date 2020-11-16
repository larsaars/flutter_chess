// DO NOT EDIT. This is code generated via package:gen_lang/generate.dart

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
// ignore: implementation_imports
import 'package:intl/src/intl_helpers.dart';

final _$de = $de();

class $de extends MessageLookupByLibrary {
  get localeName => 'de';
  
  final messages = {
		"app_name" : MessageLookupByLibrary.simpleMessage("Schach"),
		"cancel" : MessageLookupByLibrary.simpleMessage("schließen"),
		"choose_promotion" : MessageLookupByLibrary.simpleMessage("Umwandlung wählen"),
		"checkmate" : MessageLookupByLibrary.simpleMessage("Schachmatt"),
		"draw" : MessageLookupByLibrary.simpleMessage("Unentschieden"),
		"error" : MessageLookupByLibrary.simpleMessage("Fehler"),
		"draw_desc" : MessageLookupByLibrary.simpleMessage("Das Spiel wurde mit einem Unentschieden beendet!"),
		"replay" : MessageLookupByLibrary.simpleMessage("neu spielen"),
		"ok" : MessageLookupByLibrary.simpleMessage("ok"),
		"white" : MessageLookupByLibrary.simpleMessage("weiß"),
		"black" : MessageLookupByLibrary.simpleMessage("schwarz"),
		"check_mate_desc" : (loser, winner) => "${loser} ist Schachmatt. ${winner} hat gewonnen.",
		"turn_of_x" : (turn) => "${turn} ist dran",
		"replay_desc" : MessageLookupByLibrary.simpleMessage("Bist du dir sicher, dass du das Spiel neustarten willst?"),

  };
}

final _$en = $en();

class $en extends MessageLookupByLibrary {
  get localeName => 'en';
  
  final messages = {
		"app_name" : MessageLookupByLibrary.simpleMessage("Chess"),
		"cancel" : MessageLookupByLibrary.simpleMessage("cancel"),
		"choose_promotion" : MessageLookupByLibrary.simpleMessage("choose promotion"),
		"checkmate" : MessageLookupByLibrary.simpleMessage("checkmate"),
		"draw" : MessageLookupByLibrary.simpleMessage("draw"),
		"error" : MessageLookupByLibrary.simpleMessage("error"),
		"draw_desc" : MessageLookupByLibrary.simpleMessage("The game finished with a draw!"),
		"replay" : MessageLookupByLibrary.simpleMessage("replay"),
		"ok" : MessageLookupByLibrary.simpleMessage("ok"),
		"white" : MessageLookupByLibrary.simpleMessage("white"),
		"black" : MessageLookupByLibrary.simpleMessage("black"),
		"check_mate_desc" : (loser, winner) => "${loser} is in checkmate. ${winner} won.",
		"turn_of_x" : (turn) => "turn of ${turn}",
		"replay_desc" : MessageLookupByLibrary.simpleMessage("Are you sure to restart the game and reset the board?"),

  };
}



typedef Future<dynamic> LibraryLoader();
Map<String, LibraryLoader> _deferredLibraries = {
	"de": () => Future.value(null),
	"en": () => Future.value(null),

};

MessageLookupByLibrary _findExact(localeName) {
  switch (localeName) {
    case "de":
        return _$de;
    case "en":
        return _$en;

    default:
      return null;
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName) async {
  var availableLocale = Intl.verifiedLocale(
      localeName,
          (locale) => _deferredLibraries[locale] != null,
      onFailure: (_) => null);
  if (availableLocale == null) {
    return Future.value(false);
  }
  var lib = _deferredLibraries[availableLocale];
  await (lib == null ? Future.value(false) : lib());

  initializeInternalMessageLookup(() => CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, _findGeneratedMessagesFor);

  return Future.value(true);
}

bool _messagesExistFor(String locale) {
  try {
    return _findExact(locale) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary _findGeneratedMessagesFor(locale) {
  var actualLocale = Intl.verifiedLocale(locale, _messagesExistFor,
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(actualLocale);
}

// ignore_for_file: unnecessary_brace_in_string_interps
