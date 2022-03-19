import 'dart:io';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/connectivity_service.dart';
import 'package:gsot_timekeeping/core/services/wifi_service.dart';
import 'package:gsot_timekeeping/core/translation/app_translations_delegate.dart';
import 'package:gsot_timekeeping/core/translation/application.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:launch_review/launch_review.dart';
import 'package:new_version/new_version.dart';
import 'package:provider/provider.dart';

import 'core/services/working_report_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();


class MyApp extends StatefulWidget {
  final String launchScreen;

  const MyApp({Key key, this.launchScreen}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  AppTranslationsDelegate _newLocaleDelegate;

  @override
  void initState() {
    super.initState();
    _newLocaleDelegate = AppTranslationsDelegate(newLocale: Locale('vi'));
    application.onLocaleChanged = onLocaleChange;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));
    checkAppUpdate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onLocaleChange(Locale locale) {
    setState(() {
      _newLocaleDelegate = AppTranslationsDelegate(newLocale: locale);
    });
  }

  checkAppUpdate() async {
    final newVersion = NewVersion(
        androidId: txt_app_id, iOSId: 'gsot.timekeeping');
    final status = await newVersion.getVersionStatus();
    if (status.canUpdate)
      showMessageDialog(navigatorKey.currentState.overlay.context,
          title: 'Cập nhật phần mềm',
          description:
              'Đã có phiên bản mới ${status.storeVersion}, phiên bản của bạn là ${status.localVersion}, vui lòng cập nhật phần mềm để tiếp tục sử dụng!',
          buttonText: txt_go_update, onPress: () async {
        LaunchReview.launch(androidAppId: txt_app_id, iOSAppId: txt_apple_id);
        Future.delayed(Duration(seconds: 3), () {
          exit(0);
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    return /*BlocProvider<LocationBloc>(
        create: (BuildContext context) => LocationBloc(),
        child: */MultiProvider(
          providers: [
            ChangeNotifierProvider<WorkingReportService>(
              create: (context) => WorkingReportService(),
            ),
            ChangeNotifierProvider<ConnectivityService>(
                create: (context) => ConnectivityService()),
            ChangeNotifierProvider<BaseResponse>(
                create: (context) => BaseResponse()),
            ChangeNotifierProvider<WifiService>(
                create: (context) => WifiService()),
          ],
          child: MaterialApp(
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
            debugShowCheckedModeBanner: false,
            initialRoute: widget.launchScreen,
            onGenerateRoute: Routers.generateRoute,
            localizationsDelegates: [
              _newLocaleDelegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale("en", ""),
              const Locale("vi", ""),
            ],
            navigatorKey: navigatorKey,
          ),
        )/*)*/;
  }
}
