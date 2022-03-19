import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/chats_widget/src/chat_theme.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

import '../main_view.dart';

class ChatOptionView extends StatefulWidget {
  final dynamic data;

  const ChatOptionView(this.data);

  @override
  _ChatOptionViewState createState() => _ChatOptionViewState();
}

class _ChatOptionViewState extends State<ChatOptionView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: main_background,
        appBar: appBarCustom(context, () => Navigator.pop(context), null, 'Tùy chọn', null),
        body: Container(
          height: double.infinity,
          color: Colors.grey.shade200,
          child: SingleChildScrollView(
              child: Column(
            children: [
              _buildUserInfo(),
              _userOption(),
            ],
          )),
        ));
  }

  Widget _buildUserInfo() => Container(
        padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
        color: Colors.white,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              maxRadius: 50,
              backgroundColor: (widget.data['isGroup']
                          ? widget.data['RoomData']['AvaGroup']['v']
                          : widget.data['RoomData']["ChatUser"]['avatar']['v']) !=
                      ''
                  ? Colors.transparent
                  : Colors.white,
              child: (widget.data['isGroup']
                          ? widget.data['RoomData']['AvaGroup']['v']
                          : widget.data['RoomData']["ChatUser"]['avatar']['v']) !=
                      ''
                  ? CachedNetworkImage(
                      imageUrl: avatarUrlAPIs +
                          (widget.data['isGroup']
                              ? widget.data['RoomData']['AvaGroup']['v']
                              : widget.data['RoomData']["ChatUser"]['avatar']['v']),
                      imageBuilder: (context, imageProvider) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 1, color: only_color),
                          image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                        ),
                      ),
                      placeholder: (context, url) => CupertinoTheme(
                        data: CupertinoTheme.of(context).copyWith(brightness: Brightness.dark),
                        child: CupertinoActivityIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    )
                  : TKText(
                      (widget.data['isGroup']
                              ? widget.data['RoomData']['RoomName']['v']
                              : widget.data['RoomData']["ChatUser"]['full_name']['v'])
                          .toString()
                          .substring(0, 1),
                      tkFont: TKFont.SFProDisplayBold,
                      style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 40), color: only_color),
                    ),
            ),
            SizedBox(
              height: Utils.resizeWidthUtil(context, 20),
            ),
            TKText(
              widget.data['isGroup']
                  ? widget.data['RoomData']['RoomName']['v']
                  : widget.data['RoomData']["ChatUser"]['full_name']['v'],
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(
              height: Utils.resizeWidthUtil(context, 40),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeaderOptionItem(title: 'Đổi\nhình nền', icon: 'images/chat_images/icon-image-input.png', onPress: () {}),
                _buildHeaderOptionItem(title: 'Tắt\nthông báo', icon: 'images/chat_images/icon-image-input.png', onPress: () {})
              ],
            )
          ],
        ),
      );

  Widget _userOption() => Expanded(
    child: Container(
      color: Colors.white,
    ),
  );

  Widget _buildHeaderOptionItem({String title, String icon, Function onPress}) => GestureDetector(
    onTap: onPress,
    child: Column(
      children: [
        Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: main_background
          ),
          child: Image.asset(
            icon,
            color: neutral0.withOpacity(0.5),
            height: 20,
            width: 20,
          ),
        ),
        SizedBox(
          height: Utils.resizeWidthUtil(context, 20),
        ),
        TKText(
          title,
          textAlign: TextAlign.center,
          tkFont: TKFont.SFProDisplayMedium,
          style: TextStyle(fontSize: 15),
        ),
      ],
    ),
  );
}
