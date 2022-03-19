import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/components/local_notification.dart';
import 'package:gsot_timekeeping/core/enums/connectivity_status.dart';
import 'package:gsot_timekeeping/core/models/working_report_main.dart';
import 'package:gsot_timekeeping/core/mqtt/mqtt_services.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/connectivity_service.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/services/timekeeping_backgroud_service.dart';
import 'package:gsot_timekeeping/core/services/working_report_service.dart';
import 'package:gsot_timekeeping/core/storage/database_helper.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/loading.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:permission_handler/permission_handler.dart' as permission;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_value.dart';

String avatarUrl = 'https://apiadmin.gsotgroup.vn';
String avatarUrlAPIs = 'https://apihrms.gsotgroup.vn';
final Mqtt mQttServices = Mqtt.mQttServices;

class MainView extends StatefulWidget {
  @override
  _MainViewState createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  List<dynamic> _menu = [];
  DatabaseHelper dbHelper = DatabaseHelper.instance;

  DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd');

  DateFormat inOutFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  int status = 0;

  String _deviceBrand;

  Location location = Location();

  List<BottomAppBarItemCustom> _bottomItems = [];

  TabController _tabController;

  BottomAppBarCustomState _state;

  dynamic menuCenter;

  AnimationController _controllerRotate;

  int _crossAxisCount = 3;

  double height = 0;

  double heightEstimate = 0;

  int totalRequest = 0;
  var fireBaseMessaging = FirebaseMessaging.instance;
  var model;

  bool _isRotated = true;

  AnimationController _controller;
  Animation<double> _animation;
  String isQRCode = '';
  String isNFC = '';
  String isTensorFlow = '';
  double heightScale = 0.0;

  int check = 0;

