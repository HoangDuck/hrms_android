import 'dart:convert';
import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
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
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ClockInOutRegisterView extends StatefulWidget {
  final String title;

  ClockInOutRegisterView(this.title);

  @override
  _ClockInOutRegisterViewState createState() => _ClockInOutRegisterViewState();
}

class _ClockInOutRegisterViewState extends State<ClockInOutRegisterView> {
  DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  DateFormat timeFormat = DateFormat('HH:mm');

  int totalValidTimeLate = 0;
  int totalValidTimeEarly = 0;

  //final totalValidTime = 90;

  int _totalTime = 90;

  List<dynamic> listWorkingSession = [];

  List<dynamic> listLateType = [];

  List<dynamic> _genRowList = [];

  TextEditingController _dateController = TextEditingController();

  TextEditingController _timeController = TextEditingController();

  TextEditingController _reasonController = TextEditingController();

  int _sessionSelected = 0;

  int _typeSelected = 0;

  bool _forceErrorTimeOffReason = false;

  String _showErrorText = '';

  String startTimeLimit = '';

  String endTimeLimit = '';

  bool _isLateActive = true;

  bool _isEarlyActive = false;

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  final SpeechToText speech = SpeechToText();

  bool isOpenModal = false;

  ScrollController _scrollController = ScrollController();

  List<int> _listDateEnable = [];

  bool _enableUpdateButton = false;

  @override
  void initState() {
    super.initState();
    initSpeechState();
    _dateController.value = TextEditingValue(
        text: dateFormat.format(DateTime.now()),
        selection: _dateController.selection);
    _timeController.value = TextEditingValue(
        text: timeFormat.format(DateTime.now()),
        selection: _timeController.selection);

    _reasonController.addListener(_onTextFieldChange);
  }

