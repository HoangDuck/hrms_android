// import 'dart:io';
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
//
// class FireBaseNotifications {
//   FirebaseMessaging fireBaseMessaging;
//   final void Function(dynamic data) onMessageCallback;
//   final void Function(dynamic data) onLaunchCallback;
//   final void Function(dynamic data) onResumeCallback;
//
//   FireBaseNotifications(
//       {@required this.onMessageCallback,
//       @required this.onLaunchCallback,
//       @required this.onResumeCallback});
//
//   void setUpFireBase(BuildContext context) {
//     fireBaseMessaging = FirebaseMessaging();
//     fireBaseCloudMessagingListeners(context);
//   }
//
//   void fireBaseCloudMessagingListeners(context) {
//     if (Platform.isIOS) iOSPermission();
//     fireBaseMessaging.configure(
//       onMessage: (Map<String, dynamic> message) async {
//         if (onMessageCallback != null && message != null) {
//           onMessageCallback(message);
//         }
//       },
//       onBackgroundMessage: myBackgroundMessageHandler,
//       onLaunch: (Map<String, dynamic> message) async {
//         if (onLaunchCallback != null && message != null) {
//           onLaunchCallback(message);
//         }
//       },
//       onResume: (Map<String, dynamic> message) async {
//         if (onResumeCallback != null && message != null) {
//           onResumeCallback(message);
//         }
//       },
//     );
//     fireBaseMessaging.requestNotificationPermissions(
//         const IosNotificationSettings(
//             sound: true, badge: true, alert: true, provisional: true));
//     fireBaseMessaging.onIosSettingsRegistered
//         .listen((IosNotificationSettings settings) {});
//     fireBaseMessaging.subscribeToTopic("matchscore");
//   }
//
//   void iOSPermission() {
//     fireBaseMessaging.requestNotificationPermissions(
//         IosNotificationSettings(sound: true, badge: true, alert: true));
//     fireBaseMessaging.onIosSettingsRegistered
//         .listen((IosNotificationSettings settings) {});
//   }
// }
//
// Future<dynamic> myBackgroundMessageHandler(message) {
//   if (message.containsKey('data')) {
//     // Handle data message
//   }
//
//   if (message.containsKey('notification')) {
//     // Handle notification message
//   }
//   return message;
// }
