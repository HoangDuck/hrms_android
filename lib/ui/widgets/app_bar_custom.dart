import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

const double app_bar_icon_size = 40;
const double app_bar_font_size = 34;

Widget appBarCustom(BuildContext context, Function leftPress,
        Function rightPress, String title, IconData icon,
        {bool hideBackground = false, Widget titleCustom, Color leadingIconColor = white_color}) =>
    AppBar(
      flexibleSpace: hideBackground
          ? Container()
          : Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                    gradient_end_color,
                    gradient_start_color
                  ])),
            ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: InkWell(
          onTap: leftPress,
          child: Padding(
              padding: EdgeInsets.all(17),
              child: Image.asset(
                ic_back,
                color: leadingIconColor,
              ))),
      title: titleCustom != null ? titleCustom : TKText(title,
          tkFont: TKFont.SFProDisplayMedium,
          style: appBarTextStyle(
              Utils.resizeWidthUtil(context, app_bar_font_size))),
      actions: <Widget>[
        InkWell(
          child: Icon(icon ?? icon,
              color: icon_app_bar_color,
              size: Utils.resizeWidthUtil(context, app_bar_icon_size)),
          onTap: rightPress,
        ),
        Container(
          width: Utils.resizeWidthUtil(context, 20),
        )
      ],
    );