  _onTextFieldChange() {
    if (_reasonController.text.length > 0 && _showErrorText == '') {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
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
    speech.stop();
    setState(() {
      level = 0.0;
    });
  }

  void cancelListening() {
    speech.cancel();
    setState(() {
      level = 0.0;
    });
  }

  void resultListener(SpeechRecognitionResult result) {
    debugPrint(result.recognizedWords);
    setState(() {
      if (isOpenModal) _reasonController.text = result.recognizedWords;
      if (_genRowList
              .where((i) => i['Name']['r'] == 'reason')
              .toList()[0]['AllowNull']['v']
              .toString() !=
          'True') {
        setState(() {
          _forceErrorTimeOffReason = _reasonController.text.trimRight().isEmpty;
        });
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

  @override
  void dispose() {
    if (!mounted) {
      _reasonController.dispose();
      _timeController.dispose();
      _dateController.dispose();
    }
    super.dispose();
  }

  bool checkEmpty() {
    if (_reasonController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      showMessageDialog(context,
          description: Utils.getString(context, txt_text_field_empty),
          onPress: () => Navigator.pop(context));
      return false;
    }
    return true;
  }

  void checkSelected(String selected, String type) {
    switch (type) {
      case 'workingSession':
        for (int i = 0; i < listWorkingSession.length; i++) {
          if (listWorkingSession[i]['nameTimeDefine'] == selected)
            setState(() {
              _sessionSelected = i;
              if (i == 1) {
                if (_typeSelected == 0)
                  _timeController.text = timeFormat.format(timeFormat
                      .parse(listWorkingSession[_sessionSelected]
                          ['startTimeDefine'])
                      .add(Duration(minutes: totalValidTimeLate)));
                else
                  _timeController.text = timeFormat.format(timeFormat
                      .parse(
                          listWorkingSession[_sessionSelected]['endTimeDefine'])
                      .subtract(Duration(minutes: totalValidTimeEarly)));
              } else if (_typeSelected == 0)
                _timeController.text = timeFormat.format(timeFormat
                    .parse(
                        listWorkingSession[_sessionSelected]['startTimeDefine'])
                    .add(Duration(minutes: totalValidTimeLate)));
              else
                _timeController.text = timeFormat.format(timeFormat
                    .parse(
                        listWorkingSession[_sessionSelected]['endTimeDefine'])
                    .subtract(Duration(minutes: totalValidTimeEarly)));
            });
        }
        break;
      case 'lateType':
        for (int i = 0; i < listLateType.length; i++) {
          if (listLateType[i]['type'] == selected)
            setState(() {
              _typeSelected = i;
              if (_sessionSelected == 1) {
                if (i == 0)
                  _timeController.text = timeFormat.format(timeFormat
                      .parse(listWorkingSession[_sessionSelected]
                          ['startTimeDefine'])
                      .add(Duration(minutes: totalValidTimeLate)));
                else
                  _timeController.text = timeFormat.format(timeFormat
                      .parse(
                          listWorkingSession[_sessionSelected]['endTimeDefine'])
                      .subtract(Duration(minutes: totalValidTimeEarly)));
              } else if (i == 0)
                _timeController.text = timeFormat.format(timeFormat
                    .parse(
                        listWorkingSession[_sessionSelected]['startTimeDefine'])
                    .add(Duration(minutes: totalValidTimeLate)));
              else
                _timeController.text = timeFormat.format(timeFormat
                    .parse(
                        listWorkingSession[_sessionSelected]['endTimeDefine'])
                    .subtract(Duration(minutes: totalValidTimeEarly)));
            });
        }
        break;
    }
  }

  void checkValidTime(String time) {
    switch (_typeSelected) {
      case 0:
        _totalTime = timeFormat
            .parse(time)
            .difference(timeFormat
                .parse(listWorkingSession[_sessionSelected]['startTimeDefine']))
            .inMinutes;
        break;
      case 1:
        _totalTime = timeFormat
            .parse(listWorkingSession[_sessionSelected]['endTimeDefine'])
            .difference(timeFormat.parse(time))
            .inMinutes;
    }
    if ((_totalTime > totalValidTimeLate && _typeSelected == 0) ||
        (_totalTime > totalValidTimeEarly && _typeSelected == 1)) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      );
      setState(() {
        _showErrorText = Utils.getString(context, txt_error_is_more_than_time) +
            ' (${_typeSelected == 0 ? totalValidTimeLate : totalValidTimeEarly} phút)';
        _enableUpdateButton = false;
      });
    } else if (_totalTime <= 0) {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      );
      setState(() {
        _totalTime = 0;
        _showErrorText = Utils.getString(context, txt_error_is_more_than_time) +
            ' (${_typeSelected == 0 ? totalValidTimeLate : totalValidTimeEarly} phút)';
        _enableUpdateButton = false;
      });
    } else {
      setState(() {
        _showErrorText = '';
        _enableUpdateButton = true;
      });
    }
  }

  void getTimeAllowLateEarly(BaseViewModel model, String timeID, {Function callback}) async {
    var response = await model.callApis({
      'time_id': timeID,
      'late_history_type': listWorkingSession[_sessionSelected]['id'],
      'date_late': _dateController.text,
      'hours': ''
    }, timeAllowLateEarlyUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      if (response.data['data'][0]['Column1']['v'] != '') {
        var data = jsonDecode(response.data['data'][0]['Column1']['v']);
        setState(() {
          for (int i = 0; i < data.length; i++)
            if (data[i]['late_history_type_id'] == '0')
              totalValidTimeLate = data[i]['late_history_quota_submit'] != ''
                  ? num.parse(data[i]['late_history_quota_submit'])
                  : 0;
            else
              totalValidTimeEarly = data[i]['late_history_quota_submit'] != ''
                  ? num.parse(data[i]['late_history_quota_submit'])
                  : 0;
          if (_timeController.text.isEmpty)
            _timeController.value = TextEditingValue(
                text: timeFormat.format(timeFormat
                    .parse(listWorkingSession[0]['startTimeDefine'])
                    .add(Duration(minutes: totalValidTimeLate))),
                selection: _timeController.selection);
        });
        if(callback != null) callback();
      }
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void getWorkingSession(BaseViewModel model, {Function callBack}) async {
    showLoadingDialog(context);
    var timeID = await getTimeDefine(model);
    if (timeID != null && timeID != -1) {
      List<dynamic> _list = [];
      var response = await model.callApis(
          {"time_id": timeID, "date_late": _dateController.text},
          workingSessionUrl,
          method_post,
          isNeedAuthenticated: true,
          shouldSkipAuth: false);
      if (response.status.code == 200) {
        Navigator.pop(context);
        for (var listItem in response.data['data']) {
          _list.add({
            'timeDefineId': listItem['time_define_id']['v'],
            'id': listItem['ID'],
            'nameTimeDefine': listItem['name_time_define']['v'],
            'startTimeDefine': timeFormat.format(
                DateFormat('dd/MM/yyyy HH:mm:ss a')
                    .parse(listItem['start_time_define']['v'])),
            //convert 12h to 24h
            'endTimeDefine': timeFormat.format(
                        DateFormat('dd/MM/yyyy HH:mm:ss a')
                            .parse(listItem['end_time_define']['r'])) ==
                    '00:00'
                ? timeFormat.format(DateFormat('dd/MM/yyyy HH:mm:ss')
                    .parse(listItem['end_time_define']['r']))
                : timeFormat.format(DateFormat('dd/MM/yyyy HH:mm:ss a')
                    .parse(listItem['end_time_define']['r'])),
          });
        }
        listWorkingSession = _list;
        if (listWorkingSession.length == 1) _sessionSelected = 0;
        getTimeAllowLateEarly(model, timeID, callback: callBack);
      } else {
        Navigator.pop(context);
        showMessageDialog(context,
            description: Utils.getString(context, txt_get_data_failed),
            onPress: () => Navigator.pop(context));
      }
    } else if (timeID == -1) {
      Navigator.pop(context);
      setState(() {
        _dateController.text = dateFormat.format(DateTime(
            dateFormat.parse(_dateController.text).year,
            dateFormat.parse(_dateController.text).month,
            dateFormat.parse(_dateController.text).day + 1));
      });
      getWorkingSession(model, callBack: callBack);
    } else {
      Navigator.pop(context);
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  //get time define check date picker disable click
  void getTimeDefineAll(BaseViewModel model) async {
    var response = await model.callApis({}, timDefineAllUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        for (var item in list['day']['v'].toString().split(';').toList())
          _listDateEnable.add(int.parse(item));
      }
    } else
      debugPrint('error');
  }

  Future<dynamic> getTimeDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"date_late": _dateController.text}, timeDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (response.data['data'].length != 0) {
        return response.data['data'][0]['ID'];
      } else
        return -1;
    } else
      return null;
  }

  void getLateEarlyType(BaseViewModel model, {Function callBack}) async {
    var response = await model.callApis({}, lateEarlyTypeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      List<dynamic> _list = [];
      for (var listItem in response.data['data']) {
        _list.add({'id': listItem['ID'], 'type': listItem['Type']['v']});
      }
      setState(() {
        listLateType = _list;
        if (callBack != null) callBack();
      });
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
  }

  Future<dynamic> checkDouble(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis({
      "ID": -100,
      "date_late": '00:00 ' + _dateController.text,
      "hours": _timeController.text,
      "time_id": listWorkingSession[_sessionSelected]['timeDefineId'],
      "late_history_type": listLateType[_typeSelected]['id']
    }, checkDoubleLateUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      Navigator.pop(context);
      return response.data['data'][0]['result']['r'];
    } else {
      Navigator.pop(context);
      return null;
    }
  }

  void submitData(BaseViewModel model) async {
    if (checkEmpty()) {
      var check = await checkDouble(model);
      if (check == "") {
        showLoadingDialog(context);
        if (_isLateActive) {
          _typeSelected = 0;
        } else {
          _typeSelected = 1;
        }
        var encryptData = await Utils.encrypt(
            "vw_tb_hrms_nhanvien_employee_late_history_submit");
        BaseResponse _user = context.read<BaseResponse>();
        var addDataResponse = await model.callApis({
          "tbname": encryptData,
          "employee_id": _user.data['data'][0]['ID'],
          "date_late": _dateController.text,
          "time_detail_id": listWorkingSession[_sessionSelected]['id'],
          "late_history_type": listLateType[_typeSelected]['id'],
          "hours": _timeController.text,
          "error_time": _totalTime,
          "reason": _reasonController.text,
          "time_id": listWorkingSession[_sessionSelected]['timeDefineId'],
          "iscomplete": true,
          "status": 5
        }, addDataUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.pop(context);
        if (addDataResponse.status.code == 200) {
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_register_success),
              onPress: () => Navigator.pushNamedAndRemoveUntil(
                  context, Routers.main, (r) => false));
        } else {
          //Navigator.pop(context);
          showMessageDialog(context,
              description: Utils.getString(context, txt_register_failed),
              onPress: () => Navigator.pop(context));
        }
      } else if (check == null)
        showMessageDialog(context,
            description: Utils.getString(context, txt_get_data_failed),
            onPress: () => Navigator.pop(context));
      else
        showMessageDialog(context,
            description: check.toString(),
            onPress: () => Navigator.pop(context));
    }
  }

  void getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {"TbName": vw_tb_hrms_nhanvien_employee_late_history_submit},
        getGenRowDefineUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      _genRowList = response.data['data'];
      setState(() {});
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  calculateLimitTime({int indexWorkSession = 0, int indexType = 0}) {
    DateTime start = timeFormat
        .parse(listWorkingSession[indexWorkSession]['startTimeDefine']);
    DateTime end =
        timeFormat.parse(listWorkingSession[indexWorkSession]['endTimeDefine']);

    if (listLateType[indexType]['id'] == '0') {
      setState(() {
        endTimeLimit =
            timeFormat.format(start.add(Duration(minutes: totalValidTimeLate)));
        startTimeLimit = timeFormat.format(start);
        _timeController.value = TextEditingValue(
            text: timeFormat.format(timeFormat.parse(endTimeLimit)),
            selection: _timeController.selection);
      });
    } else {
      setState(() {
        startTimeLimit = timeFormat
            .format(end.subtract(Duration(minutes: totalValidTimeEarly)));
        endTimeLimit = timeFormat.format(end);
        _timeController.value = TextEditingValue(
            text: timeFormat.format(timeFormat.parse(startTimeLimit)),
            selection: _timeController.selection);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
        model: BaseViewModel(),
        onModelReady: (model) {
          getTimeDefineAll(model);
          Future.delayed(Duration(milliseconds: 0), () {
            getGenRowDefine(model);
            getLateEarlyType(model, callBack: () {
              getWorkingSession(model, callBack: () => calculateLimitTime());
            });
          });
        },
        builder: (context, model, child) => Scaffold(
              appBar: appBarCustom(context, () => Navigator.pop(context),
                  () => {}, widget.title, null),
              body: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: Utils.resizeWidthUtil(context, 30)),
                child: GestureDetector(
                  onTap: () => Utils.closeKeyboard(context),
                  child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _userManual(),
                          _buildWorkingDate(model),
                          _buildSessionDateWork(),
                          _buildTimeType(),
                          SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                          _buildRegisterType(),
                          SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                          _buildPlanTime(),
                          SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                          _buildReason(),
                          _buildRegisterLateEarlyButton(model)
                        ],
                      )),
                ),
              ),
            ));
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
                  _showErrorText != ''
                      ? _showErrorText
                      : '${Utils.getString(context, txt_title_register_late_early_header)}'
                          ' ${_typeSelected == 0 ? totalValidTimeLate : totalValidTimeEarly} (${Utils.getString(context, txt_title_register_late_early_header_minute)}).'
                          ' ${Utils.getString(context, txt_title_register_late_early_header_allow_time)}: $startTimeLimit - $endTimeLimit',
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

