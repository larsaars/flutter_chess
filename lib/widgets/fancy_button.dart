import 'package:flutter/material.dart';

enum FancyButtonAnimation {
  rotate_right, rotate_left, pulse, none
}

class FancyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color splashColor, fillColor, iconColor;

  final FancyButtonAnimation animation;

  FancyButton(
      {Key key,
      @required this.onPressed,
      this.text = "",
      this.icon,
      this.splashColor = Colors.white60,
      this.fillColor = Colors.brown,
      this.iconColor = Colors.white60,
      this.animation = FancyButtonAnimation.rotate_right})
      : super(key: key);

  @override
  _FancyButtonState createState() => _FancyButtonState();
}

class _FancyButtonState extends State<FancyButton>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  void onTapped() {
    //animate, then call callback
    animationController.forward();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    //predefine icon since anim could change
    var _icon = Icon(
      widget.icon,
      color: widget.iconColor,
    );
    //set the transition according to enum with switch case
    var _transition;
    switch(widget.animation) {
      case FancyButtonAnimation.rotate_right:
        _transition = RotationTransition(
          turns: Tween(
            begin: 0.0,
            end: 1.0,
          ).animate(animationController),
          child: _icon,
        );
        break;
      case FancyButtonAnimation.rotate_left:
        _transition = RotationTransition(
          turns: Tween(
            begin: 1.0,
            end: 0.0,
          ).animate(animationController),
          child: _icon,
        );
        break;
      case FancyButtonAnimation.pulse:
        _transition = FadeTransition(
          opacity: Tween(
            begin: 1.0,
            end: 0.0
          ).animate(animationController),
          child: _icon,
        );
        break;
      default:
        break;
    }

    //the button
    return RawMaterialButton(
      onPressed: onTapped,
      splashColor: widget.splashColor,
      fillColor: widget.fillColor,
      shape: StadiumBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 20.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon == null ? Container(): _transition,
            SizedBox(
              //set the sized box only 8 wide when a text is set
              width: widget.text.length == 0 ? 0.0 : 8.0,
            ),
            Text(
              widget.text,
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
      duration: const Duration(milliseconds: 622),
      vsync: this,
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) animationController.reset();
    });
    super.initState();
  }
}
