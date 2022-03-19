import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/app_value.dart';
import 'package:gsot_timekeeping/ui/views/notification_view.dart';
import 'package:gsot_timekeeping/ui/widgets/loading.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

import '../../my_app.dart';

showLoadingDialog(BuildContext context) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Future.delayed(Duration(seconds: timeout_duration), () {
        try {
          Navigator.of(context).pop(true);
          showMessageDialog(context, description: 'Server hiện không phản hồi!', onPress: () => Navigator.of(navigatorKey.currentContext).pop(true));
        } catch (e) {
          print(e.toString());
        }
      });
      return WillPopScope(onWillPop: () async => false, child: LoadingWidget());
    });

showPushNotification(BuildContext context, dynamic data) => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return NotificationWidget(notificationData: data);
    });

showMessageDialog(BuildContext context,
        {String title = 'Thông báo',
        String description = '',
        Function onPress,
        Function onPressX,
        Widget childContent,
        bool isShowX = true,
        String buttonText = txt_ok}) =>
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                ),
                elevation: 0.0,
                backgroundColor: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                          EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TKText(title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Utils.resizeWidthUtil(context, 32),
                                  color: txt_grey_color_v1),
                              tkFont: TKFont.SFProDisplaySemiBold),
                          description.isEmpty
                              ? childContent
                              : Container(
                                  margin: EdgeInsets.only(
                                      top: Utils.resizeHeightUtil(context, 30)),
                                  child: TKText(
                                    description,
                                    tkFont: TKFont.SFProDisplayRegular,
                                    style: TextStyle(
                                        fontSize:
                                            Utils.resizeWidthUtil(context, 28)),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                          TKButton(Utils.getString(context, buttonText),
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: Utils.resizeHeightUtil(context, 70),
                              margin: EdgeInsets.only(
                                  top: Utils.resizeHeightUtil(context, 50)),
                              onPress: onPress != null
                                  ? onPress
                                  : () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    isShowX
                        ? Positioned(
                            right: 10,
                            top: 10,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: onPressX != null
                                  ? onPressX
                                  : () => Navigator.pop(context),
                              child: Icon(
                                Icons.clear,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ))
                        : Container()
                  ],
                ),
              ),
              onWillPop: () async => false);
        });

showMessageDialogIOS(BuildContext context,
        {String title = 'Thông báo',
        String description = '',
        Function onPress,
        Function onPressX,
        Widget childContent,
        bool enableButton = true,
        String buttonText = txt_ok}) =>
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return Theme(
            data: ThemeData(
              cupertinoOverrideTheme:
                  const CupertinoThemeData(brightness: Brightness.light),
            ),
            child: WillPopScope(
                child: CupertinoAlertDialog(
                  title: enableButton ? TKText(title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 34),
                          fontFamily: 'SFProDisplay-Bold'),
                      tkFont: TKFont.SFProDisplaySemiBold) : CupertinoActivityIndicator(),
                  content: description.isEmpty
                      ? Container()
                      : Container(
                          margin: EdgeInsets.only(top: 10),
                          child: TKText(
                            description,
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 32)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                  actions: <Widget>[
                    if (enableButton)
                      CupertinoDialogAction(
                        child: Text(Utils.getString(context, buttonText)),
                        onPressed: onPress != null
                            ? onPress
                            : () => Navigator.pop(context),
                      ),
                  ],
                ),
                onWillPop: () async => false),
          );
        });

showMessageChoose(
    BuildContext context, {
      String title = 'Thông báo',
      String description = '',
      Function onPress,
      Function onPressX,
      Widget childContent,
      bool isShowX = true,
      String buttonText = txt_ok,
      Function onPressBack,
    }) =>
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WillPopScope(
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                ),
                elevation: 0.0,
                backgroundColor: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Padding(
                      padding:
                      EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TKText(title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Utils.resizeWidthUtil(context, 32),
                                  color: txt_grey_color_v1),
                              tkFont: TKFont.SFProDisplaySemiBold),
                          description.isEmpty
                              ? childContent
                              : Container(
                            margin: EdgeInsets.only(
                                top: Utils.resizeHeightUtil(context, 30)),
                            child: TKText(
                              description,
                              tkFont: TKFont.SFProDisplayRegular,
                              style: TextStyle(
                                  fontSize:
                                  Utils.resizeWidthUtil(context, 28)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TKButton(
                                    Utils.getString(context, buttonText),
                                    width:
                                    MediaQuery.of(context).size.width * 0.3,
                                    height: Utils.resizeHeightUtil(context, 70),
                                    margin: EdgeInsets.only(
                                        top: Utils.resizeHeightUtil(
                                            context, 50)),
                                    onPress: onPress != null
                                        ? onPress
                                        : () => Navigator.pop(context)),
                              ),
                              SizedBox(
                                width: Utils.resizeHeightUtil(context, 20),
                              ),
                              Expanded(
                                child: TKButton("Không",
                                    width:
                                    MediaQuery.of(context).size.width * 0.3,
                                    height: Utils.resizeHeightUtil(context, 70),
                                    margin: EdgeInsets.only(
                                        top: Utils.resizeHeightUtil(
                                            context, 50)),
                                    onPress: onPressBack != null
                                        ? onPressBack
                                        : () => Navigator.pop(context)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    isShowX
                        ? Positioned(
                        right: 10,
                        top: 10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: onPressX != null
                              ? onPressX
                              : () => Navigator.pop(context),
                          child: Icon(
                            Icons.clear,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ))
                        : Container()
                  ],
                ),
              ),
              onWillPop: () async => false);
        });
