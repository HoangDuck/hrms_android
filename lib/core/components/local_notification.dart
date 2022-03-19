import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/my_app.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:shared_preferences/shared_preferences.dart';

const NOTIFICATION_TITLE_KEY = "notification_title_key";
const NOTIFICATION_CONTENT_KEY = "notification_content_key";
const NOTIFICATION_PAYLOAD_KEY = "notification_payload_key";

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

initLocalNotification() {
  var initializationSettingsAndroid =
      new AndroidInitializationSettings('app_icon_local_notification');
  var initializationSettingsIOS = IOSInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: _onSelectNotification);
}

Future _onSelectNotification(String value) async {
  showTimekeepingDialog();
}

showTimekeepingDialog({bool isTimekeeping = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String title = prefs.getString(NOTIFICATION_TITLE_KEY);
  String content = prefs.getString(NOTIFICATION_CONTENT_KEY);
  String dataString = prefs.get(NOTIFICATION_PAYLOAD_KEY);
  if(dataString != null && !isTimekeeping) {
    var data = jsonDecode(dataString);
    await prefs.remove(NOTIFICATION_PAYLOAD_KEY);
    Navigator.pushNamed(
      navigatorKey.currentContext,
      Routers.chatEmpView,
      arguments: data
    );
  }
  if (title != null && content != null) {
      showMessageDialogIOS(Utils().getContext(),
          title: title, description: content);
    await prefs.remove(NOTIFICATION_TITLE_KEY);
    await prefs.remove(NOTIFICATION_CONTENT_KEY);
  }
}

Future<void> showNotification(String title, String content, {String type = '', dynamic data}) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name', channelDescription: 'your channel description',
      importance: Importance.max, priority: Priority.high, ticker: 'ticker');
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if(type == '') {
    prefs.setString(NOTIFICATION_TITLE_KEY, title);
    prefs.setString(NOTIFICATION_CONTENT_KEY, content);
  } else prefs.setString(NOTIFICATION_PAYLOAD_KEY, data);
  await flutterLocalNotificationsPlugin.show(
      0, title, content ?? null, platformChannelSpecifics);
}

Future<void> showDailyRemindTimekeeping(
    int id, Time time, String title, String content) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'repeatDailyAtTime channel id',
      'repeatDailyAtTime channel name',
      channelDescription: 'repeatDailyAtTime description');
  var iOSPlatformChannelSpecifics = IOSNotificationDetails();
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.showDailyAtTime(
      id, title, content, time, platformChannelSpecifics);
}

Future<void> scheduleNotification(
    int id, DateTime time, String title, String content) async {
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your other channel id',
      'your other channel name',
      channelDescription: 'your other channel description');
  var iOSPlatformChannelSpecifics =
      IOSNotificationDetails(sound: 'slow_spring_board.aiff');
  var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.schedule(
      id, title, content, time, platformChannelSpecifics);
}
