import 'package:flutter/material.dart';

class FancyButton extends StatefulWidget {

  final GestureTapCallback onPressed;
  final String text;
  final IconData icon;

  FancyButton({@required this.onPressed, this.text = "", this.icon});

  @override
  State<StatefulWidget> createState() => _FancyButtonState(
    onPressed: onPressed,
    text: text,
    icon: icon
  );
}

class _FancyButtonState extends State<FancyButton> with SingleTickerProviderStateMixin {

  AnimationController animationController;

  final GestureTapCallback onPressed;
  final String text;
  final IconData icon;

  _FancyButtonState({@required this.onPressed, this.text = "", this.icon});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
            onPressed: onPressed,
            splashColor: Colors.orange,
            fillColor: Colors.brown,
            shape: StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 20.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RotationTransition(
                    turns: Tween(
                      begin: 0.0,
                      end: 1.0,
                    ).animate(animationController),
                    child: Icon(
                      icon,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(
                    //set the sized box only 8 wide when a text is set
                    width: text.length == 0 ? 0.0 : 8.0,
                  ),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  BuildContext get context => context;

  @override
  void deactivate() {
    animationController.dispose();
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant StatefulWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 412),
      vsync: this,
    );
    super.initState();
  }
}