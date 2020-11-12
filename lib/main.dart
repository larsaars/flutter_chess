import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_controller.dart';
import 'package:chess_bot/generated/i18n.dart';
import 'package:chess_bot/widgets/fancy_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'chess_board/src/chess_board.dart';

S strings;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //the app name
    const appName = 'chess';

    //set fullscreen
    SystemChrome.setEnabledSystemUIOverlays([]);
    //and portrait only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);

    //create the material app
    return MaterialApp(
      //manage resources first
      localizationsDelegates: [S.delegate],
      supportedLocales: S.delegate.supportedLocales,
      //define title etc.
      title: appName,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.brown,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  ChessController _chessController;
  int _timesResumed = 0;

  @override
  Widget build(BuildContext context) {
    //set strings object
    strings = S.of(context);
    //build the chess controller
    _chessController = ChessController(context);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: ChessBoard(
            boardType: BoardType.darkBrown,
            size: MediaQuery.of(context).size.width,
            onGame: (game) {
              _chessController.game = game;
              _chessController.onReloadLastGame();
            },
            onChessBoardController: (chessBoardController) => _chessController.controller = chessBoardController,
            onCheckMate: (color) => _chessController.onCheckMate(color),
            onDraw: () => _chessController.onDraw(),
            onMove: (move) => _chessController.onMove(move),
            onCheck: (color) => _chessController.onCheckMate(color),
          ),
      ),
      bottomNavigationBar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FancyButton(
                onPressed: () => print('pressed'),
                icon: Icons.add,
              ),
              SizedBox(
                width: 8.0,
              ),
              FancyButton(
                onPressed: () => print('pressed'),
                icon: Icons.add,
              ),
              SizedBox(
                width: 8.0,
              ),
              FancyButton(
                onPressed: () => print('pressed'),
                icon: Icons.add,
              ),
              SizedBox(
                width: 8.0,
              ),
              FancyButton(
                onPressed: () => print('pressed'),
                icon: Icons.add,
              ),
              SizedBox(
                width: 8.0,
              ),
              FancyButton(
                onPressed: () => print('pressed'),
                icon: Icons.add,
              ),
              SizedBox(
                width: 8.0,
              ),
              FancyButton(
                onPressed: () => _chessController.resetBoard(),
                icon: Icons.autorenew,
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //on pause save game,
    //on resume load game only if is not the first time to re enter activity
    switch(state) {
      case AppLifecycleState.paused:
        _chessController.onSaveGame();
        break;
      case AppLifecycleState.resumed:
        if(_timesResumed != 0)
          _chessController.onReloadLastGame();
        _timesResumed++;
        break;
      default:
        break;
    }
    super.didChangeAppLifecycleState(state);
  }
}
