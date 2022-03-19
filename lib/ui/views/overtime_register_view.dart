import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/time_off_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';

class OvertimeRegisterView extends StatefulWidget {
  @override
  _OvertimeRegisterViewState createState() => _OvertimeRegisterViewState();
}

class _OvertimeRegisterViewState extends State<OvertimeRegisterView> {
  ScrollController _scrollController = ScrollController();
  TextEditingController _dateTimeStartController = TextEditingController();
  TextEditingController _dateTimeEndController = TextEditingController();
  DateTime _startWorkingTime;
  DateTime _endWorkingTime;
  dynamic _genRow = {};
  TextEditingController _reasonController = TextEditingController();
  TextEditingController _timeController = TextEditingController();
  TextEditingController _placeNameController = TextEditingController();
  final SpeechToText speech = SpeechToText();
  String lastWords = "";
  String lastError = "";
  String lastStatus = "";
  String _currentLocaleId = "vi_VN";
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  bool isOpenModal = false;
  bool _enableRegisterButton = false;
  bool _forceErrorReason = false;
  bool _forceErrorTime = false;
  BaseResponse _user;
  String _showErrorText = '';

  @override
  void initState() {
    super.initState();
    initSpeechState();
    _dateTimeStartController.value = TextEditingValue(
        text: dateTimeFormat.format(DateTime.now()),
        selection: _dateTimeStartController.selection);
    _dateTimeEndController.value = TextEditingValue(
        text: dateTimeFormat.format(DateTime.now()),
        selection: _dateTimeEndController.selection);
    _startWorkingTime = DateTime.now();
    _endWorkingTime = DateTime.now();
    _timeController.text =
        Utils.countTotalTime(context, _startWorkingTime, _endWorkingTime);

    _timeController.addListener(_onTextFieldChange);
    _reasonController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    if (!mounted) {
      _dateTimeStartController.dispose();
      _dateTimeEndController.dispose();
      _reasonController.dispose();
      _timeController.dispose();
      _placeNameController.dispose();
    }
    super.dispose();
  }

