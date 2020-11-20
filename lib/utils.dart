import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'main.dart';

const version = '1.0';
const app_name = 'chess';

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

void showTextDialog(
  String title,
  String text, {
  String onDoneText,
  List<Widget> children = const [],
  OnDialogCancelCallback onDone,
  OnDialogReturnSetStateCallback setStateCallback,
}) async {
  if (_showing) return;

  _showing = true;

  //show dialog
  await showGeneralDialog(
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
            if(setStateCallback != null)
              setStateCallback(context, setState);
            //create the alert dialog object
            return AlertDialog(
              title: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.subtitle1,
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
                            text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                        ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ],
              ),
              actions: <Widget>[
                FlatButton(
                    child: Text(onDone == null ? strings.ok : strings.cancel),
                    onPressed: () {
                      _showing = false;
                      Navigator.of(context).pop(onDone == null ? 'ok' : null);
                    }),
                onDone != null
                    ? FlatButton(
                        child: Text(onDoneText),
                        onPressed: () {
                          _showing = false;
                          Navigator.of(context).pop('ok');
                        })
                    : Container()
              ],
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
