import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class MenuOwnerView extends StatefulWidget {
  final data;

  MenuOwnerView(this.data);

  @override
  _MenuOwnerViewState createState() => _MenuOwnerViewState();
}

class _MenuOwnerViewState extends State<MenuOwnerView> {


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_view_color,
      appBar: appBarCustom(context, () => Navigator.pop(context), () {},
          widget.data['title'], null),
      body: Card(
        margin: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.data['data'].length,
          itemBuilder: (context, index) {
            dynamic _data = jsonDecode(widget.data['data'][index]['ThongSo']['v']);
            return _itemContent(
                title: widget.data['data'][index]['Ten']['v'],
                icon: widget.data['data'][index]['Icon']['v'],
                onPress: () =>
                    Navigator.pushNamed(context, _data['router'], arguments: {
                      'title': 'Quản lý ${widget.data['data'][index]['Ten']['v']}',
                      'url': 'api/data/process/${_data['url']}',
                      'dataRequest': _data['dataRequest'],
                      'icon': widget.data['data'][index]['Icon']['v'],
                      'titleUpdate': 'Cập nhật ${widget.data['data'][index]['Ten']['v']}',
                      'titleAdd': 'Thêm ${widget.data['data'][index]['Ten']['v']}',
                      'routerAdd': _data['routerAdd'],
                      'routerUpdate': _data['routerUpdate']
                    }));
          }
        )
      ),
    );
  }

  Widget _itemContent(
      {String title,
      Function onPress,
      String icon,
      bool isShowIcon = true,
      bool isShowBorder = true}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onPress,
      child: Container(
        height: Utils.resizeWidthUtil(context, 80),
        padding: EdgeInsets.only(
            bottom: Utils.resizeHeightUtil(context, 20),
            left: Utils.resizeWidthUtil(context, 30),
            right: Utils.resizeWidthUtil(context, 30)),
        decoration: isShowIcon
            ? BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                color: txt_grey_color_v3.withOpacity(0.2),
                width: Utils.resizeHeightUtil(context, 1),
              )))
            : null,
        margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Row(
                children: <Widget>[
                  Image.network(avatarUrl + icon),
                  SizedBox(
                    width: Utils.resizeWidthUtil(context, 20),
                  ),
                  TKText(
                    title,
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        color: txt_grey_color_v3,
                        fontSize: Utils.resizeWidthUtil(context, 30)),
                  ),
                ],
              ),
            ),
            isShowIcon
                ? Image.asset(ic_arrow_forward,
                    width: Utils.resizeWidthUtil(context, 11),
                    height: Utils.resizeHeightUtil(context, 22))
                : Container()
          ],
        ),
      ),
    );
  }
}
