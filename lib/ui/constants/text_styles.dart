import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'app_colors.dart';

final normalTitleGreyTextStyle = TextStyle(
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
    color: txt_grey_color_v1);

final normalTextStyle = TextStyle(
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
    color: txt_grey_color_v3);

final bigTextStyle = TextStyle(
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 34),
    color: txt_grey_color_v3);

final bigBoldTextStyle = TextStyle(
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 34),
    color: txt_grey_color_v3,
    fontWeight: FontWeight.bold);

final avatarNameTextStyle = TextStyle(
  fontWeight: FontWeight.w500,
  fontSize: 20,
  color: gradient_color_main_end,
);

TextStyle appBarTextStyle(num size) {
  return TextStyle(fontSize: size, color: Colors.white);
}

TextStyle loginInputHintTextStyle(num size) {
  return TextStyle(fontSize: size, color: Colors.black);
}
