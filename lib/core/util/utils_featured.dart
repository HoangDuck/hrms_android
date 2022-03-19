import 'package:flutter/material.dart';

import '../../ui/constants/app_colors.dart';

class UtilsFeatured{
  static Color colorTextReactionButton(int iconChoose){
    switch (iconChoose) {
      case 1:
        return Color(0xff558AFE);
      case 2:
        return Color(0xffED5167);
      case 3:
      case 4:
      case 5:
        return Color(0xffF2D45C);
      case 6:
        return Color(0xffF6876B);
      default:
        return txt_grey_color_v1;
    }
  }
}