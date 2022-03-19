import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:launch_review/launch_review.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class ProfileView extends StatefulWidget {
  ProfileView();

  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  BaseResponse _user;

  String isShowSocial = '';
  String isFaceID = '';
  var fireBaseMessaging = FirebaseMessaging.instance;
  bool isMainReload = false;
  bool isAllowEditPassword = false;

  @override
  void initState() {
    super.initState();
    getShowOption();
    _user = context.read<BaseResponse>();
    checkAllowEdit();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  getShowOption() async {
    isShowSocial =
        await SecureStorage().getCustomString(SecureStorage.SOCIAL_LOGIN);
    isFaceID = await SecureStorage().getCustomString(SecureStorage.FACE_ID_LOGIN);
    setState(() {});
  }

  checkAllowEdit() async {
    var _user = await SecureStorage().userProfile;
    setState(() {
      isAllowEditPassword = _user.data['data'][0]['UserAccount_IsChangePass']['v'] == 'True' ? true : false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: main_background,
      extendBodyBehindAppBar: true,
      appBar: appBarCustom(context, () => Navigator.pop(context, isMainReload), () => {},
          Utils.getString(context, txt_profile_title), null,
          hideBackground: true),
      body: Stack(
        children: <Widget>[
          _background(),
          _content(),
        ],
      ),
    );
  }

  Widget _background() => Container(
        height: Utils.resizeHeightUtil(context, 250),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [gradient_end_color, gradient_start_color])),
      );

  Widget _content() => Container(
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 180)),
      child: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Container(
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 180),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      children: <Widget>[
                        _itemContent(
                            title: txt_modify_profile,
                            icon: ic_profile_edit,
                            onPress: () {
                              Navigator.pushNamed(context, Routers.editProfile,
                                  arguments: _user);
                            }),
                        if(isAllowEditPassword)
                        _itemContent(
                            title: txt_title_password_change,
                            icon: ic_change_password,
                            onPress: () {
                              Navigator.pushNamed(
                                  context, Routers.changePassword);
                            }),
                        isShowSocial == 'false'
                            ? SizedBox.shrink()
                            : _itemContent(
                                title: txt_account_social,
                                icon: ic_social,
                                onPress: () {
                                  Navigator.pushNamed(
                                      context, Routers.socialLink);
                                }),
                        _itemContent(
                                title: txt_user_setting,
                                icon: ic_fingerprint,
                                isShowIcon: true,
                                onPress: () async {
                                  Navigator.pushNamed(
                                      context, Routers.settingsAuthorization,
                                      arguments: '').then((value) {
                                        if(value) {
                                          getShowOption();
                                          isMainReload = true;
                                        }
                                  });
                                })
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                        top: Utils.resizeWidthUtil(context, 20)),
                    decoration: BoxDecoration(color: Colors.white),
                    child: Column(
                      children: <Widget>[
                        _itemContent(
                            title: txt_frequently_asked_question,
                            icon: ic_fqa,
                            onPress: () => Navigator.pushNamed(
                                    context, Routers.userGuide,
                                    arguments: {
                                      'title': Utils.getString(context,
                                          txt_frequently_asked_question),
                                      'type': 'questions'
                                    })),
                        _itemContent(
                            title: txt_user_manual,
                            icon: ic_tutorial,
                            onPress: () => Navigator.pushNamed(
                                    context, Routers.userGuide, arguments: {
                                  'title':
                                      Utils.getString(context, txt_user_manual),
                                  'type': 'guide'
                                })),
                        _itemContent(
                            title: txt_software_review,
                            icon: ic_rating,
                            onPress: () {
                              LaunchReview.launch(
                                  androidAppId: txt_app_id,
                                  iOSAppId: txt_apple_id);
                            }),
                        _itemContent(
                            icon: ic_contact,
                            isShowIcon: true,
                            title: txt_contact,
                            onPress: () =>
                                Navigator.pushNamed(context, Routers.contact))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 20),
                  ),
                  Container(
                    child: _itemContent(
                        isShowIcon: false,
                        isShowBorder: false,
                        title: txt_log_out,
                        icon: ic_logout,
                        onPress: () {
                          showMessageDialog(context,
                              description:
                                  Utils.getString(context, txt_request_logout),
                              onPress: () async {
                            String pushToken = await SecureStorage().pushToken;
                            fireBaseMessaging.unsubscribeFromTopic(pushToken);
                            await SecureStorage().deletePushToken();
                            SecureStorage().removeCustomString(
                                SecureStorage.PROFILE_CUSTOMER);
                            SecureStorage().deleteToken();
                            Navigator.pushNamedAndRemoveUntil(
                                context, Routers.login, (r) => false);
                          });
                        }),
                  ),
                ],
              ),
            ),
            _userTaskBar()
          ],
        ),
      ));

  Widget _userTaskBar() {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: Utils.resizeWidthUtil(context, 30)),
            height: Utils.resizeHeightUtil(context, 150),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12.0,
                  offset: Offset(0, 3),
                )
              ],
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(Utils.resizeWidthUtil(context, 16)),
            ),
            child: _userInfo(),
          ),
        ],
      ),
    );
  }

  Widget _userInfo() {
    var avatar = _user.data['data'][0]['avatar']['v'].toString() != ''
        ? '$avatarUrl${_user.data['data'][0]['avatar']['v'].toString()}'
        : avatarDefaultUrl;
    var avatarFileName = _user.data['data'][0]['avatar']['v'].toString() != ''
        ? '${_user.data['data'][0]['avatar']['v'].toString()}'
        : avatarDefaultUrl.split('/').last;
    return Row(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 20)),
          width: Utils.resizeWidthUtil(context, 100),
          height: Utils.resizeWidthUtil(context, 100),
          child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: NetworkToFileImage(
                url: avatar,
                file: Utils().fileFromDocsDir(avatarFileName),
              )),
        ),
        Container(
          margin: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TKText(
                (_user != null)
                    ? "${Utils.getString(context, txt_main_view_hello)} "
                        "${_user.data['data'][0]['full_name']['r'].toString()}!"
                    : Utils.getString(context, txt_waiting),
                style: TextStyle(
                    fontSize: Utils.resizeWidthUtil(context, 36),
                    color: txt_black_color,
                    decoration: TextDecoration.none),
                textAlign: TextAlign.left,
                tkFont: TKFont.SFProDisplayBold,
              ),
              SizedBox(
                height: Utils.resizeHeightUtil(context, 5),
              ),
              TKText(
                Utils.getString(context, txt_main_view_wishes),
                tkFont: TKFont.SFProDisplayRegular,
                style: TextStyle(
                    fontSize: Utils.resizeWidthUtil(context, 32),
                    color: txt_grey_color_v2,
                    decoration: TextDecoration.none),
              ),
            ],
          ),
        )
      ],
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
                  Image.asset(icon,
                      width: Utils.resizeWidthUtil(context, 36),
                      height: Utils.resizeWidthUtil(context, 36)),
                  SizedBox(
                    width: Utils.resizeWidthUtil(context, 20),
                  ),
                  TKText(
                    Utils.getString(context, title),
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