  _onTextFieldChange() {
    if (!_dateTimeStartController.text.contains(_dateTimeEndController.text) &&
        _timeController.text.isNotEmpty &&
        _reasonController.text.isNotEmpty) {
      _enableRegisterButton = true;
    } else
      _enableRegisterButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {'TbName': 'tb_hrms_congtacngoai_overtime'},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _genRow = Utils.getListGenRow(response.data['data'], 'add');
      });
  }

  Future<void> initSpeechState() async {
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
    _reasonController.text = '';
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
        _reasonController.text = result.recognizedWords;
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

  Future<dynamic> checkDouble(BaseViewModel model) async {
    var response = await model.callApis({
      "ID": -100,
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, checkDoubleOvertime, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _showErrorText =
            response.data['data'][0]['result']['r'].replaceAll(';', '.');
      });
      return response.data['data'][0]['result']['v'];
    } else
      return null;
  }

  void submitData(BaseViewModel model) async {
    showLoadingDialog(context);
    var check = await checkDouble(model);
    if (check == "") {
      Navigator.pop(context);
      var encryptData = await Utils.encrypt("tb_hrms_congtacngoai_overtime");
      Navigator.pushNamed(context, Routers.map, arguments: {
        'data': {
          'tbname': encryptData,
          "employee_id": _user.data['data'][0]['ID'],
          "from_time": DateFormat("MM/dd/yyyy HH:mm:ss")
              .format(_startWorkingTime),
          "to_time": DateFormat("MM/dd/yyyy HH:mm:ss")
              .format(_endWorkingTime),
          'break_time_employee': _timeController.text,
          "reason": _reasonController.text,
          //"place_name": _placeNameController.text,
          "status": 5
        },
        'from_time': DateFormat("HH:mm dd/MM/yyyy")
            .format(_startWorkingTime),
        'to_time': DateFormat("HH:mm dd/MM/yyyy")
            .format(_endWorkingTime),
        'gen_row_define': _genRow,
        'type': 'overtime',
        'childTableName': 'tb_hrms_congtacngoai_overtime_place'
      });
    } else if (check == null) {
      Navigator.pop(context);
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    } else {
      Navigator.pop(context);
      showMessageDialogIOS(context, description: check.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    _user = context.watch<BaseResponse>();
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getGenRowDefine(model);
        checkDouble(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () {
          Utils.closeKeyboard(context);
          Navigator.pop(context, 0);
        }, () {
          Utils.closeKeyboard(context);
        }, 'Đăng ký tăng ca', null),
        body: _genRow.length == 0
            ? Container(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Utils.resizeWidthUtil(context, 30)),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _userManual(),
                          _buildTimeOff(model),
                          _buildContentText(
                              _genRow['break_time_employee']['name'],
                              textInputType: TextInputType.number,
                              controller: _timeController),
                          /*_buildContentText(_genRow['place_name']['name'],
                              textCapitalization: TextCapitalization.sentences,
                              controller: _placeNameController),*/
                          boxTitle(context, _genRow['reason']['name']),
                          _buildReason(),
                          _buildRegisterButton(model),
                        ],
                      ),
                    ),
                  ),
                  if (MediaQuery.of(context).viewInsets.bottom > 0)
                    Positioned.fill(
                        child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => Utils.closeKeyboard(context),
                    ))
                ],
              ),
      ),
    );
  }

  Widget _userManual() {
    return Container(
        padding: EdgeInsets.fromLTRB(20, 10, 5, 0),
        margin: EdgeInsets.only(
            top: Utils.resizeHeightUtil(context, 20),
            bottom: Utils.resizeHeightUtil(context, 20)),
        decoration: BoxDecoration(
          color: _showErrorText == ''
              ? blue_light.withOpacity(0.3)
              : txt_fail_color.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: TKText(
                  _showErrorText.replaceAll('mới Đã', 'mới\nĐã'),
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 26),
                      color: _showErrorText == ''
                          ? gradient_start_color.withOpacity(0.8)
                          : txt_fail_color),
                ),
              ),
            ),
            Expanded(flex: 1, child: Image.asset(work_outside))
          ],
        ));
  }

  Widget _buildTimeOff(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, Utils.getString(context, txt_time_register)),
        Row(
          children: <Widget>[
            _iconTime(),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 35),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  DateTimePickerCustomModify(
                      controller: _dateTimeStartController,
                      initialDate:
                          dateTimeFormat.parse(_dateTimeStartController.text),
                      initialTime: TimeOfDay(
                          hour: _startWorkingTime.hour,
                          minute: _startWorkingTime.minute),
                      firstDate: DateTime(DateTime.now().year,
                          DateTime.now().month - 1, DateTime.now().day),
                      callBack: (date, time) async {
                        if (date == null || time == null) return;
                        _startWorkingTime = DateTime(date.year, date.month,
                            date.day, time.hour, time.minute);
                        _dateTimeStartController.text =
                            dateTimeFormat.format(_startWorkingTime);
                        if (_startWorkingTime.isAfter(_endWorkingTime)) {
                          var _dailyEndWorkingTime = DateTime(
                              _startWorkingTime.year,
                              _startWorkingTime.month,
                              _startWorkingTime.day,
                              17,
                              30);
                          var _newEndWorkingTime;
                          if (_startWorkingTime
                              .isBefore(_dailyEndWorkingTime)) {
                            _newEndWorkingTime = DateTime(
                                _startWorkingTime.year,
                                _startWorkingTime.month,
                                _startWorkingTime.day,
                                17,
                                30);
                          } else {
                            _newEndWorkingTime = DateTime(
                                _startWorkingTime.year,
                                _startWorkingTime.month,
                                _startWorkingTime.day,
                                _startWorkingTime.hour,
                                _startWorkingTime.minute);
                          }
                          _endWorkingTime = _newEndWorkingTime;
                          _dateTimeEndController.text =
                              dateTimeFormat.format(_newEndWorkingTime);
                        }
                        _timeController.text = Utils.countTotalTime(
                            context, _startWorkingTime, _endWorkingTime);
                        checkDouble(model);
                      }),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                  DateTimePickerCustomModify(
                      controller: _dateTimeEndController,
                      initialDate:
                          dateTimeFormat.parse(_dateTimeEndController.text),
                      firstDate: DateTime(_startWorkingTime.year,
                          _startWorkingTime.month, _startWorkingTime.day),
                      initialTime: TimeOfDay(
                          hour: _endWorkingTime.hour,
                          minute: _endWorkingTime.minute),
                      callBack: (date, time) async {
                        if (DateTime(date.year, date.month, date.day, time.hour,
                                time.minute)
                            .isBefore(_startWorkingTime)) {
                          showMessageDialog(context,
                              description: Utils.getString(
                                  context, txt_error_is_less_than_time),
                              onPress: () => Navigator.pop(context));
                          return;
                        }
                        _endWorkingTime = DateTime(date.year, date.month,
                            date.day, time.hour, time.minute);
                        _dateTimeEndController.text =
                            dateTimeFormat.format(_endWorkingTime);
                        _timeController.text = Utils.countTotalTime(
                            context, _startWorkingTime, _endWorkingTime);
                        checkDouble(model);
                      }),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _iconTime() {
    return Container(
      height: Utils.resizeHeightUtil(context, 140) + 4,
      child: Column(
        children: <Widget>[
          _iconCircleTIme(),
          Expanded(
            child: Container(
              width: 2,
              color: button_color,
            ),
          ),
          _iconCircleTIme()
        ],
      ),
    );
  }

  Widget _iconCircleTIme() {
    return Container(
      width: Utils.resizeWidthUtil(context, 23),
      height: Utils.resizeWidthUtil(context, 23),
      decoration: BoxDecoration(
          border: Border.all(
              color: button_color, width: Utils.resizeWidthUtil(context, 5)),
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 11.4))),
    );
  }

  Widget _buildContentText(String title,
      {bool isEnable = true,
      bool isExpand = false,
      TextEditingController controller,
      TextInputType textInputType = TextInputType.text,
      TextCapitalization textCapitalization = TextCapitalization.none,
      Function onPress,
      String icon}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (onPress != null) {
          onPress();
        } else {
          Utils.closeKeyboard(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            boxTitle(context, title),
            TextFieldCustom(
              controller: controller,
              enable: isEnable,
              imgLeadIcon: icon,
              textInputType: textInputType,
              textCapitalization: textCapitalization,
              expandMultiLine: isExpand,
              forceError: title == _genRow['break_time_employee']['name']
                  ? _forceErrorTime
                  : false,
              onChange: (changeValue) {
                setState(() {
                  if (title == _genRow['break_time_employee']['name'])
                    _forceErrorTime = controller.text.trimRight().isEmpty;
                });
              },
              onSubmit: (value) {

              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReason() {
    return TextFieldCustom(
        onSpeechPress: () {
          isOpenModal = true;
          startListening();
          Future.delayed(Duration(seconds: 5), () {
            isOpenModal = false;
            Navigator.pop(context);
          });
        },
        onSubmit: (value) {

        },
        controller: _reasonController,
        expandMultiLine: true,
        textCapitalization: TextCapitalization.sentences,
        hintText: 'Nhập lý do',
        forceError: _forceErrorReason,
        onChange: (changeValue) {
          setState(() {
            _forceErrorReason = _reasonController.text.trimRight().isEmpty;
          });
        });
  }

  Widget _buildRegisterButton(BaseViewModel model) {
    return Container(
      margin: EdgeInsets.only(
          left: 4,
          right: 4,
          top: Utils.resizeHeightUtil(context, 50),
          bottom: Utils.resizeHeightUtil(context, 90)),
      child: TKButton(Utils.getString(context, txt_continue),
          enable: _enableRegisterButton,
          width: double.infinity,
          onPress: () => submitData(model)),
    );
  }
}
