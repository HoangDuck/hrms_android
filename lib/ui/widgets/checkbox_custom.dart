import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';

import 'box_title.dart';

Widget checkBoxCustom(
        {BuildContext context,
        String title = '',
        bool check = false,
        bool enable = true,
        Function onTap}) =>
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: enable ? onTap : () {},
      child: Container(
        margin:
            EdgeInsets.symmetric(vertical: Utils.resizeHeightUtil(context, 10)),
        child: Row(
          children: <Widget>[
            Expanded(
              child: boxTitle(context, title),
            ),
            check
                ? Icon(Icons.check_box,
                    size: 30, color: enable ? only_color : txt_grey_color_v1)
                : Icon(Icons.check_box_outline_blank,
                    size: 30, color: txt_grey_color_v1)
          ],
        ),
      ),
    );
