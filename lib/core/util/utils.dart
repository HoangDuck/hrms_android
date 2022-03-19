import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:connectivity/connectivity.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_ip/flutter_ip.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip/get_ip.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gsot_timekeeping/core/enums/connectivity_status.dart';
import 'package:gsot_timekeeping/core/models/wifi_info.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/translation/app_translations.dart';
import 'package:gsot_timekeeping/main.dart';
import 'package:gsot_timekeeping/my_app.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:new_version/new_version.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart' as wfInfo;

import '../../main.dart';
import '../../ui/constants/app_images.dart';

class Utils {
  static Pattern emailPattern = r'^[a-zA-Z0-9]';
  static const platform = const MethodChannel('flutter.native/helper');
  static LatLng latLngCompany = LatLng(10.8026214, 106.6471017);

  static bool isInDebugMode() {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  Future<WifiInfo> getNetworkInformation() async {
    Connectivity _connectivity = Connectivity();
    ConnectivityResult result;
    String wifiName, wifiBSSID, external, internal, identifierForVendor, nameForVendor, androidId, androidName;
    try {
      result = await _connectivity.checkConnectivity();
      if (result != null) {
        if (result == ConnectivityResult.wifi) {

          wifiBSSID = await wfInfo.WifiInfo().getWifiBSSID();
          wifiName = await wfInfo.WifiInfo().getWifiName();

          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
          if (Platform.isIOS) {
            internal = await FlutterIp.internalIP;
            external = await FlutterIp.externalIP;
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            identifierForVendor = iosInfo.identifierForVendor;
            nameForVendor = iosInfo.name;
          } else {
            internal = await GetIp.ipAddress;
            http.Response response = await http.get(Uri.parse('http://api.ipify.org/'));
            external = response.body;
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            androidId = androidInfo.androidId;
            androidName = androidInfo.model;
          }

          return WifiInfo(
              identifierForVendor: identifierForVendor,
              nameForVendor: nameForVendor,
              androidId: androidId,
              androidName: androidName,
              wan: external,
              lan: internal,
              wifiSSID: wifiName,
              wifiBSSID: wifiBSSID);
        }
      }
    } on PlatformException catch (e) {
      print(e.toString());
    }
    return null;
  }

  static bool checkNetwork(BuildContext context) {
    var connectionStatus = context.read<ConnectivityStatus>();
    if (connectionStatus == ConnectivityStatus.Offline) {
      return false;
    }
    return true;
  }

  static void closeKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static double resizeWidthSpecialUtil(double width, double value) {
    var screenDesignWidth = 750;
    return (width * value) / screenDesignWidth;
  }

  static double resizeWidthUtil(BuildContext context, double value) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenDesignWidth = 750;
    return (screenWidth * value) / screenDesignWidth;
  }

  static double resizeHeightUtil(BuildContext context, double value) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenDesignHeight = 1344;
    return (screenHeight * value) / screenDesignHeight;
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  static String getString(BuildContext context, String value) => AppTranslations.of(context).text(value);

  static String getTitle(List<dynamic> list, String key) {
    bool allowNull = true;
    return list
        .where((i) {
      if (i['Name']['v'] == key && i['AllowNull']['v'] == 'False') allowNull = false;
      return i['Name']['v'] == key;
    })
        .toList()[0]['VnName']['v']
        .toString() +
        (!allowNull ? '*' : '') ??
        '';
  }

  static dynamic getTitleGenRowOnly(List<dynamic> list) {
    dynamic _list = {};
    list.forEach((item) {
      _list = {
        ..._list,
        ...{
          '${item['Name']['v']}': {
            'key': item['Name']['v'],
            'name': item['VnName']['v'],
          }
        }
      };
    });
    return _list;
  }

  static dynamic getListGenRow(List<dynamic> list, String type) {
    dynamic _list = {};
    list.forEach((item) {
      _list = {
        ..._list,
        ...{
          '${item['Name']['v']}': {
            'key': item['Name']['v'],
            'name': item['VnName']['v'] + (item['AllowNull']['v'] == 'False' ? '*' : ''),
            'allowNull': item['AllowNull']['v'] == 'True' || item['AllowNull']['v'] == '' ? true : false,
            'allowEdit': type.contains('add')
                ? (item['AllowEdit']['v'] == 'True' || item['AllowEdit']['v'] == '' ? true : false)
                : ((item['AllowEdit']['v'] == 'True' || item['AllowEdit']['v'] == '') &&
                (item['AllowChange']['v'] == 'True' || item['AllowChange']['v'] == '')
                ? true
                : false),
            'dataType': item['DataType']['v'],
            'show': item['ColumnWidth']['v'],
            'status': item['Status']['v']
          }
        }
      };
    });
    return _list;
  }

