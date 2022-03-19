import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class ComingSoonView extends StatelessWidget {

  final dynamic data;

  ComingSoonView(this.data);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(context, () {
        Utils.closeKeyboard(context);
        Navigator.pop(context, 0);
      }, () {
        Utils.closeKeyboard(context);
      }, data['title'], null),
      body: Center(
        child: TKText(
          'Tính năng đang được phát triển',
          tkFont: TKFont.SFProDisplayMedium,
          style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 32)),
        ),
      ),
    );
  }
}
