import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:background_fetch/background_fetch.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gsot_timekeeping/core/components/local_notification.dart';
import 'package:gsot_timekeeping/core/models/wifi_info.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';

const EVENTS_KEY = "fetch_events";
const TIMEKEEPING_DATA_KEY = "timekeeping_data";
const PREDICTED_DATA = "predicted_data";
const delay_time_timekeeping = 10000;
const delay_time_period = 60000;//300000; //5min
const title_timekeeping_success = 'CHẤM CÔNG THÀNH CÔNG';
const title_timekeeping_fail = 'CHẤM CÔNG THẤT BẠI';
const title_tracking = 'SMARTHRMS TRACKING';
const title_alarm_before_in = 'SẮP ĐẾN GIỜ CHẤM CÔNG VÀO ';
const title_alarm_before_out = 'SẮP ĐẾN GIỜ CHẤM CÔNG RA CA';
const String background_timekeeping_task_id =
    "com.transistorsoft.timekeepingTask";
const String background_periodic_request_task_id =
    "com.transistorsoft.periodicRequestTask";

initBackgroundFetch() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(EVENTS_KEY);
  BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 15,
            forceAlarmManager: false,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE,
          ),
          onBackgroundTimekeeping)
      .then((int status) {
    debugPrint('[BackgroundFetch] configure success: $status');
  }).catchError((e) {
    debugPrint('[BackgroundFetch] configure ERROR: $e');
  });
}

addTimeKeepingBackgroundFetch({bool init = false}) {
  if (!init) BackgroundFetch.finish(background_timekeeping_task_id);
  BackgroundFetch.scheduleTask(TaskConfig(
          taskId: background_timekeeping_task_id,
          delay: delay_time_timekeeping,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true))
      .then((value) {
    debugPrint('Schedule timekeeping: $value');
  }).catchError((e) {
    debugPrint('Schedule timekeeping ERROR: $e');
  });
}

addPeriodicBackgroundFetch({bool init = false}) {
  if (!init) BackgroundFetch.finish(background_periodic_request_task_id);
  BackgroundFetch.scheduleTask(TaskConfig(
          taskId: background_periodic_request_task_id,
          delay: delay_time_period,
          periodic: true,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true))
      .then((value) {
    debugPrint('Schedule Periodic: $value');
  }).catchError((e) {
    debugPrint('Schedule Periodic ERROR: $e');
  });
}

void onBackgroundTimekeeping(String taskId) async {
  debugPrint('running on background service: ${DateTime.now()}');
  print(taskId);
  if (taskId.contains("com.transistorsoft.timekeepingTask")) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String timekeepingData = prefs.getString(TIMEKEEPING_DATA_KEY);
    if (timekeepingData == null) {
      _stopBackgroundFetch(prefs);
      return;
    }
    var connectivityResult = await (Connectivity().checkConnectivity());
    DateTime nowTime = DateTime.now();
    List<String> events = [];
    String json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      events = jsonDecode(json).cast<String>();
    }
    if (connectivityResult != ConnectivityResult.none && events.length > 0) {
      if (events.length > 0) {
        var _user = await SecureStorage().userProfile;
        if(_user.data['data'][0]['Timekeeping_IsTFFaceAuto']['v'] == 'True')
          _runTensorFlowDetect(prefs, timekeepingData, events);
        else _runMicrosoftDetect(prefs, timekeepingData, events);
      }
      _stopBackgroundFetch(prefs);
    } else {
      if (events.length > 0) {
        var oldValue = events.first.split('~').last;
        var newValue = int.parse(oldValue) + delay_time_timekeeping;
        events.insert(0, "$nowTime~$newValue");
      } else {
        events.insert(0, "$nowTime~$delay_time_timekeeping");
      }
      prefs.setString(EVENTS_KEY, jsonEncode(events));
      addTimeKeepingBackgroundFetch();
    }
  } else if (taskId.contains("com.transistorsoft.periodicRequestTask")) {
    // showNotification(title_tracking, 'TRACKING RUN');
    /*var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult != ConnectivityResult.none) {
      var response = await BaseViewModel().callApis(
          {}, checkFollowLocationUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      if (response.status.code == 200) {
        if (response.data['data'][0]['result']['v'] == '1') {
          Position userLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          var stringWifiInfo =
              await SecureStorage().getCustomString(SecureStorage.WIFI_INFO);
          WifiInfo wifiInfo = WifiInfo.fromJson(json.decode(stringWifiInfo));
          var _user = await SecureStorage().userProfile;
          var data = {
            "tbname": 'jyHwAy3K3iEsGZTNQxW1YYLEJN73qMD/6/nH8njbOclHGDsB1gma+Q==', //tb_hrms_chamcong_timesheet_tracking
            "employee_id": _user.data['data'][0]['ID'],
            "org_id": _user.data['data'][0]['org_id']['v'],
            "role_id": _user.data['data'][0]['role_id']['v'],
            "company_id": _user.data['data'][0]['company_id']['v'],
            "lat": userLocation.latitude,
            "long": userLocation.longitude,
            'location_address': '',
            "time_check": DateTime.now().toString(),
            "network_wan": wifiInfo.wan,
            "network_lan": wifiInfo.lan,
            "wifiSSID": wifiInfo.wifiSSID,
            "wifiBSSID": wifiInfo.wifiBSSID
          };
          //device_type: 1 android, 2 ios, 3 #
          if (Platform.isAndroid)
            data = {
              ...data,
              "device_id": wifiInfo.androidId,
              "device_name": wifiInfo.androidName,
              "device_type": 1
            };
          else
            data = {
              ...data,
              "device_id": wifiInfo.identifierForVendor,
              "device_name": wifiInfo.nameForVendor,
              "device_type": 2
            };
          try {
            await BaseViewModel().callApis(data, addDataUrl, method_post,
                shouldSkipAuth: false, isNeedAuthenticated: true);
          } catch (e) {
            print(e);
          }
          addPeriodicBackgroundFetch();
        } else {
          BackgroundFetch.finish(background_periodic_request_task_id);
          return;
        }
      } else
        addPeriodicBackgroundFetch();
    } else
      addPeriodicBackgroundFetch();*/
  } else
    BackgroundFetch.stop();
}

