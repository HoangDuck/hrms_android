import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactView extends StatefulWidget {
  @override
  _ContactViewState createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  dynamic _listData;

  @override
  void initState() {
    super.initState();
    _getCompanyInfo();
  }

  _getCompanyInfo() async {
    String data = await SecureStorage().companyInfo;
    if (data != null)
      setState(() {
        _listData = json.decode(data);
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(context, () => Navigator.pop(context), () => {},
          Utils.getString(context, txt_contact), null),
      body: Column(
        children: <Widget>[
          Image.asset(img_contact),
          _listData != null
              ? Container(
                  child: Column(
                    children: <Widget>[
                      _rowItem('Hotline', Icons.phone,
                          _listData['phone_company']['v'], () async {
                        if (await canLaunch(
                            'tel:${_listData['phone_company']['v']}')) {
                          await launch(
                              'tel:${_listData['phone_company']['v']}');
                        } else {
                          throw 'Could not launch ${_listData['phone_company']['v']}';
                        }
                      }),
                      _rowItem(
                          'Email', Icons.mail, _listData['email_company']['v'],
                          () async {
                        final Uri _emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: _listData['email_company']['v'],
                            queryParameters: {'subject': 'SmartHrms contact'});
                        await launch(_emailLaunchUri.toString());
                      }),
                      _rowItem(Utils.getString(context, txt_address),
                          Icons.location_on, _listData['address']['v'], () {}),
                      _rowItem('Website', Icons.public,
                          _listData['url_company']['v'], () async {
                        if (await canLaunch(_listData['url_company']['v'])) {
                          await launch(
                            _listData['url_company']['v'],
                            forceSafariVC: true,
                            forceWebView: true,
                          );
                        } else {
                          throw 'Could not launch ${_listData['url_company']['v']}';
                        }
                      }),
                    ],
                  ),
                )
              : SizedBox.shrink()
        ],
      ),
    );
  }

  Widget _rowItem(String title, IconData icon, String value, Function onTap) =>
      Container(
        padding: EdgeInsets.only(
            top: Utils.resizeWidthUtil(context, 20),
            bottom: Utils.resizeWidthUtil(context, 20),
            left: Utils.resizeWidthUtil(context, 30),
            right: Utils.resizeWidthUtil(context, 30)),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
          color: txt_grey_color_v3.withOpacity(0.2),
          width: Utils.resizeHeightUtil(context, 1),
        ))),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              color: txt_grey_color_v1,
            ),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 20),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TKText(
                    title,
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        color: txt_grey_color_v1,
                        fontSize: Utils.resizeWidthUtil(context, 24)),
                  ),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 5),
                  ),
                  GestureDetector(
                    onTap: onTap,
                    child: TKText(
                      value,
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(
                          color: only_color,
                          fontSize: Utils.resizeWidthUtil(context, 28)),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );
}
