import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class LinkSocialAccountView extends StatefulWidget {
  @override
  _LinkSocialAccountViewState createState() => _LinkSocialAccountViewState();
}

class _LinkSocialAccountViewState extends State<LinkSocialAccountView> {
  BaseResponse _user;

  final facebookLogin = FacebookLogin();

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  _link(var data) async {
    showLoadingDialog(context);
    BaseViewModel model = BaseViewModel();
    var encryptData = await Utils.encrypt("tbAccountInfo");
    var response = await model.callApis({
      "tbname": encryptData,
      "dataid": _user.data['data'][0]['AccountID']['v'],
      ...data,
    }, updateDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      var profileResponse = await model.callApis(
          {}, userProfileUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      Navigator.pop(context);
      if (profileResponse.status.code == 200) {
        await SecureStorage().saveProfileCustomer(profileResponse);
        context.read<BaseResponse>().addData(profileResponse.data);
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success));
      } else {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_get_data_failed));
      }
    } else {
      Navigator.pop(context);
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
    }
  }

  _linkFacebook() async {
    final result = await facebookLogin.logIn(['email']);
    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        print(result.accessToken.token);
        var profileResponse = await http.get(Uri.parse(
            'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=${result.accessToken.token}'));
        var profile = json.decode(profileResponse.body);
        _link({
          "FacebookUserName": profile['name'],
          "EmailFaceBook": profile['email'],
          "FacebookUserID": profile['id']
        });
        break;
      case FacebookLoginStatus.cancelledByUser:
        showMessageDialog(context,
            description: Utils.getString(context, txt_facebook_cancel));
        break;
      case FacebookLoginStatus.error:
        print(result);
        showMessageDialog(context,
            description: Utils.getString(context, txt_login_facebook_failed));
        break;
    }
  }

  _linkGoogle() async {
    var result = await _googleSignIn.signIn();
    result.authentication.then((googleKey) async {
      _link({
      "GoogleUserName": result.displayName,
      "EmailGoogle": result.email,
      "GoogleUserID": result.id,
      "GoogleAccessToken": googleKey.accessToken
      });
    });
  }

  _linkZalo() async {
    await Utils.platform.invokeMethod('loginZalo');
    String profile = await Utils.platform.invokeMethod('getZaloProfile');
    var resultProfile = jsonDecode(profile);
    debugPrint(resultProfile['name']);
    _link({
      "ZaloUserName": resultProfile['name'],
      "ZaloUserID": resultProfile['id']
    });
  }

  @override
  Widget build(BuildContext context) {
    _user = context.watch<BaseResponse>();
    return Scaffold(
      appBar: appBarCustom(context, () => Navigator.pop(context), () => {},
          Utils.getString(context, txt_account_social), null),
      body: ListView(
        children: <Widget>[
          _listItem(
              ic_facebook,
              _user.data['data'][0]['FacebookUserName']['v'],
              TypeSocial.facebook),
          _listItem(ic_google,
              _user.data['data'][0]['GoogleUserName']['v'], TypeSocial.gmail),
          _listItem(ic_zalo,
              _user.data['data'][0]['ZaloUserName']['v'], TypeSocial.zalo)
        ],
      ),
    );
  }

  Widget _listItem(String icon, String userName, TypeSocial type) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () async {
          switch (type) {
            case TypeSocial.facebook:
              if (userName != '')
                showMessageDialogIOS(context,
                    description: userName,
                    buttonText: txt_un_link, onPress: () {
                  Navigator.pop(context);
                  _link({
                    "FacebookUserName": '',
                    "EmailFaceBook": '',
                    "FacebookAccessToken": '',
                    "FacebookUserID": ''
                  });
                });
              else {
                _linkFacebook();
              }
              break;
            case TypeSocial.gmail:
              if (userName != '')
                showMessageDialog(context,
                    description: userName,
                    buttonText: txt_un_link, onPress: () {
                  Navigator.pop(context);
                  _link({
                    "GoogleUserName": '',
                    "EmailGoogle": '',
                    "GoogleAccessToken": '',
                    "GoogleUserID": ''
                  });
                });
              else {
                _linkGoogle();
              }
              break;
            case TypeSocial.zalo:
              if (userName != '')
                showMessageDialog(context,
                    description: userName,
                    buttonText: txt_un_link, onPress: () {
                  Navigator.pop(context);
                  _link({
                    "ZaloUserName": '',
                    "ZaloAccessToken": '',
                    "ZaloUserID": ''
                  });
                });
              else {
                _linkZalo();
              }
          }
        },
        child: Container(
          padding: EdgeInsets.only(
              bottom: Utils.resizeHeightUtil(context, 20),
              left: Utils.resizeWidthUtil(context, 30),
              right: Utils.resizeWidthUtil(context, 30)),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
            color: txt_grey_color_v3.withOpacity(0.2),
            width: Utils.resizeHeightUtil(context, 1),
          ))),
          margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Image.asset(icon,
                        width: Utils.resizeWidthUtil(context, 50),
                        height: Utils.resizeWidthUtil(context, 50))
                  ],
                ),
              ),
              TKText(
                userName == '' ? Utils.getString(context, txt_link) : userName,
                tkFont: TKFont.SFProDisplayRegular,
                style: TextStyle(color: only_color),
              ),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 20),
              ),
              Image.asset(ic_arrow_forward,
                  color: only_color,
                  width: Utils.resizeWidthUtil(context, 11),
                  height: Utils.resizeHeightUtil(context, 22))
            ],
          ),
        ),
      );
}

enum TypeSocial { facebook, gmail, zalo }
