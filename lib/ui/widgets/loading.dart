import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        //color: Colors.black.withOpacity(0.7),
        child: Theme(
            data: ThemeData(
                cupertinoOverrideTheme:
                    CupertinoThemeData(brightness: Brightness.dark)),
            child: WillPopScope(
                child: CupertinoAlertDialog(
                  title: CupertinoActivityIndicator(),
                  content: Container(
                    margin: EdgeInsets.only(top: 10),
                    child: TKText(
                      Utils.getString(context, txt_loading),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 32)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                onWillPop: () async => false)));
  }
}
