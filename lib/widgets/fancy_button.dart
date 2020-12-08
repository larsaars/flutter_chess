import 'package:flutter/material.dart';

enum FancyButtonAnimation { rotate_right, rotate_left, pulse }

class FancyButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final Color splashColor, fillColor, iconColor;
  final bool visible;
  final double width;

  final FancyButtonAnimation animation;

  FancyButton({
    Key key,
    this.width = -1,
    this.onPressed,
    this.visible = true,
    this.text = "",
    this.icon,
    this.splashColor = Colors.white60,
    this.fillColor = Colors.brown,
    this.iconColor = Colors.white60,
    this.animation = FancyButtonAnimation.rotate_right,
  }) : super(key: key);

  @override
  _FancyButtonState createState() => _FancyButtonState();
}

class _FancyButtonState extends State<FancyButton>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  void onTapped() {
    //animate, then call callback
    animationController.forward();
    widget?.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    //predefine icon since anim could change
    var icon = Icon(
      widget.icon,
      color: widget.iconColor,
    );
    //set the transition according to enum with switch case
    var _transition;
    switch (widget.animation) {
      case FancyButtonAnimation.rotate_right:
        _transition = RotationTransition(
          turns: Tween(
            begin: 0.0,
            end: 1.0,
          ).animate(animationController),
          child: icon,
        );
        break;
      case FancyButtonAnimation.rotate_left:
        _transition = RotationTransition(
          turns: Tween(
            begin: 1.0,
            end: 0.0,
          ).animate(animationController),
          child: icon,
        );
        break;
      case FancyButtonAnimation.pulse:
        _transition = FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(animationController),
          child: icon,
        );
        break;
      default:
        break;
    }

    //the button
    Widget button = Visibility(
      visible: widget.visible,
      child: Container(
        height: 40,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: RawMaterialButton(
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
                  widget.icon == null ? Container() : _transition,
                  SizedBox(
                    //set the sized box only 8 wide when a text is set
                    width: widget.text.length == 0 || widget.icon == null
                        ? 0.0
                        : 8.0,
                  ),
                  Text(
                    widget.text ?? "",
                    style: TextStyle(
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.width != -1)
      return Container(
        width: widget.width,
        child: button,
      );
    else
      return button;
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) animationController.reset();
    });
    super.initState();
  }
}
