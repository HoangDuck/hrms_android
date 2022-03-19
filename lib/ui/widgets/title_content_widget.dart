import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

titleContentWidget(BuildContext context, String title, String content,
    {EdgeInsets margin,
    EdgeInsets padding,
    Color color = Colors.white,
    Color textColor = txt_grey_color_v2,
    bool isBold = true,
    double width}) {
  return Container(
    decoration:
        BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
    margin: margin,
    padding: padding,
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          alignment: Alignment.centerLeft,
          child: TKText(
            Utils.getString(context, title),
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(
                color: txt_grey_color_v1,
                fontSize: Utils.resizeWidthUtil(context, 26)),
          ),
        ),
        SizedBox(height: Utils.resizeHeightUtil(context, 5)),
        Container(
          alignment: Alignment.centerLeft,
          child: TKText(
            content == null ? "" : content,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 34),
                color: textColor),
            tkFont: isBold
                ? TKFont.SFProDisplaySemiBold
                : TKFont.SFProDisplayRegular,
          ),
        )
      ],
    ),
  );
}
