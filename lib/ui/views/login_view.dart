import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:device_info/device_info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/models/wifi_info.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController userNameController = TextEditingController();

  final TextEditingController numberRegisterController =
      TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController passwordRegisterController =
      TextEditingController();

  final TextEditingController rePasswordRegisterController =
      TextEditingController();

  LocalAuthentication localAuth = LocalAuthentication();

  bool _enableButton = false;

  bool _enableRegisterButton = false;

  bool isBiometricsAuthentication = false;

  bool isFaceId = false;

  bool _showRegister = false;

  bool _showRegisterButton = false;

  bool _showLoginSocial = false;

  String _showReInputPasswordWrong = '';

  FirebaseDatabase _fireBaseDatabase;

  bool _passwordVisible = true;

  dynamic registerData;

  String _fcmKey;

  String phoneNum = '';

  final facebookLogin = FacebookLogin();

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  dynamic _deviceInfo;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    // _initFireBaseDatabase();
    userNameController.addListener(_onchange);
    passwordController.addListener(_onchange);
    numberRegisterController.addListener(_onchange);
    passwordRegisterController.addListener(_onRegisterChange);
    rePasswordRegisterController.addListener(_onRegisterChange);
    _setUserName();
    _getFCMToken();
    _getCompanyPhone();
  }

  @override
  void dispose() {
    if (!mounted) {
      userNameController.dispose();
      passwordController.dispose();
      numberRegisterController.dispose();
      passwordRegisterController.dispose();
      rePasswordRegisterController.dispose();
    }
    super.dispose();
  }

  _getDeviceInfo() async {
    var stringWifiInfo =
        await SecureStorage().getCustomString(SecureStorage.WIFI_INFO);
    WifiInfo wifiInfo = WifiInfo.fromJson(json.decode(stringWifiInfo));
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceInfo = {
        'id': androidInfo.androidId,
        'name': androidInfo.model,
        'wifiInfo': {
          'identifierForVendor': wifiInfo.identifierForVendor,
          'androidId': wifiInfo.androidId,
          'wan': wifiInfo.wan,
          'lan': wifiInfo.lan,
          'wifiSSID': wifiInfo.wifiSSID,
          'wifiBSSID': wifiInfo.wifiBSSID
        }
      };
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceInfo = {
        'id': iosInfo.identifierForVendor,
        'name': iosInfo.utsname.machine,
        'wifiInfo': {
          'identifierForVendor': wifiInfo.identifierForVendor,
          'androidId': wifiInfo.androidId,
          'wan': wifiInfo.wan,
          'lan': wifiInfo.lan,
          'wifiSSID': wifiInfo.wifiSSID,
          'wifiBSSID': wifiInfo.wifiBSSID
        }
      };
    }
  }

  _initFireBaseDatabase() async {
    /*final FirebaseApp app = await FirebaseApp.configure(
      name: 'timekeeping-ba749',
      options: Platform.isIOS
          ? const FirebaseOptions(
              googleAppID: '1:966970455591:ios:26ccea9a4d7038239a8002',
              gcmSenderID: '966970455591',
              databaseURL: 'https://timekeeping-ba749.firebaseio.com/',
              apiKey: 'AIzaSyA-WWE-yz0oWJSoVR4a4mRABME6_eD69VM',
            )
          : const FirebaseOptions(
              googleAppID: '1:966970455591:android:341e3ea7220e65b19a8002',
              apiKey: 'AIzaSyA-WWE-yz0oWJSoVR4a4mRABME6_eD69VM',
              databaseURL: 'https://timekeeping-ba749.firebaseio.com/',
            ),
    );
    _fireBaseDatabase = FirebaseDatabase(app: app);
    _fireBaseDatabase
        .reference()
        .child('inAppleReviewTime')
        .once()
        .then((DataSnapshot snapshot) {
      if (snapshot.value) {
        _fireBaseDatabase
            .reference()
            .child('userTest')
            .once()
            .then((DataSnapshot snapshot) {
          registerData = snapshot.value;
          _showRegisterButton = true;
          _showLoginSocial = false;
          SecureStorage().saveCustomString(SecureStorage.SOCIAL_LOGIN, 'false');
          setState(() {});
        });
      } else {
        _showLoginSocial = true;
        SecureStorage().saveCustomString(SecureStorage.SOCIAL_LOGIN, 'true');
        setState(() {});
      }
    });*/
  }

  _checkBiometrics(BaseViewModel model) async {
    bool isUsingAuthorization = await SecureStorage()
            .getCustomString(SecureStorage.IS_USING_AUTHORIZATION) ==
        'true';
    bool isChangePassword =
        await SecureStorage().getCustomString(SecureStorage.CHANGE_PASSWORD) ==
            'true';
    bool canCheckBiometrics = await localAuth.canCheckBiometrics;
    bool _isBiometricsAuthentication = canCheckBiometrics;
    bool _isFaceId = false;
    if (isUsingAuthorization && canCheckBiometrics) {
      if (Platform.isIOS) {
        List<BiometricType> availableBiometrics =
            await localAuth.getAvailableBiometrics();
        if (canCheckBiometrics && availableBiometrics.length > 0) {
          if (availableBiometrics.contains(BiometricType.face)) {
            _isFaceId = true;
          } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
            _isFaceId = false;
          }
        }
      }

      try {
        Future.delayed(
            Duration(milliseconds: 500), () => {_loginBiometrics(model)});
      } on PlatformException catch (e) {
        if (e.code == auth_error.notAvailable) {
          _isBiometricsAuthentication = false;
        }
      }
    } else {
      _isBiometricsAuthentication = false;
      _isFaceId = false;
      if (isUsingAuthorization != null &&
          !isUsingAuthorization &&
          isChangePassword != null &&
          isChangePassword) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_notice_change_password));
      }
    }
    setState(() {
      isBiometricsAuthentication = _isBiometricsAuthentication;
      isFaceId = _isFaceId;
    });
  }

  _setUserName() async {
    String userName =
        await SecureStorage().getCustomString(SecureStorage.USERNAME);
    if (userName != null) {
      userNameController.text = userName;
    }
  }

  _loginBiometrics(BaseViewModel model) async {
    bool didAuthenticate = await localAuth.authenticate(
        stickyAuth: true,
        localizedReason: Utils.getString(context, txt_authentication_login));
    if (didAuthenticate) {
      showLoadingDialog(context);
      var data = {
        "user": userNameController.text,
        "password":
            await SecureStorage().getCustomString(SecureStorage.PASSWORD)
      };
      var loginResponse = await model.callApis(data, loginUrl, method_post);
      getUserProfile(loginResponse, model, context);
    }
  }

  _onchange() {
    if (userNameController.text.isNotEmpty &&
        passwordController.text.length >= 1) {
      _enableButton = true;
    } else
      _enableButton = false;
    setState(() {});
  }

  _onRegisterChange() {
    if (numberRegisterController.text.length >= 1 &&
        passwordRegisterController.text.length >= 1 &&
        rePasswordRegisterController.text.length >= 1) {
      _enableRegisterButton = true;
    } else
      _enableRegisterButton = false;
    setState(() {});
  }

  void getUserProfile(BaseResponse baseResponse, BaseViewModel model,
      BuildContext context) async {
    if (baseResponse.status.code == 200) {
      FirebaseMessaging.instance.deleteToken();
      await SecureStorage()
          .saveCustomString(SecureStorage.CHANGE_PASSWORD, 'false');
      await SecureStorage().saveApiToken(baseResponse.data['token']);
      if (baseResponse.data['accuserkey'] != null)
        await SecureStorage().savePushToken(baseResponse.data['accuserkey']);
      await SecureStorage().saveFcmToken(_fcmKey);
      await SecureStorage().saveCustomString(
          SecureStorage.USERNAME, baseResponse.data['username']);
      if (passwordController.text != '') {
        await SecureStorage()
            .saveCustomString(SecureStorage.PASSWORD, passwordController.text);
      }
      var profileResponse = await model.callApis(
          {}, userProfileUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      Navigator.of(context).pop();
      if (profileResponse.status.code == 200) {
        await SecureStorage().saveProfileCustomer(profileResponse);
        context.read<BaseResponse>().addData(profileResponse.data);
        Navigator.pushReplacementNamed(context, Routers.main);
      } else {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_get_data_failed));
      }
    } else {
      Navigator.of(context).pop();
      if (json.decode(baseResponse.status.message)['message'] == '')
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_error_unknown));
      else
        showMessageDialogIOS(context,
            description: json.decode(baseResponse.status.message)['message']);
    }
  }

  _getFCMToken() {
    var fireBaseMessaging = FirebaseMessaging.instance;
    fireBaseMessaging.getToken().then((String token) {
      assert(token != null);
      _fcmKey = token;
      debugPrint("Push Messaging token: $token");
    });
  }

  _getCompanyPhone() async {
    String phone = await SecureStorage().companyInfo;
    if (phone != null)
      setState(() {
        phoneNum = json.decode(phone)['phone_company']['v'].toString();
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: _showRegister,
      body: Stack(
        children: <Widget>[
          Positioned(
              top: 0,
              child: Container(
                padding:
                    EdgeInsets.only(left: Utils.resizeWidthUtil(context, 45)),
                height: Utils.resizeHeightUtil(context, 375),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [gradient_end_color, gradient_start_color])),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      Utils.getString(context, txt_title_login),
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 48),
                          color: white_color),
                      tkFont: TKFont.SFProDisplayBold,
                    ),
                    SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                    TKText(
                      Utils.getString(context, txt_description_login),
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 34),
                          color: white_color),
                      tkFont: TKFont.SFProDisplayRegular,
                    ),
                  ],
                ),
              )),
          Positioned(
            bottom: 0,
            child: Container(
                padding: EdgeInsets.only(
                    left: Utils.resizeWidthUtil(context, 45),
                    right: Utils.resizeWidthUtil(context, 45)),
                height: Utils.resizeHeightUtil(context, 1004),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.0),
                    topRight: Radius.circular(25.0),
                  ),
                ),
                child: BaseView<BaseViewModel>(
                  model: BaseViewModel(),
                  onModelReady: (model) {
                    _checkBiometrics(model);
                  },
                  builder: (context, model, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                      _textField(
                          hintText: Utils.getString(
                              context, txt_input_hint_user_name),
                          controller: userNameController,
                          onchange: (value) {}),
                      SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                      _textField(
                          hintText:
                              Utils.getString(context, txt_input_hint_password),
                          controller: passwordController,
                          isShowSuffix: true,
                          obscureText: true,
                          onchange: (value) {}),
                      SizedBox(height: Utils.resizeHeightUtil(context, 60)),
                      TKButton(Utils.getString(context, txt_login),
                          width: double.infinity,
                          enable: _enableButton, onPress: () async {
                        Utils.closeKeyboard(context);
                        String baseUrl = await SecureStorage().companyInfo;
                        if (baseUrl == null) {
                          await SecureStorage()
                              .removeCustomString(SecureStorage.USERNAME);
                          showMessageDialogIOS(context,
                              description: 'Vui lòng chọn lại công ty!',
                              onPress: () => Navigator.pushNamedAndRemoveUntil(
                                  context, Routers.chooseCompany, (r) => false));
                        } else {
                          showLoadingDialog(context);
                          var data = {
                            "user": userNameController.text,
                            "password": passwordController.text,
                            "fcmkey": _fcmKey,
                            'deviceInfo': _deviceInfo,
                            'company_id': json.decode(baseUrl)['ID']
                          };
                          var loginResponse =
                              await model.callApis(data, loginUrl, method_post);
                          getUserProfile(loginResponse, model, context);
                        }
                      }),
                      if (_showRegisterButton)
                        SizedBox(height: Utils.resizeHeightUtil(context, 30)),
                      if (_showRegisterButton)
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setState(() {
                              _showRegister = true;
                            });
                          },
                          child: Container(
                            alignment: Alignment.center,
                            width: double.infinity,
                            child: TKText(
                              Utils.getString(
                                  context, txt_title_button_register),
                              style: TextStyle(
                                  fontSize: Utils.resizeWidthUtil(context, 32),
                                  color: txt_blue),
                              tkFont: TKFont.SFProDisplayMedium,
                            ),
                          ),
                        ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 30)),
                      Container(
                        height: Utils.resizeHeightUtil(context, 8),
                        width: Utils.resizeWidthUtil(context, 88),
                        decoration: BoxDecoration(
                          color: blue_light,
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                      ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 30)),
                      isBiometricsAuthentication
                          ? GestureDetector(
                              onTap: () async {
                                _loginBiometrics(model);
                              },
                              child: Container(
                                decoration: BoxDecoration(color: Colors.white),
                                child: Image.asset(
                                    isFaceId ? ic_face_id : ic_touch_id,
                                    width: Utils.resizeWidthUtil(context, 100),
                                    height:
                                        Utils.resizeHeightUtil(context, 100)),
                              ),
                            )
                          : Container(
                              width: Utils.resizeWidthUtil(context, 100),
                              height: Utils.resizeHeightUtil(context, 100)),
                      GestureDetector(
                        onTap: () async {
                          Navigator.pushReplacementNamed(
                              context, Routers.chooseCompany);
                          await SecureStorage().deleteCompany();
                          await SecureStorage().removeCustomString(
                              SecureStorage.IS_USING_AUTHORIZATION);
                          await SecureStorage()
                              .removeCustomString(SecureStorage.USERNAME);
                        },
                        child: TKText(
                            Utils.getString(context, txt_title_choose_company),
                            style: TextStyle(
                                color: txt_blue,
                                fontSize: Utils.resizeWidthUtil(context, 32))),
                      ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          TKText(
                            'Hotline:  ',
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(color: txt_grey_color_v1),
                          ),
                          GestureDetector(
                            onTap: () async {
                              if (await canLaunch('tel:$phoneNum')) {
                                await launch('tel:$phoneNum');
                              } else {
                                throw 'Could not launch $phoneNum';
                              }
                            },
                            child: TKText(
                              phoneNum,
                              tkFont: TKFont.SFProDisplayMedium,
                              style: TextStyle(
                                  color: only_color,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                      _showLoginSocial
                          ? _loginSocial(model)
                          : SizedBox.shrink(),
                      SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                    ],
                  ),
                )),
          ),
          if (_showRegister)
            _buildRegister(),
          //if (!_showLoading) LoadingWidget(),
        ],
      ),
    );
  }

  Widget _textField(
          {String hintText,
          TextEditingController controller,
          Function(String value) onchange,
          bool obscureText = false,
          bool isShowSuffix = false,
          TextInputType type,
          int maxLength}) =>
      TextField(
        textAlign: TextAlign.start,
        controller: controller,
        obscureText: obscureText ? _passwordVisible : obscureText,
        keyboardType: type ?? TextInputType.text,
        maxLength: maxLength,
        onChanged: onchange,
        style: TextStyle(
            fontFamily: "SFProDisplay-Medium",
            fontSize: Utils.resizeWidthUtil(context, 32)),
        decoration: InputDecoration(
          suffixIcon: isShowSuffix
              ? IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                )
              : null,
          counterText: '',
          hintText: hintText,
          hintStyle: TextStyle(
              fontSize: Utils.resizeWidthUtil(context, 32),
              fontFamily: "SFProDisplay-Medium"),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(width: 1, color: only_color),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(width: 1, color: border_text_field),
          ),
          filled: true,
          contentPadding: EdgeInsets.all(16),
          fillColor: bg_text_field,
        ),
      );

  Widget _buildRegister() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Center(
        child: Wrap(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.8),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 0.5),
                  ),
                ],
              ),
              width: MediaQuery.of(context).size.width * 0.9,
              child: Stack(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                    child: Column(
                      children: <Widget>[
                        TKText(
                          Utils.getString(context, txt_title_register),
                          style: TextStyle(
                              fontSize: Utils.resizeWidthUtil(context, 48),
                              color: Colors.black),
                          tkFont: TKFont.SFProDisplayBold,
                        ),
                        SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                        Row(
                          children: <Widget>[
                            Container(
                              margin: EdgeInsets.only(right: 3),
                              child: Text(
                                '(+84)',
                                style: TextStyle(
                                    fontFamily: "SFProDisplay-Medium",
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 32)),
                              ),
                            ),
                            Expanded(
                              child: _textField(
                                  hintText: Utils.getString(
                                      context, txt_title_input_number),
                                  controller: numberRegisterController,
                                  type: TextInputType.number,
                                  maxLength: 9,
                                  onchange: (value) {}),
                            )
                          ],
                        ),
                        SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                        _textField(
                            hintText: Utils.getString(
                                context, txt_input_hint_password),
                            controller: passwordRegisterController,
                            obscureText: true,
                            onchange: (value) {}),
                        SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                        _textField(
                            hintText: Utils.getString(
                                context, txt_re_input_password_register),
                            controller: rePasswordRegisterController,
                            obscureText: true,
                            onchange: (value) {}),
                        SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                        if (_showReInputPasswordWrong.isNotEmpty)
                          TKText(
                            _showReInputPasswordWrong,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 32),
                                color: Colors.red),
                            tkFont: TKFont.SFProDisplayBold,
                          ),
                        SizedBox(height: Utils.resizeHeightUtil(context, 50)),
                        TKButton(
                            Utils.getString(context, txt_title_button_register),
                            width: double.infinity,
                            enable: _enableRegisterButton, onPress: () {
                          if (passwordRegisterController.text !=
                              rePasswordRegisterController.text) {
                            _showReInputPasswordWrong = Utils.getString(
                                context, txt_title_re_input_wrong);
                            setState(() {});
                          } else {
                            bool existed = false;
                            if (registerData != null) {
                              registerData.forEach((key, value) {
                                if (value['userName'].toString().contains(
                                    numberRegisterController.text.trim())) {
                                  existed = true;
                                  return;
                                }
                              });
                            }
                            if (!existed) {
                              _fireBaseDatabase
                                  .reference()
                                  .child('accountTest')
                                  .push()
                                  .set(<String, String>{
                                'number': numberRegisterController.text.trim(),
                                'passWord':
                                    rePasswordRegisterController.text.trim(),
                              });
                              showMessageDialogIOS(context,
                                  description: Utils.getString(
                                      context, txt_title_register_success),
                                  onPress: () {
                                _showRegister = false;
                                setState(() {});
                                Navigator.pop(context);
                                numberRegisterController.text = '';
                                passwordRegisterController.text = '';
                                rePasswordRegisterController.text = '';
                              });
                            } else {
                              _showReInputPasswordWrong = Utils.getString(
                                  context, txt_title_number_existed);
                            }
                            setState(() {});
                          }
                        }),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: GestureDetector(
                      onTap: () {
                        _showRegister = false;
                        setState(() {});
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Icon(Icons.clear, color: Colors.grey),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _circleContainer(String icon) => Container(
        padding: EdgeInsets.all(10),
        height: Utils.resizeHeightUtil(context, 75),
        width: Utils.resizeWidthUtil(context, 75),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: white_color,
          boxShadow: [
            BoxShadow(
                color: txt_grey_color_v1.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 2.0)
          ],
        ),
        child: Image.asset(icon),
      );

  Widget _loginSocial(BaseViewModel model) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            child: _circleContainer(ic_facebook),
            onTap: () async {
              final result = await facebookLogin.logIn(['email']);
              switch (result.status) {
                case FacebookLoginStatus.loggedIn:
                  print(result.accessToken.token);
                  List<Map<String, dynamic>> params = [];
                  Map<String, dynamic> accessToken = Map();
                  accessToken['key'] = 'accessTokenValue';
                  accessToken['value'] = result.accessToken.token;
                  params.add(accessToken);
                  showLoadingDialog(context);
                  var loginResponse = await model.callApis(
                      {}, loginFacebookUrl, method_post,
                      params: params, isLoginSocial: true);
                  getUserProfile(loginResponse, model, context);
                  break;
                case FacebookLoginStatus.cancelledByUser:
                  showMessageDialog(context,
                      description:
                          Utils.getString(context, txt_facebook_cancel));
                  break;
                case FacebookLoginStatus.error:
                  print(result);
                  showMessageDialog(context,
                      description:
                          Utils.getString(context, txt_login_facebook_failed));
                  break;
              }
            },
          ),
          SizedBox(width: Utils.resizeWidthUtil(context, 40)),
          GestureDetector(
            child: _circleContainer(ic_google),
            onTap: () async {
              var result = await _googleSignIn.signIn();
              print("google login: $result");
              result.authentication.then((googleKey) async {
                List<Map<String, dynamic>> params = [];
                Map<String, dynamic> accessToken = Map();
                accessToken['key'] = 'accessTokenValue';
                accessToken['value'] = googleKey.accessToken;
                params.add(accessToken);
                showLoadingDialog(context);
                var loginResponse = await model.callApis(
                    {}, loginGoogleUrl, method_post,
                    params: params, isLoginSocial: true);
                getUserProfile(loginResponse, model, context);
              }).catchError((err) {
                print('inner error');
              });
            },
          ),
          SizedBox(width: Utils.resizeWidthUtil(context, 40)),
          GestureDetector(
              child: _circleContainer(ic_zalo),
              onTap: () async {
                String result = await Utils.platform.invokeMethod('loginZalo');
                debugPrint(result);
                List<Map<String, dynamic>> params = [];
                Map<String, dynamic> accessToken = Map();
                accessToken['key'] = 'accessTokenValue';
                accessToken['value'] = result;
                params.add(accessToken);
                showLoadingDialog(context);
                var loginResponse = await model.callApis(
                    {}, loginZaloUrl, method_post,
                    params: params, isLoginSocial: true);
                getUserProfile(loginResponse, model, context);
              })
        ],
      );
}