  List<dynamic> listMenuChat = [
    {'ID': '1', 'Name': 'Trò chuyện', 'Icon': Icons.chat},
    {
      'ID': '2',
      'Name': 'Trao đổi với nv phụ trách',
      'Icon': Icons.announcement
    },
    {'ID': '3', 'Name': 'Bản tin', 'Icon': Icons.newspaper}
  ];

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 180),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 1.0, curve: Curves.linear),
    );
    _controller.reverse();
    super.initState();
    _getDeviceInfo();
    model = BaseViewModel();
    checkTimekeepingOffline(model);
    _getUser(context);
    _getWorkingReportMain(model);
    _getMenu(model);
    context.read<ConnectivityService>();
    _checkMenu(model);
    showTimekeepingDialog(isTimekeeping: true);
    _getTotalRequestWaiting();
    _controllerRotate = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    );
    _controllerRotate.repeat();
    initFirebaseMessaging();

    //initialize mqtt
    // mQttServices.init();
  }

  void _rotate() {
    setState(() {
      if (_isRotated) {
        _isRotated = false;
        _controller.forward();
      } else {
        _isRotated = true;
        _controller.reverse();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    calculatedPadding();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controllerRotate.dispose();
    _controller.dispose();
    super.dispose();
  }

  initFirebaseMessaging() async {
    String pushToken = await SecureStorage().pushToken;
    print('MESSAGING TOKEN:' + pushToken);
    fireBaseMessaging.subscribeToTopic(pushToken);
    fireBaseMessaging
        .subscribeToTopic(pushToken.replaceAll(new RegExp(r'[^\w\s]+'), ''));
    Future.delayed(Duration(seconds: 1), () {
      FirebaseMessaging.onMessage.listen((message) {
        dynamic dataFormat = Platform.isAndroid ? message.data : message;
        if (dataFormat['notification_types'] != null &&
            dataFormat['notification_types'] ==
                'chat_message') if (currentPage == 'ChatsView')
          return;
        else {
          showNotification(dataFormat['title'], dataFormat['body'],
              type: dataFormat['notification_types'],
              data: dataFormat['room_data']);
          return;
        }
        if (message != null) {
          if (int.parse(dataFormat['type']) == 2) return;
          showPushNotification(context, message);
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (message != null) {
          dynamic dataFormat = Platform.isAndroid ? message.data : message;
          if (dataFormat['notification_types'] != null &&
              dataFormat['notification_types'] == 'chat_message') {
            Navigator.pushNamed(
              context,
              Routers.chatEmpView,
              arguments: jsonDecode(dataFormat['room_data']),
            );
            return;
          }
          switch (int.parse(dataFormat['type'])) {
            case 0:
              return;
            case 1:
              showPushNotification(context, message);
              return;
            case 2:
              Navigator.pushNamed(context, dataFormat['navigator']);
          }
        }
      });
    });
  }

  _tabChange() {
    if (_state != null &&
        _tabController.index == _tabController.animation.value.round()) {
      _state.updateIndex(_tabController.animation.value.round());
    }
  }

  _getUser(BuildContext context) async {
    var _user = await SecureStorage().userProfile;
    String _companyInfo = await SecureStorage().companyInfo;
    avatarUrl = jsonDecode(_companyInfo)['urlwebs_company']['v'];
    avatarUrlAPIs = jsonDecode(_companyInfo)['urlapis_company']['v'];
    if (_user.data['data'][0]['Timekeeping_IsTracking']['v'] == 'True') {
      Future.delayed(Duration(seconds: 10), () {
        // print('RUN BACKGROUND TRACKING');
        // addPeriodicBackgroundFetch(init: true);
      });
    }
    await SecureStorage().saveCustomString(
        SecureStorage.IS_USING_AUTHORIZATION,
        _user.data['data'][0]['Login_IsFingerprint']['v'] == 'False'
            ? 'false'
            : 'true');
    await SecureStorage().saveCustomString(
        SecureStorage.QR_CODE,
        _user.data['data'][0]['Timekeeping_IsQrCode']['v'] == 'False'
            ? 'false'
            : 'true');
    await SecureStorage().saveCustomString(
        SecureStorage.NFC,
        _user.data['data'][0]['Timekeeping_IsRFID']['v'] == 'False'
            ? 'false'
            : 'true');
    await SecureStorage().saveCustomString(
        SecureStorage.TENSOR_FLOW,
        _user.data['data'][0]['Timekeeping_IsTFFaceAuto']['v'] == 'False'
            ? 'false'
            : 'true');
    context.read<BaseResponse>().addData(_user.data);
    setState(() {
      isQRCode = _user.data['data'][0]['Timekeeping_IsQrCode']['v'] == 'False'
          ? 'false'
          : 'true';
      isNFC = _user.data['data'][0]['Timekeeping_IsRFID']['v'] == 'False'
          ? 'false'
          : 'true';
      isTensorFlow =
          _user.data['data'][0]['Timekeeping_IsTFFaceAuto']['v'] == 'False'
              ? 'false'
              : 'true';
    });
  }

  void _getWorkingReportMain(BaseViewModel model) async {
    await Future.delayed(Duration(seconds: 1));
    var connectStatus = context.read<ConnectivityService>().status;
    if (connectStatus != ConnectivityStatus.Offline) {
      var data = {'date_working': dateFormat.format(DateTime.now()).toString()};
      var mainReportResponse = await model.callApis(
          data, getWorkingMain, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (mainReportResponse.status.code == 200) {
        WorkingReportMain workingReportMain;
        if (mainReportResponse.data['data'].length > 0) {
          workingReportMain = WorkingReportMain(
              startTimeKeeping: mainReportResponse.data['data'][0]
                  ['start_time_timecheck']['v'],
              endTimeKeeping: mainReportResponse.data['data'][0]
                  ['end_time_timecheck']['v'],
              salaryWorkDay: '0',
              totalWorkday: '0');
          var dashboardResponse = await model.callApis(
              {'date': dateTimeFormat.format(DateTime.now())},
              workingMonthUrl,
              method_post,
              isNeedAuthenticated: true,
              shouldSkipAuth: false);
          if (dashboardResponse.status.code == 200) {
            if (dashboardResponse.data['data'].length > 0) {
              workingReportMain.salaryWorkDay =
                  dashboardResponse.data['data'][0]['congtong_tinhluong']['v'];
              workingReportMain.totalWorkday =
                  dashboardResponse.data['data'][0]['congchuan']['v'];
            } else {
              workingReportMain =
                  WorkingReportMain(salaryWorkDay: '0', totalWorkday: '0');
            }
          } else {
            workingReportMain =
                WorkingReportMain(salaryWorkDay: '0', totalWorkday: '0');
          }
          context
              .read<WorkingReportService>()
              .addWorkingReport(workingReportMain);
        }
      }
    }
  }

  void _getMenu(BaseViewModel model) async {
    final menus = await dbHelper.getAllData(dbHelper.menuTableName);
    if (menus.length > 0 && jsonDecode(menus[0]['value']).length > 0) {
      _menu = jsonDecode(menus[0]['value']);
    } else {
      _menu = await _getMenuValues(model);
      await dbHelper.insert(dbHelper.menuTableName, {
        DatabaseHelper.columnId: 1,
        DatabaseHelper.columnValue: jsonEncode(_menu).toString(),
      });
    }
    setState(() {
      _initMenuAfterCheck();
    });
  }

  _initMenuAfterCheck() {
    for (var value in _menu.where((value) => value[3] == 'False').toList()) {
      _bottomItems.add(BottomAppBarItemCustom(
          iconData: '${avatarUrl + value[1]}', text: value[0]));
    }
    _tabController = TabController(
        vsync: this,
        initialIndex: 0,
        length: _menu.where((value) => value[3] == 'False').length);
    _tabController.animation..addListener(_tabChange);
  }

  Future<List> _getMenuValues(BaseViewModel model) async {
    var menuResponse = await model.callApis({}, getMenuUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    List _listMenu = [];
    if (menuResponse.status.code == 200) {
      for (var mn in menuResponse.data['data']) {
        if (mn['ID'] == mn['Thuoc']['v']) {
          List _subMenu = [];
          for (var subMN in mn['MenuCon']['v'][0]) {
            subMN['MenuCon']['v'][0].sort((a, b) =>
                num.parse(a['STT']['v']).compareTo(num.parse(b['STT']['v'])));
            _subMenu.add([
              subMN['Ten']['v'],
              subMN['Icon']['v'],
              subMN['BackEnd_Menu_ID']['v'],
              subMN['ThongSo']['v'],
              subMN['MenuCon']['v']
            ]);
          }
          // _subMenu.sort((a, b) => num.parse(a[2]).compareTo(num.parse(b[2])));
          _listMenu.add([
            mn['Ten']['v'],
            mn['Icon']['v'],
            _subMenu,
            mn['IsCenter']['v'],
            mn['StartColor']['v'],
            mn['EndColor']['v'],
            mn['Duration']['v']
          ]);
        }
      }
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () async {
        String pushToken = await SecureStorage().pushToken;
        fireBaseMessaging.unsubscribeFromTopic(pushToken);
        await SecureStorage().deletePushToken();
        SecureStorage().removeCustomString(SecureStorage.PROFILE_CUSTOMER);
        SecureStorage().deleteToken();
        Navigator.pushNamedAndRemoveUntil(context, Routers.login, (r) => false);
      });
    }
    return _listMenu;
  }

  Future<bool> checkPermission() async {
    // geo.Geolocator geoLocator = geo.Geolocator()..forceAndroidLocationManager = true;
    // geoLocator.isLocationServiceEnabled();
    var results = true;
    if (Platform.isAndroid) {
      results = await Utils.platform.invokeMethod('checkPermission');
    }
    if (results &&
        await permission.Permission.camera.isGranted &&
        await permission.Permission.storage.isGranted &&
        await permission.Permission.microphone.isGranted &&
        await permission.Permission.location.isGranted) {
      return true;
    } else if (!results &&
            await permission.Permission.camera.isPermanentlyDenied ||
        await permission.Permission.storage.isPermanentlyDenied ||
        await permission.Permission.microphone.isPermanentlyDenied ||
        await permission.Permission.location.isPermanentlyDenied) {
      showMessageDialog(context,
          description: Utils.getString(context, txt_settings_location_error),
          buttonText: txt_go_settings, onPress: () async {
        Navigator.popUntil(context, ModalRoute.withName(Routers.main));
        permission.openAppSettings();
      }, onPressX: () async {
        Navigator.popUntil(context, ModalRoute.withName(Routers.main));
      });
      return false;
    } else {
      if (Platform.isAndroid) {
        var result = await [
          permission.Permission.location,
          permission.Permission.camera,
          permission.Permission.microphone,
          permission.Permission.storage
        ].request();
        if (result[permission.Permission.location] ==
                permission.PermissionStatus.granted &&
            result[permission.Permission.camera] ==
                permission.PermissionStatus.granted &&
            result[permission.Permission.storage] ==
                permission.PermissionStatus.granted &&
            result[permission.Permission.microphone] ==
                permission.PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      } else {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_settings_location_error),
            buttonText: txt_go_settings, onPress: () async {
          Navigator.popUntil(context, ModalRoute.withName(Routers.main));
          permission.openAppSettings();
        }, onPressX: () async {
          Navigator.popUntil(context, ModalRoute.withName(Routers.main));
        });
        return false;
      }
    }
  }

  _checkMenu(BaseViewModel model) async {
    await Future.delayed(Duration(seconds: 1));
    var connectStatus = context.read<ConnectivityService>().status;
    if (connectStatus != ConnectivityStatus.Offline) {
      var menuValues = await _getMenuValues(model);
      if (!menuValues.toString().contains(_menu.toString())) {
        setState(() {
          _menu = menuValues;
          _bottomItems.clear();
          _initMenuAfterCheck();
        });
        await dbHelper.update(dbHelper.menuTableName, {
          DatabaseHelper.columnId: 1,
          DatabaseHelper.columnValue: jsonEncode(menuValues).toString(),
        });
      }
    }
  }

  _getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceBrand = androidInfo.brand;
      });
    } else {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceBrand = iosInfo.utsname.machine;
      });
    }
  }

  void _getTotalRequestWaiting() async {
    await Future.delayed(Duration(seconds: 1));
    var connectStatus = context.read<ConnectivityService>().status;
    if (connectStatus != ConnectivityStatus.Offline) {
      var response = await BaseViewModel().callApis(
          {}, totalRequestWaitingUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      if (response.status.code == 200)
        setState(() {
          if (response.data['data'][0]['total']['v'] == '')
            totalRequest = 0;
          else
            totalRequest = int.parse(response.data['data'][0]['total']['v']);
        });
      else
        debugPrint('_getTotalRequestWaiting error');
    }
  }

  String checkTotalRequest(int value) {
    if (value > 99)
      return '99+';
    else
      return value.toString();
  }

  checkTimekeepingOffline(BaseViewModel model) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String timekeepingData = prefs.getString(TIMEKEEPING_DATA_KEY);
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none &&
        timekeepingData != null) {
      var _user = await SecureStorage().userProfile;
      if (_user.data['data'][0]['Timekeeping_IsTFFaceAuto']['v'] == 'True')
        _runTensorFlowDetect(prefs, timekeepingData);
      else
        _runMicrosoftDetect(prefs, timekeepingData);
    }
  }

  _runMicrosoftDetect(SharedPreferences prefs, String timekeepingData) async {
    var dataSubmit = jsonDecode(timekeepingData);
    for (int i = 0; i < dataSubmit.length; i++) {
      var submitResponse = await BaseViewModel().callApis({
        ...{"isOffline": true},
        ...{'error': false},
        ...dataSubmit[i]
      }, timeKeepingUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (submitResponse.status.code == 200) {
        showMessageDialog(context,
            title: submitResponse.data['data'][0]['isSuccees'] == 0
                ? title_timekeeping_fail
                : title_timekeeping_success,
            description: '${submitResponse.data['data'][0]['msg']}');
      } else {
        showMessageDialog(context,
            title: title_timekeeping_fail, description: 'Chấm công thất bại');
      }
    }
    await prefs.remove(TIMEKEEPING_DATA_KEY);
    await prefs.remove(EVENTS_KEY);
  }

  _runTensorFlowDetect(SharedPreferences prefs, String timekeepingData) async {
    List faceData = jsonDecode(prefs.getString(PREDICTED_DATA));
    var response = await BaseViewModel().callApis(
        {}, getFaceTrainUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    var dataSubmit = jsonDecode(timekeepingData);
    if (response.status.code == 200) {
      if (response.data['data'][0]['TF_FaceID']['v'] != '') {
        bool result = _searchResult(
            faceData, jsonDecode(response.data['data'][0]['TF_FaceID']['v']));
        if (result) {
          for (int i = 0; i < dataSubmit.length; i++) {
            var submitResponse = await BaseViewModel().callApis({
              ...{"isOffline": true},
              ...{'error': false},
              ...dataSubmit[i]
            }, timeKeepingUrl, method_post,
                isNeedAuthenticated: true, shouldSkipAuth: false);
            if (submitResponse.status.code == 200) {
              showMessageDialog(context,
                  title: submitResponse.data['data'][0]['isSuccees'] == 0
                      ? title_timekeeping_fail
                      : title_timekeeping_success,
                  description: '${submitResponse.data['data'][0]['msg']}');
            } else {
              showMessageDialog(context,
                  title: title_timekeeping_fail,
                  description: 'Chấm công thất bại');
            }
          }
        } else
          for (int i = 0; i < dataSubmit.length; i++) {
            var submitResponse = await BaseViewModel().callApis({
              ...{"isOffline": true},
              ...{"error": true},
              ...dataSubmit[i]
            }, timeKeepingUrl, method_post,
                isNeedAuthenticated: true, shouldSkipAuth: false);
            if (submitResponse.status.code == 200)
              showNotification(title_timekeeping_fail,
                  '${submitResponse.data['data'][0]['msg']}');
            else
              showNotification(title_timekeeping_fail, 'Chấm công thất bại');
          }
        await prefs.remove(TIMEKEEPING_DATA_KEY);
        await prefs.remove(EVENTS_KEY);
      }
    }
  }

  bool _searchResult(List predictedDataLocal, List predictedDataServer) {
    double minDist = 999;
    double currDist = 0.0;
    bool match = false;

    currDist = _euclideanDistance(predictedDataLocal, predictedDataServer);
    if (currDist <= 1.0 && currDist < minDist) {
      minDist = currDist;
      match = true;
    }
    return match;
  }

  double _euclideanDistance(List e1, List e2) {
    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  @override
  Widget build(BuildContext context) {
    final cover = context.watch<BaseResponse>().data == null
        ? ''
        : context.watch<BaseResponse>().data['data'][0]['cover']['v'] == null
            ? ''
            : '$avatarUrlAPIs${context.watch<BaseResponse>().data['data'][0]['cover']['v']?.toString()}';
    final coverFileName = context.watch<BaseResponse>().data == null
        ? ''
        : context
            .watch<BaseResponse>()
            .data['data'][0]['cover']['v']
            .toString()
            .replaceAll('/', '-');
    debugPrint('build main view');
    return Scaffold(
      body: context.watch<BaseResponse>().data == null
          ? LoadingWidget()
          : Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: Utils.resizeWidthUtil(context, 750),
                            height: Utils.resizeHeightUtil(
                                context, 375 - heightScale),
                            child: context
                                        .watch<BaseResponse>()
                                        .data['data'][0]['cover']['v']
                                        .toString()
                                        .isEmpty ||
                                    cover.isEmpty
                                ? Image.asset(img_cover, fit: BoxFit.cover)
                                : Image(
                                    image: NetworkToFileImage(
                                      url: cover,
                                      file: Utils()
                                          .fileFromDocsDir(coverFileName),
                                    ),
                                    fit: BoxFit.cover,
                                  )),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: MediaQuery.of(context).size.width,
                          color: Colors.transparent,
                          margin: EdgeInsets.only(
                              top: Utils.resizeHeightUtil(
                                  context, 300 - heightScale)),
                          child: Center(
                            child: _userTaskBar(context.watch<BaseResponse>()),
                          ),
                        )
                      ],
                    ),
                    Expanded(
                        child: Stack(
                      children: [
                        Container(child: _bodyContent()),
                        _iconZoomInOut()
                      ],
                    ))
                  ],
                ),
                if (!_isRotated)
                  GestureDetector(
                    onTap: _rotate,
                    child: Container(
                      color: txt_grey_color_v1.withOpacity(0.7),
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  ),
                if (!_isRotated) _timekeepingTypeButton()
              ],
            ),
      bottomNavigationBar: BottomAppBarCustom(
          color: txt_grey_color_v1,
          backgroundColor: Colors.white,
          selectedColor: only_color,
          iconSize: Utils.resizeHeightUtil(context, 50),
          centerItemText: _menu.length > 0 ? _menu[2][0] : '',
          notchedShape: CircularNotchedRectangle(),
          initCallback: (state) {
            _state = state;
          },
          onTabSelected: (_selectedTab) {
            _tabController.animateTo(_selectedTab);
          },
          items: _bottomItems),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: Utils.resizeWidthUtil(context, 120),
        height: Utils.resizeWidthUtil(context, 120),
        child: RotationTransition(
            turns: Tween(begin: 0.0, end: 1.0).animate(_controllerRotate),
            child: FloatingActionButton(
                backgroundColor: only_color,
                onPressed: () async {
                  if (isQRCode == 'true' || isNFC == 'true') {
                    _rotate();
                  } else {
                    if (await checkPermission()) {
                      if (!await location.serviceEnabled()) {
                        location.requestService();
                      } else {
                        if (isTensorFlow == 'true')
                          return;
                        /*Navigator.pushNamed(context, Routers.checkLocationV2,
                              arguments:
                                  CameraArgument(deviceBrand: _deviceBrand, timekeepingType: TimekeepingType.Face));*/
                        else
                          Navigator.pushNamed(context, Routers.timeKeeping,
                              arguments:
                                  CameraArgument(deviceBrand: _deviceBrand));
                      }
                    }
                  }
                },
                child: _menu.length > 0
                    ? ImageIcon(
                        NetworkToFileImage(
                          url:
                              '$avatarUrl${(_menu.where((value) => value[3] == 'True').toList())[0][1]}',
                          file: Utils().fileFromDocsDir(
                              'main-menu${((_menu.where((value) => value[3] != 'False').toList())[0][1]).split('/').last}'),
                        ),
                        size: Utils.resizeWidthUtil(context, 80))
                    : Container())),
      ),
    );
  }

  Widget _timekeepingTypeButton() => Positioned(
        bottom: Utils.resizeHeightUtil(context, 20),
        left: Utils.resizeWidthUtil(context, 0),
        right: 0,
        child: Container(
          width: double.infinity,
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              isNFC == 'true'
                  ? _timekeepingTypeItemButton(
                      bottom: 0,
                      title: 'NFC',
                      icon: Icons.wifi,
                      onTap: () async {
                        int result = await Utils.platform
                            .invokeMethod('checkNFCPermission');
                        if (result == 0)
                          showMessageDialogIOS(context,
                              description:
                                  Utils.getString(context, txt_nfc_available));
                        else if (result == 1)
                          showMessageDialogIOS(context,
                              description:
                                  Utils.getString(context, txt_nfc_disable),
                              buttonText: txt_go_settings, onPress: () async {
                            Navigator.pop(context);
                            await Utils.platform
                                .invokeMethod('startNFCSettings');
                          });
                        else if (await checkPermission()) {
                          if (!await location.serviceEnabled()) {
                            location.requestService();
                          } else {
                            // context.read<LocationBloc>().add(LocationEvent.getCurrentPosition);
                            Navigator.pushNamed(context, Routers.nfcScan);
                          }
                        }
                      })
                  : Container(),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 40),
              ),
              _timekeepingTypeItemButton(
                  bottom: 60,
                  title: 'Khuôn mặt',
                  icon: Icons.face,
                  onTap: () async {
                    if (await checkPermission()) {
                      if (!await location.serviceEnabled()) {
                        location.requestService();
                      } else {
                        if (isTensorFlow == 'true')
                          return;
                        /*Navigator.pushNamed(context, Routers.checkLocationV2,
                              arguments:
                                  CameraArgument(deviceBrand: _deviceBrand, timekeepingType: TimekeepingType.Face));*/
                        else
                          Navigator.pushNamed(context, Routers.timeKeeping,
                              arguments:
                                  CameraArgument(deviceBrand: _deviceBrand));
                      }
                    }
                  }),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 40),
              ),
              isQRCode == 'true'
                  ? _timekeepingTypeItemButton(
                      bottom: 0,
                      title: 'QR code',
                      icon: Icons.center_focus_strong,
                      onTap: () async {
                        if (await checkPermission()) {
                          if (!await location.serviceEnabled()) {
                            location.requestService();
                          } else {
                            // context.read<LocationBloc>().add(LocationEvent.getCurrentPosition);
                            Navigator.pushNamed(context, Routers.qrCodeScan,
                                arguments:
                                    CameraArgument(deviceBrand: _deviceBrand));
                          }
                        }
                      })
                  : Container(),
              /*SizedBox(
                width: Utils.resizeWidthUtil(context, 20),
              ),
              _timekeepingTypeItemButton(
                  bottom: 0,
                  title: 'Mở tủ',
                  icon: Icons.lock_open,
                  onTap: () async {
                    if (await checkPermission()) {
                      if (!await location.serviceEnabled()) {
                        location.requestService();
                      } else {
                        context
                            .bloc<LocationBloc>()
                            .add(LocationEvent.getCurrentPosition);
                        Navigator.pushNamed(context, Router.openDrawer, arguments:
                        CameraArgument(deviceBrand: _deviceBrand));
                      }
                    }
                  })*/
            ],
          ),
        ),
      );

  Widget _timekeepingTypeItemButton(
          {double bottom, IconData icon, String title, Function onTap}) =>
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          ScaleTransition(
            scale: _animation,
            alignment: FractionalOffset.center,
            child: Container(
              margin:
                  EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
              child: TKText(
                title,
                tkFont: TKFont.SFProDisplaySemiBold,
                style: TextStyle(
                  fontSize: 13,
                  color: white_color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ScaleTransition(
            scale: _animation,
            alignment: FractionalOffset.center,
            child: GestureDetector(
              child: Container(
                  width: Utils.resizeWidthUtil(context, 80),
                  height: Utils.resizeWidthUtil(context, 80),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: only_color),
                  child: InkWell(
                    onTap: () {
                      _rotate();
                      onTap();
                    },
                    child: Center(
                      child: Icon(
                        icon,
                        color: white_color,
                      ),
                    ),
                  )),
            ),
          ),
          SizedBox(
            height: Utils.resizeHeightUtil(context, bottom),
          )
        ],
      );

  Widget _bodyContent() {
    WorkingReportMain workingReportMain =
        context.watch<WorkingReportService>().workingReportMain;
    checkStatusTimekeeping(workingReportMain);
    return _menu.length > 0
        ? Container(
            /*height: MediaQuery.of(context).size.height -
                (Utils.resizeHeightUtil(context, 450)),*/
            child: DefaultTabController(
                length:
                    _menu.where((value) => value[3] == 'False').toList().length,
                initialIndex: 0,
                child: Container(
                  margin:
                      EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: heightScale == 0.0
                            ? MediaQuery.of(context).size.width * 0.9
                            : double.infinity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () async {
                                if (status == 0) {
                                  if (await checkPermission()) {
                                    if (!await location.serviceEnabled()) {
                                      location.requestService();
                                    } else {
                                      Navigator.pushNamed(
                                          context, Routers.timeKeeping,
                                          arguments: CameraArgument(
                                              deviceBrand: _deviceBrand));
                                    }
                                  }
                                } else {
                                  var listData = _menu
                                      .where((value) => value[3] == 'False')
                                      .toList();
                                  Navigator.pushNamed(
                                      context, Routers.timeKeepingData,
                                      arguments: {
                                        'data': listData[0][2][0][3],
                                        'title': Utils.getString(context,
                                            txt_data_timekeeping_success)
                                      });
                                }
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: MediaQuery.of(context).size.width *
                                    (heightScale == 0.0 ? 0.43 : 0.15),
                                height: Utils.resizeHeightUtil(
                                    context, heightScale == 0.0 ? 120 : 50),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [
                                    gradient_color_main_start,
                                    gradient_color_main_end
                                  ]),
                                  borderRadius: heightScale == 0.0
                                      ? BorderRadius.circular(
                                          Utils.resizeWidthUtil(context, 18))
                                      : BorderRadius.only(
                                          topRight: Radius.circular(
                                              Utils.resizeWidthUtil(
                                                  context, 50)),
                                          bottomRight: Radius.circular(
                                              Utils.resizeWidthUtil(
                                                  context, 50))),
                                ),
                                child: heightScale == 0.0
                                    ? _timeBarView(
                                        status == 0
                                            ? Utils.getString(
                                                context, txt_do_not_timekeeping)
                                            : status == 1
                                                ? Utils.getString(context,
                                                    txt_out_timekeeping)
                                                : Utils.getString(context,
                                                    txt_in_timekeeping),
                                        ic_main_today,
                                        date: status == 2
                                            ? workingReportMain.startTimeKeeping
                                            : status == 1
                                                ? workingReportMain
                                                    .endTimeKeeping
                                                : '')
                                    : LayoutBuilder(
                                        builder: (context, constraint) {
                                        if (status == 0)
                                          return Icon(
                                            Icons.warning,
                                            size: constraint.biggest.height - 8,
                                            color: Colors.yellowAccent,
                                          );
                                        else
                                          return Center(
                                            child: TKText(
                                              status == 2
                                                  ? DateFormat.Hm().format(DateFormat(
                                                          'MM/dd/yyyy hh:mm:ss a')
                                                      .parse(workingReportMain
                                                          .startTimeKeeping))
                                                  : status == 1
                                                      ? DateFormat.Hm().format(DateFormat(
                                                              'MM/dd/yyyy hh:mm:ss a')
                                                          .parse(workingReportMain
                                                              .startTimeKeeping))
                                                      : '',
                                              tkFont: TKFont.SFProDisplayMedium,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize:
                                                      Utils.resizeWidthUtil(
                                                          context, 24)),
                                            ),
                                          );
                                      }),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, Routers.dashBoard,
                                    arguments: Utils.getString(
                                        context, txt_individual_work_sheet));
                              },
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: MediaQuery.of(context).size.width *
                                    (heightScale == 0.0 ? 0.43 : 0.15),
                                height: Utils.resizeHeightUtil(
                                    context, heightScale == 0.0 ? 120 : 50),
                                decoration: BoxDecoration(
                                  borderRadius: heightScale == 0.0
                                      ? BorderRadius.circular(
                                          Utils.resizeWidthUtil(context, 18))
                                      : BorderRadius.only(
                                          topLeft: Radius.circular(
                                              Utils.resizeWidthUtil(
                                                  context, 50)),
                                          bottomLeft: Radius.circular(
                                              Utils.resizeWidthUtil(
                                                  context, 50))),
                                  gradient: LinearGradient(colors: [
                                    gradient_color_main_start,
                                    gradient_color_main_end
                                  ]),
                                ),
                                child: heightScale == 0.0
                                    ? _timeBarView(
                                        Utils.getString(
                                            context, txt_working_day_main),
                                        ic_working_day,
                                        warning: workingReportMain == null
                                            ? Utils.getString(
                                                context, txt_waiting)
                                            : '',
                                        info: workingReportMain != null
                                            ? '${num.parse(workingReportMain.salaryWorkDay).toStringAsFixed(1)}/${workingReportMain.totalWorkday}'
                                            : '')
                                    : Center(
                                        child: TKText(
                                          workingReportMain != null
                                              ? '${num.parse(workingReportMain.salaryWorkDay).toStringAsFixed(1)}/${workingReportMain.totalWorkday}'
                                              : '',
                                          tkFont: TKFont.SFProDisplayMedium,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: Utils.resizeWidthUtil(
                                                  context, 24)),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            child: TabBarView(
                              //physics: NeverScrollableScrollPhysics(),
                              controller: _tabController,
                              children: <Widget>[
                                ..._menu
                                    .where((value) => value[3] == 'False')
                                    .toList()
                                    .map((menu) {
                                  switch (menu[0]) {
                                    case 'Trang chủ':
                                      return _itemTabBarView(menu[2]);
                                    case 'Trò chuyện':
                                      return _chatManagerScreen();
                                    default:
                                      return _comingSoonScreen();
                                  }
                                })
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                )),
          )
        : Center(
            child: CupertinoActivityIndicator(),
          );
  }

  Widget _userInfo(BaseResponse user) {
    var avatar = user.data['data'][0]['avatar']['v'].toString() != ''
        ? '$avatarUrl${user.data['data'][0]['avatar']['v'].toString()}'
        : avatarDefaultUrl;
    var avatarFileName =
        '${user.data['data'][0]['avatar']['v'].toString().replaceAll('/', '-')}';
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
        Expanded(
          child: Container(
            margin: EdgeInsets.only(
                left: Utils.resizeWidthUtil(context, 20), right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(
                  (user != null)
                      ? "${Utils.getString(context, txt_main_view_hello)} "
                          "${user.data['data'][0]['full_name']['r'].toString()}!"
                      : Utils.getString(context, txt_waiting),
                  overflow: TextOverflow.ellipsis,
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
          ),
        )
      ],
    );
  }

  Widget _itemTabBarView(items) {
    return Container(
      child: GridView.builder(
        padding: EdgeInsets.only(
            top: ((heightEstimate - height).abs() * (_crossAxisCount - 1)) / 2,
            bottom: Utils.resizeHeightUtil(context, 100)),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            childAspectRatio: (height / heightEstimate) > 1 ? 1.32 : 1.25,
            crossAxisSpacing: Utils.resizeHeightUtil(context, 20),
            mainAxisSpacing: Utils.resizeHeightUtil(context, 20)),
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                    top: Utils.resizeHeightUtil(context, 10),
                    right: Utils.resizeHeightUtil(context, 10)),
                child: _itemDashboard(items[index][0], items[index][1],
                    items[index][4], items[index][2], items[index][3]),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: totalRequest != 0 && items[index][2] == '451'
                    ? Container(
                        padding:
                            EdgeInsets.all(Utils.resizeHeightUtil(context, 10)),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: txt_fail_color),
                        child: Center(
                          child: TKText(
                            checkTotalRequest(totalRequest),
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                                color: white_color,
                                fontSize: Utils.resizeWidthUtil(context, 20)),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _itemDashboard(String name, String icon, List<dynamic> subMenu,
      String id, String tbName) {
    return InkWell(
        borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 18)),
        onTap: () async {
          switch (id) {
            case '450':
              Navigator.pushNamed(context, Routers.requestData,
                  arguments: {'title': name, 'data': subMenu[0]}).then((value) {
                _getTotalRequestWaiting();
              });
              break;
            case '440':
              Navigator.pushNamed(context, Routers.dashBoard, arguments: name);
              break;
            case '442':
              Navigator.pushNamed(context, Routers.timeOff, arguments: name);
              break;
            case '437':
              Navigator.pushNamed(context, Routers.timeKeepingData,
                  arguments: {'title': name, 'data': tbName});
              break;
            case '443':
              Navigator.pushNamed(context, Routers.workOutsideRegister,
                  arguments: name);
              break;
            case '439':
              Navigator.pushNamed(context, Routers.latchingWork,
                  arguments: name);
              break;
            case '449':
              Navigator.pushNamed(context, Routers.clockInOutRegister,
                  arguments: name);
              break;
            case '451':
              Navigator.pushNamed(context, Routers.requestOwnerData,
                  arguments: {'title': name, 'data': subMenu[0]}).then((value) {
                _getTotalRequestWaiting();
              });
              break;
            case '460':
              Navigator.pushNamed(context, Routers.overtimeRegister,
                  arguments: name);
              break;
            case '463':
              Navigator.pushNamed(context, Routers.menuOwner,
                  arguments: {'title': name, 'data': subMenu[0]});
              break;
            case '505':
              Navigator.pushNamed(context, Routers.salaryView, arguments: name);
              break;
            case '553':
              Navigator.pushNamed(context, Routers.trackingView,
                  arguments: name);
              break;
            default:
              Navigator.pushNamed(context, Routers.comingSoon,
                  arguments: {'title': name, 'data': subMenu[0]});
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(Utils.resizeWidthUtil(context, 18)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6.0,
                spreadRadius: 0.0,
                offset: Offset(
                  0,
                  0,
                ),
              )
            ],
          ),
          child: Column(children: [
            SizedBox(
              height: Utils.resizeHeightUtil(context, 20),
            ),
            Expanded(
              flex: 1,
              child: Container(
                  width: Utils.resizeWidthUtil(context, 52),
                  height: Utils.resizeHeightUtil(context, 52),
                  child: Image(
                      image: NetworkToFileImage(
                    url: '$avatarUrl$icon',
                    file: Utils()
                        .fileFromDocsDir('sub-menu${icon.split('/').last}'),
                  ))),
            ),
            Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Utils.resizeWidthUtil(context, 20)),
                    child: TKText(
                      name,
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 26)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
          ]),
        ));
  }

  Widget _userTaskBar(BaseResponse user) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.pushNamed(context, Routers.profile).then((value) {
          if (value) _getUser(context);
        });
      },
      child: Container(
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
              child: _userInfo(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBarView(String name, String image,
      {String warning = '', String date = '', String info = ''}) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            spreadRadius: 0.0,
            offset: Offset(
              0,
              3,
            ),
          )
        ],
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: Utils.resizeWidthUtil(context, 20),
          ),
          Image.asset(image,
              width: Utils.resizeWidthUtil(context, 80),
              height: Utils.resizeHeightUtil(context, 72)),
          SizedBox(
            width: Utils.resizeWidthUtil(context, 20),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TKText(
                  name,
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: Utils.resizeWidthUtil(context, 28)),
                ),
                warning != '' || info != '' || date != ''
                    ? TKText(
                        warning != ''
                            ? warning
                            : info != ''
                                ? info
                                : date != ''
                                    ? DateFormat.Hm().format(
                                        DateFormat('MM/dd/yyyy hh:mm:ss a')
                                            .parse(date))
                                    : '',
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: Utils.resizeWidthUtil(context, 28)),
                      )
                    : Container()
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _comingSoonScreen() {
    return Container(
      child: Center(
        child: TKText(
          Utils.getString(context, txt_coming_soon),
          tkFont: TKFont.SFProDisplaySemiBold,
          style: TextStyle(
              color: txt_grey_color_v3,
              fontSize: Utils.resizeWidthUtil(context, 32)),
        ),
      ),
    );
  }

  Widget _chatManagerScreen() {
    return Container(
      child: GridView.builder(
        padding: EdgeInsets.only(
            top: ((heightEstimate - height).abs() * (_crossAxisCount - 1)) / 2,
            bottom: Utils.resizeHeightUtil(context, 100)),
        itemCount: listMenuChat.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _crossAxisCount,
            childAspectRatio: (height / heightEstimate) > 1 ? 1.32 : 1.25,
            crossAxisSpacing: Utils.resizeHeightUtil(context, 20),
            mainAxisSpacing: Utils.resizeHeightUtil(context, 20)),
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(
                    top: Utils.resizeHeightUtil(context, 10),
                    right: Utils.resizeHeightUtil(context, 10)),
                child: _itemChatManager(listMenuChat[index]['Name'],
                    listMenuChat[index]['Icon'], listMenuChat[index]['ID']),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _itemChatManager(String name, IconData icon, String id) {
    return InkWell(
        borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 18)),
        onTap: () async {
          switch (id) {
            case '1':
              Navigator.pushNamed(context, Routers.chatView,
                      arguments: {'title': "Trò chuyện"})
                  /*.then((value) {
                _getTotalTaskNew();
                _getTotalTaskLate();
                _getTotalTaskComplete();
                _getTotalTaskProposalToCancel();
                _getTotalNotification();
              })*/
                  ;
              break;
            /*case '2':
              Navigator.pushNamed(
                  context, Routers.notificationUiView, arguments: {
                'title': "Thông báo",
                'icon': Icons.notifications
              }).then((value) {
                _getTotalTaskNew();
                _getTotalTaskLate();
                _getTotalTaskComplete();
                _getTotalTaskProposalToCancel();
                _getTotalNotification();
              });
              break;*/
            case '3':
              Navigator.pushNamed(context, Routers.newsView,
                  arguments: {'title': 'Bản tin'});
              break;
            default:
              Navigator.pushNamed(context, Routers.comingSoon,
                  arguments: {'title': name});
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(Utils.resizeWidthUtil(context, 18)),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6.0,
                spreadRadius: 0.0,
                offset: Offset(
                  0,
                  0,
                ),
              )
            ],
          ),
          child: Column(children: [
            SizedBox(
              height: Utils.resizeHeightUtil(context, 20),
            ),
            Expanded(
              flex: 1,
              child: Container(
                  width: Utils.resizeWidthUtil(context, 52),
                  height: Utils.resizeHeightUtil(context, 52),
                  child: Icon(icon, color: only_color)),
            ),
            Expanded(
                flex: 2,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: Utils.resizeWidthUtil(context, 20)),
                    child: TKText(
                      name,
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 26)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
          ]),
        ));
  }

  /*
    Status: distinguish in/out
    - 1: start time and end time has value => user latching successful.
    - 2: start time has value and end time hasn't value
    - 3: start time hasn't value and end time has value
    - 0: start time hasn't value and end time hasn't value => user didn't timekeeping yet,
   */
  void checkStatusTimekeeping(WorkingReportMain workingReportMain) {
    int _status = 0;
    if (workingReportMain != null) {
      if (workingReportMain.startTimeKeeping != '' ||
          workingReportMain.endTimeKeeping != '') {
        if (workingReportMain.startTimeKeeping != '' &&
            workingReportMain.endTimeKeeping != '') {
          if (workingReportMain.startTimeKeeping ==
              workingReportMain.endTimeKeeping) {
            _status = 2;
          } else {
            _status = 1;
          }
        } else if (workingReportMain.startTimeKeeping != '') {
          _status = 2;
        } else {
          _status = 3;
        }
      } else {
        _status = 0;
      }
    } else {
      _status = 0;
    }
    setState(() {
      status = _status;
    });
  }

  void calculatedPadding() {
    double _crossAxisSpacing = Utils.resizeHeightUtil(context, 15),
        _aspectRatio = 1.25;
    double screenWidth = MediaQuery.of(context).size.width;
    double width = (screenWidth - ((_crossAxisCount - 1) * _crossAxisSpacing)) /
        _crossAxisCount;
    setState(() {
      height = width / _aspectRatio;
      heightEstimate = Utils.resizeHeightUtil(context, 620) / 3;
    });
  }

  Widget _iconZoomInOut() {
    return Positioned(
      right: 10,
      bottom: 10,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (heightScale == 0.0)
              heightScale = 200.0;
            else
              heightScale = 0.0;
          });
        },
        child: Container(
          width: 50,
          height: 50,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 0.5),
              ),
            ],
          ),
          child: Icon(
            heightScale == 0.0
                ? Icons.open_in_full_rounded
                : Icons.close_fullscreen_rounded,
            color: txt_grey_color_v1,
          ),
        ),
      ),
    );
  }
}
