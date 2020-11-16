import 'package:chess_bot/chess_board/flutter_chess_board.dart';
import 'package:chess_bot/chess_board/src/chess_sub.dart' as chess_sub;
import 'package:chess_bot/chess_controller.dart';
import 'package:chess_bot/generated/i18n.dart';
import 'package:chess_bot/utils.dart';
import 'package:chess_bot/widgets/fancy_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'chess_board/src/chess_board.dart';

S strings;
ChessController _chessController;

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
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    //create the material app
    return MaterialApp(
      //manage resources first
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomepageState createState() => _MyHomepageState();
}

class _MyHomepageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    //set strings object
    strings ??= S.of(context);
    //init the context singleton object
    ContextSingleton(context);
    //build the chess controller,
    //if needed set context newly
    if (_chessController == null)
      _chessController = ChessController(context);
    else
      _chessController.context = context;
    //future builder: load old screen and show here on start the loading screen,
    //when the future is finished,
    //with setState show the real scaffold
    //return the view
    return (_chessController.game == null)
        ? FutureBuilder(
            future: _chessController.loadOldGame(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  var error = snapshot.error;
                  print('$error');
                  return Center(child: Text(strings.error));
                }

                return MyHomePageAfterLoading();
              } else {
                return Center(
                    child: CircularProgressIndicator(
                  backgroundColor: Colors.brown,
                ));
              }
            },
          )
        : MyHomePageAfterLoading();
  }
}

class MyHomePageAfterLoading extends StatefulWidget {
  MyHomePageAfterLoading({Key key}) : super(key: key);

  @override
  _MyHomePageAfterLoadingState createState() => _MyHomePageAfterLoadingState();
}

class _MyHomePageAfterLoadingState extends State<MyHomePageAfterLoading>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _chessController.saveOldGame();
        break;
      default:
        break;
    }
  }

  void update() {
    setState(() {});
  }

  Future<bool> _onWillPop() async {
    _chessController.saveOldGame();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    //set the update method
    _chessController.update = update;
    //the default scaffold
    return Container(
      color: Colors.white30,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    strings.turn_of_x((_chessController?.game?.game?.turn == chess_sub.Color.BLACK)
                        ? strings.black
                        : strings.white),
                    style: Theme.of(context).textTheme.subtitle1.copyWith(
                          inherit: true,
                          color: (_chessController?.game?.in_check ?? false)
                              ? Colors.red
                              : Colors.black,
                        )),
              ),
              Center(
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: ChessBoard(
                  boardType: _chessController.boardType,
                  size: MediaQuery.of(context).size.width,
                  onCheckMate: (color) => _chessController.onCheckMate(color),
                  onDraw: () => _chessController.onDraw(),
                  onMove: (move) => _chessController.onMove(move),
                  onCheck: (color) => _chessController.onCheck(color),
                  chessBoardController: _chessController.controller,
                  chess: _chessController.game,
                  whiteSideTowardsUser: _chessController.whiteSideTowardsUser,
                ),
              ),
            ],
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
                    onPressed: _chessController.switchColors,
                    icon: Icons.switch_left,
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  FancyButton(
                    onPressed: _chessController.undo,
                    icon: Icons.undo,
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  FancyButton(
                    onPressed: _chessController.resetBoard,
                    icon: Icons.autorenew,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
