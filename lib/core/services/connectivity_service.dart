import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/enums/connectivity_status.dart';
import 'package:gsot_timekeeping/core/models/wifi_info.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/services/timekeeping_backgroud_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityStatus status = ConnectivityStatus.Offline;

  ConnectivityStatus get statusValue => status;

  ConnectivityService() {
    Connectivity().checkConnectivity().then((result) {
      _connectivityEvent(result);
    });
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      _connectivityEvent(result);
    });
  }

  _connectivityEvent(ConnectivityResult result) async {
    status = _getStatusFromResult(result);
    debugPrint('Connectivity status: $status');
    if (result != ConnectivityResult.none) {
      WifiInfo wifiInfo = await Utils().getNetworkInformation();
      SecureStorage()
          .saveCustomString(SecureStorage.WIFI_INFO, json.encode(wifiInfo));
      // continue timekeeping iOS only

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String timekeepingData = prefs.getString(TIMEKEEPING_DATA_KEY);
        if (timekeepingData != null) {
          var submitResponse = await BaseViewModel().callApis(
              jsonDecode(timekeepingData), timeKeepingUrl, method_post,
              isNeedAuthenticated: true, shouldSkipAuth: false);
          if (submitResponse.status.code == 200) {
            print('Im here to time keeping');
            showMessageDialogIOS(Utils().getContext(),
                title: submitResponse.data['data'][0]['isSuccees'] == 0
                    ? title_timekeeping_fail
                    : title_timekeeping_success,
                description: submitResponse.data['data'][0]['msg']);
          } else {
            showMessageDialogIOS(Utils().getContext(),
                title: title_timekeeping_fail, description: 'Timekeeping fail');
          }
          await prefs.remove(TIMEKEEPING_DATA_KEY);
          await prefs.remove(EVENTS_KEY);
        }
      }
    }
  }

  ConnectivityStatus _getStatusFromResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.mobile:
        return ConnectivityStatus.Cellular;
      case ConnectivityResult.wifi:
        return ConnectivityStatus.WiFi;
      case ConnectivityResult.none:
        return ConnectivityStatus.Offline;
      default:
        return ConnectivityStatus.Offline;
    }
  }
}
