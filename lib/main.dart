import 'dart:convert';
import 'dart:io';
import 'package:background_fetch/background_fetch.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as service;
import 'package:gsot_timekeeping/my_app.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'core/components/local_notification.dart';
import 'core/models/wifi_info.dart';
import 'core/router/router.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/timekeeping_backgroud_service.dart';
import 'core/util/utils.dart';
import 'package:firebase_core/firebase_core.dart';

Directory appDocsDir;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  appDocsDir = await getApplicationDocumentsDirectory();
  var launchScreen = await Utils().checkIsFirstTime();
  runApp(DevicePreview(
      enabled: false, builder: (context) => MyApp(launchScreen: launchScreen ?? Routers.onBoarding)));
  await service.SystemChrome.setPreferredOrientations(
      [service.DeviceOrientation.portraitUp]);
  WifiInfo wifiInfo = await Utils().getNetworkInformation();
  String imei = await ImeiPlugin.getImei();
  await SecureStorage().saveClientID(imei);
  SecureStorage()
      .saveCustomString(SecureStorage.WIFI_INFO, json.encode(wifiInfo) ?? '');
  Provider.debugCheckInvalidValueType = null;
  initLocalNotification();
  initBackgroundFetch();
  BackgroundFetch.registerHeadlessTask(onBackgroundTimekeeping);
}