  /*static Future<double> getDistance1() async {
    double lat1 = 10.8004665;
    double lng1 = 106.7145278;
    double lat2 = 11.005136646042109;
    double lng2 = 106.69641081243753;
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lng2 - lng1) * p)) / 2;
    double cc = 2 * math.asin(math.sqrt(a));
    double distance = cc * 6371 * 1000;
    double distancia = await Geolocator().distanceBetween(lat1, lng1, lat2, lng2);
    print(distancia);
    return a;
  }*/

  static double getDistance(double lat1, double long1, double lat2, double long2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + c(lat1 * p) * c(lat2 * p) * (1 - c((long2 - long1) * p)) / 2;

    double cc = 2 * math.asin(math.sqrt(a));
    double distance = cc * 6371 * 1000;
    return distance;
  }

  static String countTotalTime(BuildContext context, DateTime timeStart, DateTime timeEnd) {
    return round((timeEnd.difference(timeStart).inMinutes / 60), 2)
        .toString()
        .replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
  }

  static double round(double val, int places) {
    double mod = pow(10.0, places);
    return ((val * mod).round().toDouble() / mod);
  }

  static String convertBase64(Uint8List imageByte) => base64.encode(imageByte);

  String convertDoubleToTime(double value) {
    if (value < 0) return 'Invalid Value';
    int flooredValue = value.floor();
    double decimalValue = value - flooredValue;
    String hourValue = getHourString(flooredValue);
    String minuteString = getMinuteString(decimalValue);
    return '$hourValue:$minuteString';
  }

  String convertTimeToDouble(String time) {
    if (time != '')
      return (int.parse(time.split(":")[0]) + int.parse(time.split(":")[1]) / 60.0)
          .toString()
          .replaceAll(RegExp(r"([.]*0)(?!.*\d)"), "");
    else
      return '';
  }

  String getMinuteString(double decimalValue) {
    return '${(decimalValue * 60).toInt()}'.padLeft(2, '0');
  }

  String getHourString(int flooredValue) {
    return '${flooredValue % 24}'.padLeft(2, '0');
  }

  static dynamic encryptHMAC(String data, String secCode) {
    var keyInBytes = utf8.encode(secCode);
    var payloadInBytes = utf8.encode(data);
    var md5Hash = Hmac(md5, keyInBytes);
    return md5Hash.convert(payloadInBytes).toString();
  }

  static String convertJson(dynamic params, String urlReqId, String reqTime, {String userName = "noname"}) {
    var jsonString =
    jsonEncode(params).replaceAll(" ", "").replaceAll("\r", "").replaceAll("\n", "").replaceAll("\"", "'");
    return "$jsonString#$userName#$urlReqId#$reqTime";
  }

  static dynamic encode(dynamic value) {
//Todo Implement decode features
    return value;
  }

  static dynamic decode(dynamic value) {
//Todo Implement decode features
    return value;
  }

  static Future encrypt(String value) async {
    var result = await platform.invokeMethod('encryptTripleDes', {"key": "smart@things!2020@HRMS***", "string": value});
    return result.toString().replaceAll("\n", "");
  }

  static Future decrypt(String value) async {
    var result = await platform.invokeMethod('decryptTripleDes', {"key": "smart@things!2020@HRMS***", "string": value});
    return result.toString().replaceAll("\n", "");
  }

  static Future<Uint8List> readFileByte(String filePath) async {
    Directory tempDir = await getTemporaryDirectory();
    var tempPath = tempDir.path;
    Uri myUri = Uri.parse(filePath);
    File file = new File.fromUri(myUri);
    file = await FlutterExifRotation.rotateImage(path: file.path);
    Uint8List bytes = file.readAsBytesSync();
    img.Image imageTemp = img.decodeImage(bytes);
    var splitPath = filePath.split("/");
    File myCompressedFile = new File(tempPath + 'resize-${splitPath[splitPath.length - 1]}')
      ..writeAsBytesSync(img.encodeJpg(imageTemp, quality: 70));
    var bytesResponse = myCompressedFile.readAsBytesSync();
    final dir = Directory(tempPath + 'resize-${splitPath[splitPath.length - 1]}');
    dir.deleteSync(recursive: true);
    return bytesResponse;
  }

