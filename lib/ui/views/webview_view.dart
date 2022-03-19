import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class WebViewView extends StatefulWidget {
  @override
  _WebViewViewState createState() => _WebViewViewState();
}

class _WebViewViewState extends State<WebViewView> {
  String url = '';

  final flutterWebViewPlugin = FlutterWebviewPlugin();

  final Set<JavascriptChannel> jsChannels = [
    JavascriptChannel(
        name: 'Print',
        onMessageReceived: (JavascriptMessage message) {
          print(message.message);
        }),
  ].toSet();

  @override
  void initState() {
    super.initState();
    getUrl();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: only_color));
  }

  @override
  void dispose() {
    flutterWebViewPlugin.dispose();
    super.dispose();
  }

  getUrl() async {
    String data = await SecureStorage().companyInfo;
    setState(() {
      url = jsonDecode(data)['urlWebView']['v'];
    });
  }

  //https://gpghrux.gsotgroup.vn:8885/
  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: url != '' ? WebviewScaffold(
          url: url,
          javascriptChannels: jsChannels,
          mediaPlaybackRequiresUserGesture: false,
          withZoom: true,
          withLocalStorage: true,
          geolocationEnabled: true,
          hidden: true,
          initialChild: Container(
            color: Colors.white,
            child: Center(
              child: TKText(
                'Vui lòng đợi...',
                style: TextStyle(color: Colors.grey, fontSize: 20),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    flutterWebViewPlugin.goBack();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.autorenew),
                  onPressed: () {
                    flutterWebViewPlugin.reload();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    flutterWebViewPlugin.goForward();
                  },
                )
              ],
            ),
          ),
        ) : Scaffold(
          body: Container(
            color: Colors.white,
            height: double.infinity,
            width: double.infinity,
            child: Center(
              child: TKText(
                'Vui lòng đợi...',
                style: TextStyle(color: Colors.grey, fontSize: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
