import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FancyButton extends StatelessWidget {
  FancyButton({@required this.onPressed, this.text, this.icon});

  final GestureTapCallback onPressed;
  final String text;
  final IconData icon;

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
                  Icon(
                    icon,
                    color: Colors.amber,
                  ),
                  const SizedBox(
                    width: 8.0,
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
}