import 'package:flutter/cupertino.dart';

import '../../../constants/app_colors.dart';

Widget dropdownMenuItemPost(dynamic lineIcons,String nameMenuItem){
  return Row(
    children: [
      Icon(
        lineIcons,
        color: txt_grey_color_v1,
      ),
      Expanded(
        child: Container(
          alignment: Alignment.center,
          child: Text(
            nameMenuItem,
            style: TextStyle(
              color: txt_grey_color_v1,
            ),
          ),
        ),
      )
    ],
  );
}