_stopBackgroundFetch(SharedPreferences prefs) async {
  await prefs.remove(TIMEKEEPING_DATA_KEY);
  await prefs.remove(EVENTS_KEY);
  await prefs.remove(PREDICTED_DATA);
  BackgroundFetch.finish(background_periodic_request_task_id);
  //BackgroundFetch.stop();
}

_runTensorFlowDetect(SharedPreferences prefs, String timekeepingData, List<String> events) async {
  List faceData = jsonDecode(prefs.getString(PREDICTED_DATA));
  var response = await BaseViewModel().callApis(
      {}, getFaceTrainUrl, method_post,
      shouldSkipAuth: false, isNeedAuthenticated: true);
  var dataSubmit = jsonDecode(timekeepingData);
  if(response.status.code == 200) {
    if (response.data['data'][0]['TF_FaceID']['v'] != '') {
      bool result = _searchResult(faceData, jsonDecode(response.data['data'][0]['TF_FaceID']['v']));
      if(result) {
        int totalTime = int.parse(events.first.split('~').last);
        var startTime = DateTime.parse(events.last.split('~').first);
        DateTime realTime = await NTP.now();
        int realTotalTime = realTime.difference(startTime).inMilliseconds;
        if (((totalTime - realTotalTime).abs() - 30000) <=
            delay_time_timekeeping.toInt()) {
          for(int i = 0; i < dataSubmit.length; i ++) {
            var submitResponse = await BaseViewModel().callApis({
              ...{"isOffline": true},
              ...{'error': false},
              ...dataSubmit[i]
            }, timeKeepingUrl, method_post,
                isNeedAuthenticated: true, shouldSkipAuth: false);
            if (submitResponse.status.code == 200) {
              showNotification(
                  submitResponse.data['data'][0]['isSuccees'] == 0
                      ? title_timekeeping_fail
                      : title_timekeeping_success,
                  '${submitResponse.data['data'][0]['msg']}');
            } else {
              showNotification(title_timekeeping_fail, 'Chấm công thất bại');
            }
          }
        } else runFail(dataSubmit, prefs);
      } else runFail(dataSubmit, prefs);
    } else runFail(dataSubmit, prefs);
  } else runFail(dataSubmit, prefs);
}

_runMicrosoftDetect(SharedPreferences prefs, String timekeepingData, List<String> events) async {
  int totalTime = int.parse(events.first.split('~').last);
  var startTime = DateTime.parse(events.last.split('~').first);
  DateTime realTime = await NTP.now();
  int realTotalTime = realTime.difference(startTime).inMilliseconds;
  var dataSubmit = jsonDecode(timekeepingData);
  if (((totalTime - realTotalTime).abs() - 30000) <=
      delay_time_timekeeping.toInt()) {
    for(int i = 0; i < dataSubmit.length; i ++) {
      var submitResponse = await BaseViewModel().callApis({
        ...{"isOffline": true},
        ...{'error': false},
        ...dataSubmit[i]
      }, timeKeepingUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (submitResponse.status.code == 200) {
        showNotification(
            submitResponse.data['data'][0]['isSuccees'] == 0
                ? title_timekeeping_fail
                : title_timekeeping_success,
            '${submitResponse.data['data'][0]['msg']}');
      } else {
        showNotification(title_timekeeping_fail, 'Chấm công thất bại');
      }
    }
  } else {
    for(int i = 0; i < dataSubmit; i ++) {
      var submitResponse = await BaseViewModel().callApis({
        ...{"isOffline": true},
        ...{"error": true},
        ...dataSubmit[i]
      }, timeKeepingUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (submitResponse.status.code == 200)
        showNotification(
            title_timekeeping_fail, '${submitResponse.data['data'][0]['msg']}');
      else
        showNotification(title_timekeeping_fail, 'Chấm công thất bại');
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

void runFail(var dataSubmit, SharedPreferences prefs) async {
  for (int i = 0; i < dataSubmit.length; i ++) {
    var submitResponse = await BaseViewModel().callApis({
      ...{"isOffline": true},
      ...{"error": true},
      ...dataSubmit[i]
    }, timeKeepingUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (submitResponse.status.code == 200)
      showNotification(
          title_timekeeping_fail, '${submitResponse.data['data'][0]['msg']}');
    else
      showNotification(title_timekeeping_fail, 'Chấm công thất bại');
  }
  _stopBackgroundFetch(prefs);
}
