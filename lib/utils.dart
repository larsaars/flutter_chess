import 'dart:math';

import 'package:connectivity/connectivity.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'main.dart';

const version = '1.0';
const app_name = 'chess!';

final Random random = Random();

Future<String> get rootDir async {
  final directory = await getApplicationDocumentsDirectory();
  // For your reference print the AppDoc directory
  return directory.path;
}

class ContextSingleton {
  static ContextSingleton _instance;
  final BuildContext _context;

  ContextSingleton(this._context) {
    _instance = this;
  }

  static get context {
    return _instance._context;
  }
}

bool _showing = false;

typedef void OnDialogCancelCallback(value);
typedef void OnDialogReturnSetStateCallback(BuildContext context, setState);

void showAnimatedDialog({
  String title,
  String text,
  String onDoneText,
  String forceCancelText,
  List<Widget> children = const [],
  OnDialogCancelCallback onDone,
  OnDialogReturnSetStateCallback setStateCallback,
  IconData icon,
  var update,
  bool showAnyActionButton = true,
}) async {
  if (_showing) return;

  _showing = true;

  //show dialog
  showGeneralDialog(
    context: ContextSingleton.context,
    barrierDismissible: true,
    barrierLabel: "showTextDialog",
    pageBuilder: (context, animation1, animation2) {
      return Container();
    },
    transitionBuilder: (context, a1, a2, widget) {
      final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
      return Transform(
        transform: Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
        child: Opacity(
          opacity: a1.value,
          child: StatefulBuilder(builder: (context, setState) {
            //call the listener that returns the set state
            if (setStateCallback != null) setStateCallback(context, setState);
            //create the alert dialog object
            return AlertDialog(
              title: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon == null ? Container() : Icon(icon),
                      SizedBox(
                        width: 8.0,
                      ),
                      Text(
                        title ?? "",
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                    ],
                  )),
              content: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  (text == null)
                      ? SizedBox()
                      : Center(
                          child: Text(
                            text ?? "",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: children,
                  ),
                ],
              ),
              actions: showAnyActionButton
                  ? [
                      FlatButton(
                          shape: roundButtonShape,
                          child: Text(forceCancelText != null
                              ? forceCancelText
                              : (onDone == null ? strings.ok : strings.cancel)),
                          onPressed: () {
                            _showing = false;
                            Navigator.of(context)
                                .pop(onDone == null ? 'ok' : null);
                          }),
                      onDone != null
                          ? FlatButton(
                              shape: roundButtonShape,
                              child: Text(onDoneText ?? ""),
                              onPressed: () {
                                _showing = false;
                                Navigator.of(context).pop('ok');
                              })
                          : Container()
                    ]
                  : [],
            );
          }),
        ),
      );
    },
    transitionDuration: Duration(milliseconds: 300),
  ).then((value) {
    //set showing dialog false
    _showing = false;
    //execute the on done
    if (onDone != null && value != null) onDone(value);
  });
}

Future<bool> hasInternet() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.mobile) {
    // I am connected to a mobile network, make sure there is actually a net connection.
    if (await DataConnectionChecker().hasConnection) {
      // Mobile data detected & internet connection confirmed.
      return true;
    } else {
      // Mobile data detected but no internet connection found.
      return false;
    }
  } else if (connectivityResult == ConnectivityResult.wifi) {
    // I am connected to a WIFI network, make sure there is actually a net connection.
    if (await DataConnectionChecker().hasConnection) {
      // Wifi detected & internet connection confirmed.
      return true;
    } else {
      // Wifi detected but no internet connection found.
      return false;
    }
  } else {
    // Neither mobile data or WIFI detected, not internet connection found.
    return false;
  }
}

RoundedRectangleBorder roundButtonShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(45));

void addLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['flutter_chess_board'],
        await rootBundle.loadString('res/licenses/flutter_chess_board'));
    yield LicenseEntryWithLineBreaks(
        ['chess'], await rootBundle.loadString('res/licenses/chess'));
    yield LicenseEntryWithLineBreaks(['modal_progress_hud'],
        await rootBundle.loadString('res/licenses/modal_progress_hud'));
  });
}

String createGameCode() {
  final availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
      .runes
      .map((int rune) => String.fromCharCode(rune))
      .toList();
  String out = '';
  for (int i = 0; i < 6; i++)
    out += availableChars[random.nextInt(availableChars.length)];
  return out;
}

String _currentGameCode;
String get currentGameCode {
  return _currentGameCode == null ? strings.local : _currentGameCode;
}