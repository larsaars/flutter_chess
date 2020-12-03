import 'package:flutter/material.dart';

import '../main.dart';

class ModalProgressHUD extends StatelessWidget {
  final bool inAsyncCall;
  final double opacity;
  final Color color;
  final Offset offset;
  final bool dismissible;
  final Widget child;

  ModalProgressHUD({
    Key key,
    @required this.inAsyncCall,
    this.opacity = 0.3,
    this.color = Colors.grey,
    this.offset,
    this.dismissible = false,
    @required this.child,
  })  : assert(child != null),
        assert(inAsyncCall != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];
    widgetList.add(child);
    if (inAsyncCall) {
      Widget layOutProgressIndicator;
      if (offset == null)
        layOutProgressIndicator = Center(
            child: Text(
          strings.loading,
          style: Theme.of(context).textTheme.subtitle2,
        ));
      else {
        layOutProgressIndicator = Positioned(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                strings.loading,
                style: Theme.of(context).textTheme.subtitle2,
              )),
          left: offset.dx,
          top: offset.dy,
        );
      }
      final modal = [
        new Opacity(
          child: new ModalBarrier(dismissible: dismissible, color: color),
          opacity: opacity,
        ),
        layOutProgressIndicator
      ];
      widgetList += modal;
    }
    return new Stack(
      children: widgetList,
    );
  }
}
