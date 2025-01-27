import 'package:flutter/material.dart';
import 'package:transitrack_web/style/constants.dart';

// Handy Multi-purpose Big Icon Button

class IconButtonBig extends StatelessWidget {
  Color color;
  Widget icon;
  Function function;
  bool inverted;
  IconButtonBig(
      {super.key,
      required this.color,
      required this.icon,
      required this.function,
      this.inverted = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        child: IconButton(
          style: ButtonStyle(
            side: WidgetStateProperty.all<BorderSide>(BorderSide(
                color: color,
                width: inverted ? 2.0 : 0.0,
                style: BorderStyle.solid)),
            overlayColor: WidgetStateProperty.all<Color>(!inverted
                ? Constants.bgColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.3)),
            backgroundColor: WidgetStateProperty.all<Color>(
                inverted ? Colors.transparent : color),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          onPressed: () => function(),
          icon: icon,
        ),
      ),
    );
  }
}
