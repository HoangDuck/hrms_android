import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class TKButton extends StatelessWidget {
  final String text;
  final Function onPress;
  final EdgeInsets margin;
  final Color borderColor;
  final Color textColor;
  final Color backgroundColor;
  final double width;
  final double height;
  final double borderRatio;
  final bool enable;

  TKButton(this.text,
      {this.onPress,
      this.margin,
      this.textColor = white_color,
      this.borderColor = Colors.transparent,
      this.width = 50,
      this.height = 50,
      this.borderRatio = 10.0,
      this.backgroundColor = button_color,
      this.enable = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: enable == false ? () => {} : onPress,
      onTap: enable == false ? () => {} : onPress,
      child: Container(
        margin: margin,
        width: width,
        height: height == 50 ? Utils.resizeHeightUtil(context, 90) : height,
        child: LayoutBuilder(
          builder: (context, constraint) {
            return Center(
              child: TKText(
                text,
                tkFont: TKFont.SFProDisplaySemiBold,
                style: TextStyle(
                    color: textColor,
                    fontSize: Utils.resizeWidthUtil(context, 32)),
              ),
            );
          },
        ),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRatio != 10.0
                ? borderRatio
                : Utils.resizeWidthUtil(context, 10)),
            color: enable == false ? Colors.grey : backgroundColor,
            border: Border.all(width: 1, color: borderColor)),
      ),
    );
  }
}