  Widget _buildWorkingDate(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(_genRowList.length > 0
            ? Utils.getTitle(_genRowList, 'date_late')
            : ''),
        DateTimePickerCustomModify(
          isShowDateOnly: true,
          controller: _dateController,
          initialDate: DateFormat('yyyy-MM-dd').parse(
              DateFormat('dd/MM/yyyy').parse(_dateController.text).toString()),
          firstDate: DateTime(
              dateFormat.parse(_dateController.text).year,
              dateFormat.parse(_dateController.text).month - 1,
              dateFormat.parse(_dateController.text).day),
          callBack: (date, time) async {
            if (_listDateEnable
                    .where((i) => i == date.weekday)
                    .toList()
                    .length ==
                0) {
              showMessageDialogIOS(context,
                  description: Utils.getString(context, txt_choose_date_error));
              return;
            }
            setState(() {
              _dateController.text = dateFormat.format(date);
              getWorkingSession(model);
              _sessionSelected = 0;
              _typeSelected = 0;
              _timeController.text = timeFormat.format(timeFormat
                  .parse(
                      listWorkingSession[_sessionSelected]['startTimeDefine'])
                  .add(Duration(minutes: totalValidTimeLate)));
              checkValidTime(_timeController.text);
            });
          },
        ),
      ],
    );
  }

  Widget _buildSessionDateWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(_genRowList.length > 0
            ? Utils.getTitle(_genRowList, 'time_detail_id')
            : ''),
        SelectBoxCustom(
            valueKey: 'nameTimeDefine',
            title: listWorkingSession.length > 0
                ? listWorkingSession[_sessionSelected]['nameTimeDefine']
                : '',
            data: listWorkingSession,
            selectedItem: _sessionSelected,
            callBack: (itemSelected) => setState(() {
                  if (itemSelected != null) {
                    _sessionSelected = itemSelected;
                    calculateLimitTime(
                        indexWorkSession: _sessionSelected,
                        indexType: _typeSelected);
                    checkValidTime(_timeController.text);
                  }
                })),
      ],
    );
  }

  Widget _buildTimeType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(Utils.getString(context, txt_title_late_early)),
        Row(
          children: <Widget>[
            _iconTime(),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 35),
            ),
            Expanded(
              child: Column(
                children: <Widget>[
                  TextFieldCustom(
                      controller: TextEditingController(
                          text: listWorkingSession.length > 0
                              ? listWorkingSession[_sessionSelected]
                                  ['startTimeDefine']
                              : ''),
                      imgLeadIcon: ic_calendar,
                      enable: false),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                  TextFieldCustom(
                      controller: TextEditingController(
                          text: listWorkingSession.length > 0
                              ? listWorkingSession[_sessionSelected]
                                  ['endTimeDefine']
                              : ''),
                      imgLeadIcon: ic_calendar,
                      enable: false),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildRegisterType() {
    return listLateType.length > 0
        ? Row(
            children: <Widget>[
              Expanded(
                  flex: 1,
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _typeSelected = 0;
                        calculateLimitTime(
                            indexWorkSession: _sessionSelected, indexType: 0);
                        checkValidTime(_timeController.text);
                        setState(() {
                          _isLateActive = true;
                          _isEarlyActive = false;
                        });
                      },
                      child: _lateEarlyType(listLateType[0]['type'],
                          isActive: _isLateActive))),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 30),
              ),
              Expanded(
                  flex: 1,
                  child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        _typeSelected = 1;
                        calculateLimitTime(
                            indexWorkSession: _sessionSelected, indexType: 1);
                        checkValidTime(_timeController.text);
                        setState(() {
                          _isLateActive = false;
                          _isEarlyActive = true;
                        });
                      },
                      child: _lateEarlyType(listLateType[1]['type'],
                          isActive: _isEarlyActive)))
            ],
          )
        : Container();
  }

  Widget _buildPlanTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(
            _genRowList.length > 0 ? Utils.getTitle(_genRowList, 'hours') : ''),
        DateTimePickerCustomModify(
          subText: _totalTime.toString(),
          isShowTimeOnly: true,
          controller: _timeController,
          initialTime: TimeOfDay.fromDateTime(
              DateFormat('HH:mm').parse(_timeController.text)),
          callBack: (date, time) async {
            setState(() {
              _timeController.text = timeFormat
                  .format(timeFormat.parse("${time.hour}:${time.minute}"));
              checkValidTime("${time.hour}:${time.minute}");
            });
          },
        ),
      ],
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
        controller: _reasonController,
        hintText: _genRowList.length == 0
            ? ''
            : Utils.getTitle(_genRowList, 'reason'),
        expandMultiLine: true,
        forceError: _forceErrorTimeOffReason,
        onChange: (changeValue) {
          if (_genRowList
                  .where((i) => i['Name']['r'] == 'reason')
                  .toList()[0]['AllowNull']['v']
                  .toString() !=
              'True') {
            setState(() {
              _forceErrorTimeOffReason =
                  _reasonController.text.trimRight().isEmpty;
            });
          }
        });
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

  Widget _buildRegisterLateEarlyButton(BaseViewModel model) {
    return Container(
      margin: EdgeInsets.only(
          left: 4,
          right: 4,
          top: Utils.resizeHeightUtil(context, 50),
          bottom: Utils.resizeHeightUtil(context, 90)),
      child: TKButton(Utils.getString(context, txt_button_send),
          enable: _enableUpdateButton, width: double.infinity, onPress: () {
        Utils.closeKeyboard(context);
        submitData(model);
      }),
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

  Widget _lateEarlyType(String title, {bool isActive = false}) {
    return Container(
      height: Utils.resizeHeightUtil(context, 82),
      decoration: BoxDecoration(
          color: isActive ? txt_yellow.withOpacity(0.07) : bg_text_field,
          border: isActive ? Border.all(color: txt_yellow, width: 2) : null,
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
      child: DottedBorder(
          borderType: BorderType.RRect,
          color: isActive ? Colors.transparent : border_text_field,
          strokeWidth: Utils.resizeWidthUtil(context, 2),
          radius: Radius.circular(Utils.resizeWidthUtil(context, 10)),
          dashPattern: [
            Utils.resizeWidthUtil(context, 6),
            Utils.resizeWidthUtil(context, 3)
          ],
          child: Stack(
            children: <Widget>[
              isActive
                  ? Positioned(
                      left: Utils.resizeWidthUtil(context, 22),
                      top: Utils.resizeHeightUtil(context, 20),
                      child: Image.asset(ic_checkbox_compensatory,
                          width: Utils.resizeWidthUtil(context, 34),
                          height: Utils.resizeHeightUtil(context, 34)),
                    )
                  : Container(),
              Center(
                child: TKText(
                  title,
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      color: isActive ? txt_yellow : txt_grey_color_v3,
                      fontSize: Utils.resizeWidthUtil(context, 30)),
                ),
              ),
            ],
          )),
    );
  }
}
