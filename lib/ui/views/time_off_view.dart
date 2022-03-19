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
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final dateTimeFormat = DateFormat("HH:mm dd/MM/yyyy");

class TimeOffRegisterView extends StatefulWidget {
  final String title;

  TimeOffRegisterView(this.title);

  @override
  _TimeOffRegisterViewState createState() => _TimeOffRegisterViewState();
}

class _TimeOffRegisterViewState extends State<TimeOffRegisterView>
    with TickerProviderStateMixin {
  BaseResponse _user;

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  TextEditingController _reasonController = TextEditingController();

  TextEditingController _workAssignController = TextEditingController();

  dynamic _typeSelected;

  dynamic _userSelected;

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  List<dynamic> _typeOffList = [];

  List<dynamic> _typeGroupList = [];

  List<dynamic> _assignerList = [];

  List<dynamic> _otherList = [];

  dynamic _genRow = {};

  num _totalQuotaAbsent = 0;

  num _totalQuotaAbsentAllow = 0;

  num _totalQuotaLeaveMode = 0;

  num _totalQuotaSalary = 0;

  num _totalQuotaNonSalary = 0;

  bool _forceErrorWorkAssign = false;

  bool _forceErrorTimeOffReason = false;

  bool _isShowInfoDayOff = false;

  AnimationController expandController;

  Animation<double> animation;

  bool _workAssignShow = false;

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  final SpeechToText speech = SpeechToText();

  int positionDetectSpeech = 0;

  int nextIndex = 0;

  String searchText = '';

  String _showErrorText = '';

  String _showInfoText = '';

  bool isOpenModal = false;

  ScrollController _scrollController = ScrollController();

  bool _enableRegisterButton = false;

  @override
  void initState() {
    super.initState();
    initSpeechState();
    _dateTimeStartController.value = TextEditingValue(
        text: dateTimeFormat.format(dateTimeFormat
            .parse('07:30 ' + DateFormat('dd/MM/yyyy').format(DateTime.now()))),
        selection: _dateTimeStartController.selection);

    _dateTimeEndController.value = TextEditingValue(
        text: dateTimeFormat.format(dateTimeFormat
            .parse('17:30 ' + DateFormat('dd/MM/yyyy').format(DateTime.now()))),
        selection: _dateTimeEndController.selection);

    _startWorkingTime = dateTimeFormat.parse(_dateTimeStartController.text);

    _endWorkingTime = dateTimeFormat.parse(_dateTimeEndController.text);

    _reasonController.addListener(_onTextFieldChange);

    _prepareAnimations();
  }

  _onTextFieldChange() {
    if (_reasonController.text.length > 0) {
      _enableRegisterButton = true;
    } else
      _enableRegisterButton = false;
    setState(() {});
  }

  void _prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  void _runExpand() {
    if (_isShowInfoDayOff) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
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
        if (positionDetectSpeech == 1) {
          _workAssignController.text = result.recognizedWords;
          if (_genRow
                  .where((i) => i['Name']['r'] == 'assign_reason')
                  .toList()[0]['AllowNull']['v']
                  .toString() !=
              'True')
            _forceErrorWorkAssign =
                _workAssignController.text.trimRight().isEmpty;
        } else if (positionDetectSpeech == 2) {
          _reasonController.text = result.recognizedWords;
          if (_genRow['reason']['allowNull'])
            _forceErrorTimeOffReason =
                _reasonController.text.trimRight().isEmpty;
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

  @override
  void dispose() {
    if (!mounted) {
      _dateTimeStartController.dispose();
      _dateTimeEndController.dispose();
      _reasonController.dispose();
      _workAssignController.dispose();
      expandController.dispose();
    }
    super.dispose();
  }

  bool _validate({BaseViewModel model, bool firstCheck = false}) {
    bool isValid = true;
    if (firstCheck == false) {
      if (_reasonController.text.isEmpty) {
        setState(() {
          _forceErrorTimeOffReason = true;
        });
        isValid = false;
      }
      if (_workAssignShow == true) {
        if (_workAssignController.text.isEmpty) {
          setState(() {
            _forceErrorWorkAssign = true;
          });
          isValid = false;
        }
      }
    }
    if (_startWorkingTime.isAtSameMomentAs(_endWorkingTime)) {
      if (firstCheck == false)
        showMessageDialog(context,
            description: Utils.getString(context, txt_start_time_same_end_time),
            onPress: () => Navigator.pop(context));
      else
        _showErrorText = Utils.getString(context, txt_start_time_same_end_time);
      isValid = false;
    }
    if (_totalQuotaAbsentAllow != -100) {
      if (_totalQuotaAbsentAllow < _totalQuotaAbsent) {
        if (firstCheck == false) {
          showMessageDialog(context,
              description: Utils.getString(context, txt_error_register_day_off),
              onPress: () {
            Navigator.pop(context);
            Utils.closeKeyboard(context);
            submitData(model, isCheckValid: false);
          });
        } else
          _showErrorText = Utils.getString(context, txt_error_register_day_off);
        isValid = false;
      }
    }
    if (_totalQuotaAbsent == 0) {
      if (firstCheck == false)
        showMessageDialog(context,
            description: Utils.getString(context, txt_error_is_less_than_time),
            onPress: () => Navigator.pop(context));
      else
        _showErrorText = Utils.getString(context, txt_error_is_less_than_time);
      isValid = false;
    }
    if (_showInfoText == '') {
      _totalQuotaAbsent = 0;
      if (firstCheck == false)
        showMessageDialog(context,
            description:
                Utils.getString(context, txt_error_register_day_off_min),
            onPress: () => Navigator.pop(context));
      else
        _showErrorText =
            Utils.getString(context, txt_error_register_day_off_min);
      isValid = false;
    }
    return isValid;
  }

  void getAbsentType(BaseViewModel model,
      {String searchText = '',
      Function callback,
      int nextIndex = 0,
      SelectBoxCustomUtilState state}) async {
    var typeOffList = List<dynamic>();
    var data = {
      'search_text': searchText,
      'next_index': nextIndex,
      'num_row': 10
    };
    var response = await model.callApis(data, absentTypeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var type in response.data['data']) {
        typeOffList.add({
          'id': type['ID'],
          'name': type['name_absent']['v'],
          'total_row': type['total_row']['v']
        });
      }
      _typeOffList.addAll(typeOffList);
      if (_typeOffList.length > 0) {
        _typeSelected = _typeOffList[0];
      }
      if (state != null) {
        state.updateDataList(_typeOffList);
      }
      if (callback != null) {
        callback();
      }
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getAbsentTypeGroup(BaseViewModel model) async {
    var groupList = List<dynamic>();
    var response = await model.callApis({"absent_type_id": _typeSelected['id']},
        absentTypeGroupUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      groupList.add([
        response.data['data'][0]['ID'],
        response.data['data'][0]['name_absent_group']['v']
      ]);
      setState(() {
        _typeGroupList = groupList;
      });
    }
  }

  void getAssigner(BaseViewModel model,
      {String searchText = '',
      int nextIndex = 0,
      SelectBoxCustomUtilState state}) async {
    List<dynamic> assignerList = [];
    var data = {
      'search_text': searchText,
      'next_index': nextIndex,
      'num_row': 10
    };
    var response = await model.callApis(data, allUserUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var user in response.data['data']) {
        assignerList.add({
          'id': user['ID'],
          'name': user['full_name']['v'],
          'emp_id': user['emp_id']['v'],
          'total_row': user['total_row']['v']
        });
      }
      _assignerList.addAll(assignerList);
      if (state != null) {
        state.updateDataList(_assignerList);
      }
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getQuotaAbsentAllow(BaseViewModel model, Function callback) async {
    var response = await model.callApis({"absent_type_id": _typeSelected['id']},
        quotaAbsentAllowUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        response.data['data'][0]['result']['r'] == ''
            ? _totalQuotaAbsentAllow = -100
            : _totalQuotaAbsentAllow =
                num.parse(response.data['data'][0]['result']['r']);
        callback();
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  getQuotaAbsent(BaseViewModel model, {Function callback}) async {
    var response = await model.callApis({
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, quotaAbsentUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _totalQuotaAbsent = num.parse(response.data['data'][0]['result']['r']);
        if (callback != null) callback();
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  //type 0 nghi phep che do, 1 nghi phep co luong, 2 nghi phep khong luong
  void getQuotaRegime(num type, BaseViewModel model) async {
    var response = await model.callApis({
      "quota_absent": _totalQuotaAbsent,
      "ngay_phep_cho_phep_dk": _totalQuotaAbsentAllow,
      "absent_type_id": _typeSelected['id'],
      "type": type,
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, quotaRegimeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        type == 0
            ? _totalQuotaLeaveMode =
                num.parse(response.data['data'][0]['result']['v'])
            : type == 1
                ? _totalQuotaSalary =
                    num.parse(response.data['data'][0]['result']['v'])
                : _totalQuotaNonSalary =
                    num.parse(response.data['data'][0]['result']['v']);
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getQuotaOther(BaseViewModel model) async {
    var otherList = List<dynamic>();
    var response = await model.callApis({}, quotaOtherUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      otherList.add([
        response.data['data'][0]['tong_ngay_phep']['r'],
        response.data['data'][0]['so_ngay_phep_da_nghi']['r'],
        response.data['data'][0]['ngay_phep_con_lai']['r'],
        response.data['data'][0]['ngay_phep_cho_duyet']['r'],
        response.data['data'][0]['ngay_phep_cho_phep_dk']['r'],
      ]);
      setState(() {
        _otherList = otherList;
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  Future<dynamic> checkDouble(BaseViewModel model) async {
    var response = await model.callApis({
      "ID": -100,
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, checkDoubleOffUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      return response.data['data'][0]['result']['v'];
    } else
      return null;
  }

  Future<dynamic> checkValidateTimeOff(BaseViewModel model) async {
    var response = await model.callApis({
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, checkValidateTimeOffUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      String result = response.data['data'][0]['result']['v'];
      String hourInfo = result.split(';')[0];
      String dayInfo = result.split(';')[1];
      setState(() {
        if (double.parse(dayInfo) < 0.5) {
          _showInfoText = '';
        } else {
          _showInfoText =
              '${Utils.getString(context, txt_title_time_off_title_1)} $hourInfo ${Utils.getString(context, txt_title_time_off_title_hour)}'
              ' (${Utils.getString(context, txt_title_time_off_title_2)}), ${Utils.getString(context, txt_title_time_off_title_3)} '
              '$dayInfo ${Utils.getString(context, txt_title_time_off_title_day)}';
        }
      });
    }
  }

  void getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_nghiphep_absent_history_sm"},
        getGenRowDefineUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      _genRow = Utils.getListGenRow(response.data['data'], 'add');
      setState(() {});
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void submitData(BaseViewModel model, {bool isCheckValid = true}) async {
    if (isCheckValid ? _validate(model: model) : true) {
      var check = await checkDouble(model);
      if (check == "") {
        var encryptData =
            await Utils.encrypt("vw_tb_hrms_nghiphep_absent_history_sm");
        var data = {
          "tbname": encryptData,
          "employee_id": _user.data['data'][0]['ID'],
          "from_time":
              DateFormat("MM/dd/yyyy HH:mm:ss").format(_startWorkingTime),
          "to_time": DateFormat("MM/dd/yyyy HH:mm:ss").format(_endWorkingTime),
          "absent_type_id": _typeSelected['id'],
          "reason": _reasonController.text,
          "assign_employeeID": _userSelected == null ? -1 : _userSelected['id'],
          "assign_reason": _workAssignController.text,
          "absent_type_group_id": _typeGroupList[0][0],
          "quota_absent": _totalQuotaAbsent,
          "quota_absent_allow":
              _totalQuotaAbsentAllow == -100 ? 0 : _totalQuotaAbsentAllow,
          "NghiPhepCheDo": _totalQuotaLeaveMode,
          "NghiPhepCoLuong": _totalQuotaSalary,
          "NghiPhepKhongLuong": _totalQuotaNonSalary,
          "iscomplete": true,
          "status": 5
        };
        showLoadingDialog(context);
        var submitResponse = await model.callApis(data, addDataUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.pop(context);
        if (submitResponse.status.code == 200) {
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_register_success),
              onPress: () => Navigator.pushNamedAndRemoveUntil(
                  context, Routers.main, (r) => false));
        } else {
          showMessageDialog(context,
              description: Utils.getString(context, txt_register_failed),
              onPress: () => Navigator.pop(context));
        }
      } else if (check == null) {
        showMessageDialog(context,
            description: Utils.getString(context, txt_get_data_failed),
            onPress: () => Navigator.pop(context));
      } else {
        setState(() {
          _showErrorText = check.toString();
        });
      }
    } else {
      _scrollController.animateTo(
        0.0,
        curve: Curves.easeOut,
        duration: Duration(milliseconds: 300),
      );
    }
  }

  refreshInfoValidate(BaseViewModel model) async {
    var check = await checkDouble(model);
    if (check != '' && check != null) {
      setState(() {
        _showErrorText = check.replaceAll(';', '');
      });
      return;
    }
    //await getQuotaAbsent(model);
    await getQuotaAbsent(model, callback: () {
      getQuotaRegime(0, model);
      getQuotaRegime(1, model);
      getQuotaRegime(2, model);
      getAbsentTypeGroup(model);
    });
    await checkValidateTimeOff(model);

    setState(() {
      if (_validate(firstCheck: true)) {
        _showErrorText = '';
      } else {
        _scrollController.animateTo(
          0.0,
          curve: Curves.easeOut,
          duration: Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _user = context.watch<BaseResponse>();
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        checkDouble(model);
        Future.delayed(Duration(milliseconds: 0), () {
          checkValidateTimeOff(model);
          getGenRowDefine(model);
          getAbsentType(model, callback: () {
            getQuotaAbsentAllow(model, () {
              getQuotaAbsent(model, callback: () {
                getQuotaRegime(0, model);
                getQuotaRegime(1, model);
                getQuotaRegime(2, model);
                getAbsentTypeGroup(model);
              });
            });
          });
          getQuotaOther(model);
          getAssigner(model);
        });
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () {
          Utils.closeKeyboard(context);
          Navigator.pop(context, 0);
        }, () {
          Utils.closeKeyboard(context);
          submitData(model);
        }, widget.title, null),
        body: Stack(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 30)),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                    _userManual(context),
                    SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                    _buildDayOffInfo(),
//                    _typeSelected != null && _typeSelected['id'] == '0'
//                        ? _buildInfoDayOff()
//                        : SizedBox.shrink(),
                    _buildInfoDayOff(),
                    _buildTimeOff(model),
                    _buildAssigned(model),
                    SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                    _buildWorkAssigned(),
                    _buildTypeOff(model),
                    boxTitle(context,
                        _genRow.length == 0 ? '' : _genRow['reason']['name']),
                    _buildReason(),
                    _buildRegisterTimeOffButton(model),
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

  Widget _userManual(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 5, 0),
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
            child: Column(
              children: <Widget>[
                _showInfoText != ''
                    ? TKText(
                        _showInfoText,
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 26),
                            color: gradient_start_color.withOpacity(0.8)),
                      )
                    : Container(),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: Utils.resizeHeightUtil(context, 10)),
                  child: TKText(
                    _showErrorText.replaceAll('mới Đã', 'mới\nĐã'),
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        fontSize: Utils.resizeWidthUtil(context, 26),
                        color: txt_fail_color),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.asset(work_outside),
          )
        ],
      ),
    );
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
                      firstDate: DateTime(DateTime.now().year),
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
                        refreshInfoValidate(model);
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
                        refreshInfoValidate(model);
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

  Widget _buildTypeOff(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context,
            _genRow.length == 0 ? '' : _genRow['absent_type_id']['name']),
        SelectBoxCustomUtil(
            title: _typeOffList.length > 0
                ? _typeSelected != null
                    ? _typeSelected['name']
                    : _typeOffList[0]['name']
                : Utils.getString(context, txt_choose_absent_type_hint),
            data: _typeOffList,
            selectedItem: 0,
            clearCallback: () {
              setState(() {
                _typeSelected = null;
                _typeOffList.clear();
              });
            },
            initCallback: (state) {
              searchText = '';
              nextIndex = 0;
              _typeOffList.clear();
              getAbsentType(model, nextIndex: nextIndex, state: state);
            },
            loadMoreCallback: (state) {
              if (_typeOffList.length <
                  int.parse(_typeOffList[0]['total_row'])) {
                nextIndex += 10;
                getAbsentType(model,
                    nextIndex: nextIndex, searchText: searchText, state: state);
              }
            },
            searchCallback: (value, state) {
              if (value != '') {
                Future.delayed(Duration(milliseconds: 300), () {
                  searchText = value;
                  nextIndex = 0;
                  _typeOffList.clear();
                  getAbsentType(model,
                      nextIndex: nextIndex, searchText: value, state: state);
                });
              }
            },
            callBack: (itemSelected) => setState(() {
                  if (itemSelected != null) {
                    _typeSelected = itemSelected;
                    getQuotaAbsentAllow(model, () {
                      getQuotaRegime(0, model);
                      getQuotaRegime(1, model);
                      getQuotaRegime(2, model);
                      getAbsentTypeGroup(model);
                    });
                  }
                })),
      ],
    );
  }

  Widget _buildDayOffInfo() {
    return Container(
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 10)),
      child: Column(
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              setState(() {
                _isShowInfoDayOff = !_isShowInfoDayOff;
              });
              _runExpand();
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      Image.asset(ic_notification,
                          width: Utils.resizeWidthUtil(context, 42),
                          height: Utils.resizeHeightUtil(context, 42)),
                      SizedBox(
                        width: Utils.resizeWidthUtil(context, 10),
                      ),
                      TKText(
                        Utils.getString(context, txt_info_time_off),
                        tkFont: TKFont.SFProDisplayMedium,
                        style: TextStyle(
                            color: txt_grey_color_v3,
                            fontSize: Utils.resizeWidthUtil(context, 32)),
                      ),
                    ],
                  ),
                ),
                _isShowInfoDayOff
                    ? Image.asset(ic_arrow_down,
                        width: Utils.resizeWidthUtil(context, 22),
                        height: Utils.resizeHeightUtil(context, 11))
                    : Image.asset(ic_arrow_forward,
                        width: Utils.resizeWidthUtil(context, 11),
                        height: Utils.resizeHeightUtil(context, 22))
              ],
            ),
          ),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 20),
          ),
          SizeTransition(
            axisAlignment: 1.0,
            sizeFactor: animation,
            child: Container(
              margin:
                  EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 20)),
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 20)),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: txt_grey_color_v1,
                      width: Utils.resizeWidthUtil(context, 1))),
              child: _genRow.length == 0
                  ? SizedBox.shrink()
                  : Column(
                      children: <Widget>[
                        _itemDayOffInfo(
                            _genRow['quota_absent_allow']['name'],
                            _totalQuotaAbsentAllow == null
                                ? Utils.getString(context, txt_waiting)
                                : _totalQuotaAbsentAllow == -100
                                    ? ''
                                    : _totalQuotaAbsentAllow.toString()),
                        _itemDayOffInfo(_genRow['so_ngay_phep_da_nghi']['name'],
                            _otherList.length > 0 ? _otherList[0][1] : ''),
                        _itemDayOffInfo(
                            _genRow['NghiPhepCheDo']['name'],
                            _totalQuotaLeaveMode == null
                                ? Utils.getString(context, txt_waiting)
                                : _totalQuotaLeaveMode.toString()),
                        _itemDayOffInfo(_genRow['ngay_phep_cho_duyet']['name'],
                            _otherList.length > 0 ? _otherList[0][3] : ''),
                        _itemDayOffInfo(
                            _genRow['NghiPhepKhongLuong']['name'],
                            _totalQuotaNonSalary != null
                                ? _totalQuotaNonSalary.toString()
                                : ''),
                        _itemDayOffInfo(
                            _genRow['ngay_phep_cho_phep_dk']['name'],
                            _otherList.length > 0 ? _otherList[0][4] : ''),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }

  Widget _itemDayOffInfo(String title, String value) {
    return Container(
      height: Utils.resizeWidthUtil(context, 70),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TKText(title,
                style: TextStyle(
                    color: txt_grey_color_v6,
                    fontSize: Utils.resizeWidthUtil(context, 30)),
                tkFont: TKFont.SFProDisplayRegular),
          ),
          TKText(value,
              style: TextStyle(
                  color: txt_grey_color_v3,
                  fontSize: Utils.resizeWidthUtil(context, 30)),
              tkFont: TKFont.SFProDisplayRegular),
        ],
      ),
    );
  }

  Widget _buildReason() {
    return TextFieldCustom(
        onSpeechPress: () {
          positionDetectSpeech = 2;
          isOpenModal = true;
          startListening();
          Future.delayed(Duration(seconds: 5), () {
            isOpenModal = false;
            Navigator.pop(context);
          });
        },
        controller: _reasonController,
        hintText: 'Nhập lý do',
        expandMultiLine: true,
        forceError: _forceErrorTimeOffReason,
        onChange: (changeValue) {
          if (_genRow['reason']['allowNull'])
            setState(() {
              _forceErrorTimeOffReason =
                  _reasonController.text.trimRight().isEmpty;
            });
        });
  }

  Widget _buildAssigned(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context,
            _genRow.length == 0 ? '' : _genRow['assign_employeeID']['name']),
        SelectBoxCustomUtil(
            title: _assignerList.length > 0
                ? _userSelected == null
                    ? Utils.getString(context, txt_choose_assign_person_hint)
                    : _userSelected['emp_id'] +
                        '(' +
                        _userSelected['name'] +
                        ')'
                : '',
            data: _assignerList,
            selectedItem: 0,
            clearCallback: () {
              setState(() {
                _userSelected = null;
                _workAssignShow = false;
              });
            },
            initCallback: (state) {
              searchText = '';
              nextIndex = 0;
              _assignerList.clear();
              getAssigner(model, nextIndex: nextIndex, state: state);
            },
            loadMoreCallback: (state) {
              if (_assignerList.length <
                  int.parse(_assignerList[0]['total_row'])) {
                nextIndex += 10;
                getAssigner(model,
                    nextIndex: nextIndex, searchText: searchText, state: state);
              }
            },
            searchCallback: (value, state) {
              if (value != '') {
                Future.delayed(Duration(milliseconds: 300), () {
                  searchText = value;
                  nextIndex = 0;
                  _assignerList.clear();
                  getAssigner(model,
                      nextIndex: nextIndex, searchText: value, state: state);
                });
              }
            },
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null)
                  _workAssignShow = true;
                else
                  _workAssignShow = false;
                _userSelected = itemSelected;
              });
            }),
      ],
    );
  }

  Widget _buildWorkAssigned() {
    return Visibility(
      visible: _workAssignShow,
      child: TextFieldCustom(
          controller: _workAssignController,
          hintText: _genRow.length == 0 ? '' : _genRow['assign_reason']['name'],
          expandMultiLine: true,
          forceError: _forceErrorWorkAssign,
          onSpeechPress: () {
            positionDetectSpeech = 1;
            isOpenModal = true;
            startListening();
            Future.delayed(Duration(seconds: 5), () {
              isOpenModal = false;
              Navigator.pop(context);
            });
          },
          onChange: (changeValue) {
            if (_genRow['assign_reason']['allowNull'])
              setState(() {
                _forceErrorWorkAssign =
                    _workAssignController.text.trimRight().isEmpty;
              });
          }),
    );
  }

  Widget _buildRegisterTimeOffButton(BaseViewModel model) {
    return Container(
      margin: EdgeInsets.only(
          left: 4,
          right: 4,
          top: Utils.resizeHeightUtil(context, 50),
          bottom: Utils.resizeHeightUtil(context, 90)),
      child: TKButton(Utils.getString(context, txt_button_send),
          enable: _enableRegisterButton, width: double.infinity, onPress: () {
        submitData(model);
      }),
    );
  }

  Widget _buildInfoDayOff() {
    return _genRow.length > 0
        ? Table(
            border: TableBorder.all(color: Colors.black26, width: 1),
            children: [
                TableRow(
                    decoration: BoxDecoration(color: Colors.white),
                    children: [
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.all(
                              Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _genRow['quota_absent']['name']
                                  .replaceAll('nghỉ phép', 'n.p'),
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 26)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayRegular),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: EdgeInsets.all(
                              Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _genRow['phep_con_lai']['name']
                                  .replaceAll('ngày phép', 'n.p'),
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 26)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayRegular),
                        ),
                      ),
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.all(
                                Utils.resizeHeightUtil(context, 10)),
                            child: TKText(
                                _genRow['tong_ngay_phep']['name']
                                    .replaceAll('ngày phép', 'n.p'),
                                style: TextStyle(
                                    color: txt_grey_color_v6,
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 26)),
                                textAlign: TextAlign.center,
                                tkFont: TKFont.SFProDisplayRegular),
                          )),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(
                              Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _genRow['NghiPhepCoLuong']['name']
                                  .replaceAll('nghỉ phép', 'n.p'),
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 26)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayRegular),
                        ),
                      ),
                    ]),
                TableRow(
                    decoration: BoxDecoration(color: Colors.white),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _totalQuotaAbsent == null
                                  ? Utils.getString(context, txt_waiting)
                                  : _totalQuotaAbsent.toString(),
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 28)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayBold),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _otherList.length > 0 ? _otherList[0][2] : '',
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 28)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayBold),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _otherList.length > 0 ? _otherList[0][0] : '',
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 28)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayBold),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: Utils.resizeHeightUtil(context, 10)),
                          child: TKText(
                              _totalQuotaSalary != null
                                  ? _totalQuotaSalary.toString()
                                  : '',
                              style: TextStyle(
                                  color: txt_grey_color_v6,
                                  fontSize: Utils.resizeWidthUtil(context, 28)),
                              textAlign: TextAlign.center,
                              tkFont: TKFont.SFProDisplayBold),
                        ),
                      ),
                    ])
              ])
        : SizedBox.shrink();
  }
}
