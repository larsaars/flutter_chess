import 'package:chess_bot/util/utils.dart';
import 'package:chess_bot/widgets/fancy_button.dart';
import 'package:flutter/material.dart';

bool collapseFancyOptions = false;

class FancyOptions extends StatefulWidget {
  final List<Widget> children;
  final String rootText;
  final IconData rootIcon;
  final bool up;
  final double widgetHeight, widgetWidth;

  FancyOptions({
    Key key,
    this.children = const [],
    this.rootText,
    this.rootIcon,
    this.up = true,
    this.widgetHeight = 40,
    this.widgetWidth = 150,
  }) : super(key: key);

  @override
  _FancyOptionsState createState() => _FancyOptionsState();
}

class _FancyOptionsState extends State<FancyOptions>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  List<Animation> animations = [];
  bool visible = false;

  @override
  void initState() {
    //create controller once
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    //and the animations for the children
    double yOffset = additionalHeight;
    for (int i = 0; i < widget.children.length; i++) {
      double randomWeight = random.nextDouble() * 100,
          randomDistribution = random.nextDouble() * yOffset;
      animations.add(TweenSequence([
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.0, end: randomDistribution),
            weight: randomWeight),
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: randomDistribution, end: yOffset),
            weight: 100 - randomWeight),
      ]).animate(_controller));

      yOffset += additionalHeight;
    }

    //call super to init
    super.initState();
    //then add the listener
    _controller.addListener(() {
      setState(() {});
    });
    //if is dismissed (reversed) set visible false again
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) visible = false;
    });
  }

  double get additionalHeight {
    return (widget.up ? -1 : 1) * (widget.widgetHeight + 4);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (collapseFancyOptions && _controller.isCompleted) {
      collapseFancyOptions = false;
      _controller.reverse();
    }

    List<Widget> childrenTransforms = [];
    //create the transforms for the children
    for (int i = 0; i < widget.children.length; i++) {
      childrenTransforms.add(Visibility(
        visible: visible,
        child: Transform.translate(
          offset: Offset(0, animations[i].value),
          child: widget.children[i],
        ),
      ));
    }

    List<Widget> ignorePointer = [];
    if (_controller.isCompleted) {
      double maxHeight = additionalHeight.abs() * (widget.children.length + 1);
      ignorePointer = [
        IgnorePointer(
          child: Container(
            width: widget.widgetWidth,
            height: maxHeight,
          ),
        )
      ];
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: ignorePointer +
          childrenTransforms +
          <Widget>[
            FancyButton(
              onPressed: () {
                if (_controller.isCompleted)
                  _controller.reverse();
                else {
                  _controller.forward();
                  visible = true;
                }
              },
              animation: FancyButtonAnimation.pulse,
              icon: widget.rootIcon,
              text: widget.rootText,
              width: -1,
            ),
          ],
    );
  }
}
