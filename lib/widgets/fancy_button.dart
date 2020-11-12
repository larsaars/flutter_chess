import 'package:flutter/material.dart';

class FancyButton extends StatefulWidget {

  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color splashColor, fillColor, iconColor;

  FancyButton({Key key, @required this.onPressed, this.text = "", this.icon, this.splashColor = Colors.orange, this.fillColor = Colors.brown, this.iconColor = Colors.amber}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FancyButtonState(
    onPressed: onPressed,
    text: text,
    icon: icon,
    splashColor: splashColor,
    fillColor: fillColor,
    iconColor: iconColor,
  );
}

class _FancyButtonState extends State<FancyButton> with SingleTickerProviderStateMixin {

  AnimationController animationController;

  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color splashColor, fillColor, iconColor;

  _FancyButtonState({@required this.onPressed, this.text = "", this.icon, this.splashColor = Colors.orange, this.fillColor = Colors.brown, this.iconColor = Colors.amber});

  void onTapped() {
    //animate, then call callback
    animationController.forward();
    onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
            onPressed: () => onTapped(),
            splashColor: splashColor,
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
                      color: iconColor,
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
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 412),
      vsync: this,
    );

    animationController.addStatusListener((status) {
      if(status == AnimationStatus.completed)
        animationController.reset();
    });
    super.initState();
  }
}