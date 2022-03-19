import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class NotificationWidget extends StatefulWidget {
  final dynamic notificationData;

  const NotificationWidget({Key key, this.notificationData}) : super(key: key);

  @override
  _NotificationWidgetState createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  dynamic _currentData;

  bool _forceErrorReason = false;

  TextEditingController _reasonErrorController = TextEditingController();

  final SpeechToText speech = SpeechToText();

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  bool isOpenModal = false;

  StateSetter _stateModal;

  BaseViewModel model;

  @override
  void initState() {
    super.initState();
    model = BaseViewModel();
    _initSpeechState();
    _getNotification(widget.notificationData);
  }

  Future<void> _initSpeechState() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      var systemLocale = await speech.systemLocale();
      debugPrint(systemLocale.localeId);
    }

    if (!mounted) return;
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received error status: $error, listening: ${speech.isListening}");
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    print(
        "Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }

  void startListening() {
    _reasonErrorController.text = '';
    lastError = "";
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 5),
        localeId: _currentLocaleId,
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        partialResults: true);
    showModalBottomSheet(
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.4,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            border: Border.all(style: BorderStyle.none),
          ),
          child: StatefulBuilder(builder: (context, setModalState) {
            return modalBottomSheetVoice(context, setModalState);
          })),
    );
  }

  void stopListening() {
    setState(() {
      speech.stop();
      level = 0.0;
    });
  }

  void cancelListening() {
    setState(() {
      speech.cancel();
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    debugPrint(result.recognizedWords);
    setState(() {
      if (isOpenModal) {
        _reasonErrorController.text = result.recognizedWords;
        if (_stateModal != null) {
          _stateModal(() {
            _forceErrorReason = _reasonErrorController.text.trimRight().isEmpty;
          });
        }
      }
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  _getNotification(dynamic data) {
    _currentData = Platform.isAndroid ? data.data : data;
  }

  Future<void> approveApplicationCall(
      BaseViewModel model, String api, dynamic data) async {
    showLoadingDialog(context);
    var response = await model.callApis(data, api, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      Navigator.pop(context);
      showMessageDialogIOS(context,
          description: response.data['data'][0]['result']);
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
    }
  }

  _action(BaseViewModel model, int type, String api, dynamic data) {
    switch (type) {
      case 0:
        approveApplicationCall(model, api, data);
        break;
      case 1:
        _showBottomSheet(api, data);
        break;
      case 3:
        print('Khác');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) return Container();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        padding: EdgeInsets.only(
          top: Utils.resizeHeightUtil(context, 100),
          bottom: Utils.resizeHeightUtil(context, 100),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Center(
            child: Container(
              //height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.8,
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
              child: Stack(
                children: <Widget>[
                  Container(
                      padding: EdgeInsets.only(
                          left: 12,
                          right: 12,
                          top: Utils.resizeHeightUtil(context, 20),
                          bottom: jsonDecode(_currentData['buttons']).length > 0
                              ? (Utils.resizeHeightUtil(context, 69) + 10)
                              : Utils.resizeHeightUtil(context, 20)),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            TKText('Thông báo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 32),
                                    color: txt_grey_color_v1),
                                tkFont: TKFont.SFProDisplaySemiBold),
                            SizedBox(
                              height: Utils.resizeHeightUtil(context, 20),
                            ),
                            TKText(
                              _currentData['title'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: Utils.resizeWidthUtil(context, 34),
                                  color: only_color),
                              tkFont: TKFont.SFProDisplayBold,
                            ),
                            SizedBox(height: 8),
                            if(_currentData['body'] != '')
                              TKText(
                                _currentData['body'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: Utils.resizeWidthUtil(context, 32),
                                    color: txt_grey_color_v2),
                                tkFont: TKFont.SFProDisplayMedium,
                              ),
                            SizedBox(height: 8),
                            if (_currentData['html'].toString() != '')
                              Html(
                                data: _currentData['html'],
                              ),
                            if (jsonDecode(_currentData['buttons']).length > 0)
                              SizedBox(
                                  height: double.parse((Utils.resizeHeightUtil(
                                              context, 69) *
                                          jsonDecode(_currentData['buttons'])
                                              .length)
                                      .toString()))
                          ],
                        ),
                      )),
                  if (jsonDecode(_currentData['buttons']).length > 0)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.only(top: 10),
                          child: _getButton(model, _stateModal)),
                    ),
                  Positioned(
                    right: 10,
                    top: Utils.resizeHeightUtil(context, 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Icon(Icons.clear, color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getButton(BaseViewModel model, StateSetter setModalState) {
    List<Widget> list = List<Widget>();
    (jsonDecode(_currentData['buttons'])).forEach((itemButton) {
      list.add(Container(
        margin: EdgeInsets.only(
            top: Utils.resizeHeightUtil(context, 5),
            bottom: Utils.resizeHeightUtil(context, 5),
            left: Utils.resizeHeightUtil(context, 20),
            right: Utils.resizeHeightUtil(context, 20)),
        child: TKButton(
          itemButton['title'].toString(),
          backgroundColor: Color(int.parse(itemButton['color'])),
          width: double.infinity,
          onPress: () {
            _action(model, itemButton['type'], itemButton['api'],
                itemButton['data']);
          },
        ),
      ));
    });
    return SingleChildScrollView(
      child: Container(
          padding:
          EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
          child: Column(children: list)),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: Utils.resizeHeightUtil(context, 15)),
      child: TKText(
        title,
        tkFont: TKFont.SFProDisplayRegular,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 32),
            color: txt_grey_color_v3),
      ),
    );
  }

  _showBottomSheet(String api, dynamic data) {
    showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => SingleChildScrollView(
              child: Container(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  decoration: BoxDecoration(
                    border: Border.all(style: BorderStyle.none),
                  ),
                  child: StatefulBuilder(builder: (context, setModalState) {
                    _stateModal = setModalState;
                    return Container(
                      padding: EdgeInsets.only(
                          left: Utils.resizeWidthUtil(context, 30),
                          right: Utils.resizeWidthUtil(context, 30),
                          top: Utils.resizeHeightUtil(context, 10),
                          bottom: Utils.resizeHeightUtil(context, 20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              Utils.resizeWidthUtil(context, 30.0)),
                          topRight: Radius.circular(
                              Utils.resizeWidthUtil(context, 30.0)),
                        ),
                      ),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            color: white_color,
                            height: 10,
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Container(
                                height: 5,
                                width: Utils.resizeWidthUtil(context, 100),
                                decoration: BoxDecoration(
                                    color: txt_grey_color_v1.withOpacity(0.3),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8.0))),
                              ),
                            ),
                          ),
                          _bottomSheetReason(setModalState, model, api, data)
                        ],
                      ),
                    );
                  })),
            ));
  }

  Widget _bottomSheetReason(StateSetter setModalState, BaseViewModel model,
          String api, dynamic data) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(
          height: Utils.resizeHeightUtil(context, 20),
        ),
        _buildTitle(Utils.getString(context, txt_reason_title)),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 10),
        ),
        TextFieldCustom(
            onSpeechPress: () {
              isOpenModal = true;
              startListening();
              Future.delayed(Duration(seconds: 5), () {
                isOpenModal = false;
                Navigator.pop(context);
              });
            },
            controller: _reasonErrorController,
            expandMultiLine: true,
            forceError: _forceErrorReason,
            onChange: (changeValue) {
              setModalState(() {
                _forceErrorReason =
                    _reasonErrorController.text.trimRight().isEmpty;
              });
            }),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 20),
        ),
        TKButton(
          Utils.getString(context, txt_btn_send),
          width: double.infinity,
          onPress: () async {
            if (_reasonErrorController.text.isEmpty)
              setModalState(() {
                _forceErrorReason = true;
              });
            else {
              Utils.closeKeyboard(context);
              Navigator.pop(context);
              data['nodeStepDetail'] = _reasonErrorController.text;
              await approveApplicationCall(model, api, data);
            }
          },
        )
      ]);
}
