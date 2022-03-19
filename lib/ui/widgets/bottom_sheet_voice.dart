import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';

Widget modalBottomSheetVoice(BuildContext context, StateSetter setModalState) {
  return Container(
      padding: EdgeInsets.only(
          left: Utils.resizeWidthUtil(context, 30),
          right: Utils.resizeWidthUtil(context, 30),
          top: Utils.resizeHeightUtil(context, 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
          topRight: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[Image.asset(wave)],
      ));
}