  Future<String> checkIsFirstTime() async {
    await [Permission.location, Permission.camera, Permission.microphone, Permission.storage].request();
    var apiToken = await SecureStorage().apiToken;
    var userProfile = await SecureStorage().userProfile;
    var onBoarding = await SecureStorage().isFirstTime();
    var baseUrl = await SecureStorage().companyInfo;
    var isWebView = await SecureStorage().isWebView;
    if (apiToken != null && apiToken.isNotEmpty && userProfile != null) {
      return Routers.main;
    } else if(isWebView == 'true') {
      return Routers.webView;
    } else if (onBoarding != true && baseUrl != null) {
      return Routers.login;
    } else if (onBoarding != true && baseUrl == null) {
      return Routers.chooseCompany;
    }
    return Routers.onBoarding;
  }

  BuildContext getContext() {
    return navigatorKey.currentState.overlay.context;
  }

  File fileFromDocsDir(String filename) {
    String pathName = path.join(appDocsDir.path, filename);
    return File(pathName);
  }

  String convertDate(DateTime date) {
    String newDate = DateFormat.E().format(date);
    switch (newDate) {
      case 'Mon':
        newDate = 'T2';
        break;
      case 'Tue':
        newDate = 'T3';
        break;
      case 'Wed':
        newDate = 'T4';
        break;
      case 'Thu':
        newDate = 'T5';
        break;
      case 'Fri':
        newDate = 'T6';
        break;
      case 'Sat':
        newDate = 'T7';
        break;
      default:
        newDate = 'CN';
    }
    return newDate;
  }

  /*void checkAppUpdate(context) async {
    final newVersion = NewVersion(androidId: txt_app_id, iOSId: 'gsot.timekeeping', context: context);
    final status = await newVersion.getVersionStatus();
    if (status.canUpdate)
      showMessageDialog(navigatorKey.currentState.overlay.context,
          title: 'Cập nhật phần mềm',
          description:
          'Đã có phiên bản mới ${status.storeVersion}, phiên bản của bạn là ${status.localVersion}, vui lòng cập nhật phần mềm để tiếp tục sử dụng!',
          buttonText: txt_go_update, onPress: () async {
            LaunchReview.launch(androidAppId: txt_app_id, iOSAppId: txt_apple_id);
            SharedPreferences preferences = await SharedPreferences.getInstance();
            await preferences.clear();
            await SecureStorage().deleteAllSS();
            exit(0);
          });
  }*/

  basicStatusCheckVersion(NewVersion newVersion, BuildContext context) {
    newVersion.showAlertIfNecessary(context: context);
  }

  advancedStatusCheckVersion(NewVersion newVersion, BuildContext context) async {
    final status = await newVersion.getVersionStatus();
    if (status != null) {
      debugPrint(status.releaseNotes);
      debugPrint(status.appStoreLink);
      debugPrint(status.localVersion);
      debugPrint(status.storeVersion);
      debugPrint(status.canUpdate.toString());
      newVersion.showUpdateDialog(
        context: context,
        versionStatus: status,
        dialogTitle: 'Custom Title',
        dialogText: 'Custom Text',
      );
    }
  }
  static String getTextReaction(dynamic whichIconUserChoose){
    switch (whichIconUserChoose) {
      case 1:
        return 'Like';
      case 2:
        return 'Love';
      case 3:
        return 'Haha';
      case 4:
        return 'Wow';
      case 5:
        return 'Sad';
      case 6:
        return 'Angry';
      default:
        return 'Like';
    }
  }
  static String getPathIconReactionIndex(dynamic whichIconUserChoose){
    switch (whichIconUserChoose) {
      case 1:
        return ic_like2;
      case 2:
        return ic_heart2;
      case 3:
        return ic_haha2;
      case 4:
        return ic_wow2;
      case 5:
        return ic_sad2;
      case 6:
        return ic_angry2;
      default:
        return ic_thumb_up2;
    }
  }
  static String getPathIconReaction(dynamic iconName){
    switch (iconName) {
      case 'Like':
        return ic_thumb_up;
      case 'Love':
        return ic_heart;
      case 'Haha':
        return ic_smile;
      case 'Wow':
        return ic_wow2;
      case 'Sad':
        return ic_weep;
      case 'Angry':
        return ic_angry2;
      default:
        return ic_thumb_up;
    }
  }
  static String formatNumberReaction(int number){
    int numberFormat=0;
    if(number>=1000 && number<1000000){
      numberFormat=number~/1000;
      return numberFormat.toString() +"K";
    }else if(number>=1000000){
      numberFormat=number~/1000000;
      return numberFormat.toString() +"Tr";
    }
    return number.toString();
  }
}