import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
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
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

final dateTimeFormat = DateFormat("HH:mm dd/MM/yyyy");

class WorkOutsideRegisterView extends StatefulWidget {
  final String title;

  WorkOutsideRegisterView(this.title);

  @override
  _WorkOutsideRegisterViewState createState() => _WorkOutsideRegisterViewState();
}

class _WorkOutsideRegisterViewState extends State<WorkOutsideRegisterView> {
  TextEditingController _transportEdtController = TextEditingController();

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  TextEditingController _contentEdtController = TextEditingController();

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  num quotaOutside;

  bool _forceErrorTransport = false;

  bool _forceErrorContent = false;

  bool _enableRegisterButton = false;

  String _showErrorText = '';

  dynamic _genRow = {};

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  final SpeechToText speech = SpeechToText();

  bool isOpenModal = false;

  @override
  void dispose() {
    if (!mounted) {
      _transportEdtController.dispose();
      _dateTimeStartController.dispose();
      _dateTimeEndController.dispose();
      _contentEdtController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initSpeechState();
    var model = BaseViewModel();
    _dateTimeStartController.value =
        TextEditingValue(text: dateTimeFormat.format(DateTime.now()), selection: _dateTimeStartController.selection);

    _dateTimeEndController.value =
        TextEditingValue(text: dateTimeFormat.format(DateTime.now()), selection: _dateTimeEndController.selection);

    _startWorkingTime = dateTimeFormat.parse(_dateTimeStartController.text);

    _endWorkingTime = dateTimeFormat.parse(_dateTimeEndController.text);

    _transportEdtController.addListener(_onTextFieldChange);
    _contentEdtController.addListener(_onTextFieldChange);
    Future.delayed(Duration(milliseconds: 0), () {
      getGenRowDefine(model);
      getQuotaOutside(model);
      checkDouble(model);
    });
  }

  getGoogleApiKey(BaseViewModel model) async {
    var response =
        await model.callApis({}, googleApiKey, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      await SecureStorage()
          .saveCustomString(SecureStorage.GOOGLE_KEY, response.data['data'][0]['GoogleApiKey']['v']);
  }

  _onTextFieldChange() {
    if (_transportEdtController.text.length >= 1 && _contentEdtController.text.length >= 1) {
      _enableRegisterButton = true;
    } else
      _enableRegisterButton = false;
    setState(() {});
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(onError: errorListener, onStatus: statusListener);
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
    print("Received listener status: $status, listening: ${speech.isListening}");
    setState(() {
      lastStatus = "$status";
    });
  }

  void startListening() {
    _contentEdtController.text = '';
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
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
      if (isOpenModal) _contentEdtController.text = result.recognizedWords;
      if (_genRow['content']['allowNull'] != 'True') {
        _forceErrorContent = _contentEdtController.text.trimRight().isEmpty;
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

  void getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_nhanvien_employee_outside_calendar_submit_V2"}, getGenRowDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      _genRow = Utils.getListGenRow(response.data['data'], 'add');
      setState(() {});
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  bool checkValidate() {
    if (_showErrorText != '') {
      return false;
    }
    if (_startWorkingTime.isAtSameMomentAs(_endWorkingTime)) {
      setState(() {
        _showErrorText = Utils.getString(context, txt_start_time_same_end_time);
      });
      return false;
    }
    if (_transportEdtController.text.isEmpty) {
      setState(() {
        _forceErrorTransport = true;
      });
      return false;
    }
    if (_contentEdtController.text.isEmpty) {
      setState(() {
        _forceErrorContent = true;
      });
      return false;
    }
    return true;
  }

  void getQuotaOutside(BaseViewModel model) async {
    var response = await model.callApis({
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, quotaOutsideUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        quotaOutside = num.parse(response.data['data'][0]['result']['r']);
      });
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  checkDouble(BaseViewModel model) async {
    var response = await model.callApis({
      "ID": -100,
      "from_time": _dateTimeStartController.text,
      "to_time": _dateTimeEndController.text
    }, checkDoubleOutside, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      _showErrorText = response.data['data'][0]['result']['r'].replaceAll(';', '');
      setState(() {});
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getGoogleApiKey(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
          Utils.closeKeyboard(context);
        }, widget.title, null),
        backgroundColor: main_background,
        body: Stack(
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 30)),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _userManual(),
                    boxTitle(context, "Thời gian công tác"),
                    _buildTimeOutside(model),
                    boxTitle(context, _genRow.length > 0 ? _genRow['transport']['name'] : ''),
                    _buildTransport(),
                    boxTitle(context, _genRow.length > 0 ? _genRow['content']['name'] : ''),
                    TextFieldCustom(
                        onSpeechPress: () {
                          isOpenModal = true;
                          startListening();
                          Future.delayed(Duration(seconds: 5), () {
                            isOpenModal = false;
                            Navigator.pop(context);
                          });
                        },
                        controller: _contentEdtController,
                        hintText: _genRow.length > 0 ? _genRow['content']['name'] + '...' : '',
                        forceError: _forceErrorContent,
                        expandMultiLine: true,
                        onSubmit: (value) {

                        },
                        onChange: (changeValue) {
                          if (_genRow['content']['allowNull'] != 'True') {
                            setState(() {
                              _forceErrorContent = _contentEdtController.text.trimRight().isEmpty;
                            });
                          }
                        }),
                    SizedBox(height: Utils.resizeHeightUtil(context, 30)),
                    TKButton(Utils.getString(context, txt_continue),
                        enable: _enableRegisterButton && _showErrorText.isEmpty,
                        width: Utils.resizeWidthUtil(context, 690), onPress: () async {
                      var encryptData = await Utils.encrypt("tb_hrms_congtacngoai_outside_calendar");
                      BaseResponse _user = context.read<BaseResponse>();
                      Navigator.pushNamed(context, Routers.map, arguments: {
                        'data': {
                          "tbname": encryptData,
                          "employee_id": _user.data['data'][0]['ID'],
                          "transport": _transportEdtController.text,
                          "from_time": DateFormat("MM/dd/yyyy HH:mm:ss").format(_startWorkingTime),
                          "to_time": DateFormat("MM/dd/yyyy HH:mm:ss").format(_endWorkingTime),
                          "content": _contentEdtController.text,
                          "quota_outside": quotaOutside,
                          "status": 5,
                          "is_location_radius": false
                        },
                        'from_time': DateFormat("HH:mm dd/MM/yyyy").format(_startWorkingTime),
                        'to_time': DateFormat("HH:mm dd/MM/yyyy").format(_endWorkingTime),
                        'gen_row_define': _genRow,
                        'type': 'outside',
                        'childTableName': 'tb_hrms_congtacngoai_outside_calendar_place'
                      });
                    }),
                    SizedBox(height: Utils.resizeHeightUtil(context, 30)),
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
        margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20), bottom: Utils.resizeHeightUtil(context, 20)),
        decoration: BoxDecoration(
          color: _showErrorText == '' ? blue_light.withOpacity(0.3) : txt_fail_color.withOpacity(0.3),
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
                  _showErrorText == ''
                      ? 'Lựa chọn vị trí hoặc địa chỉ công tác ngoài phải chính xác để thực hiện chấm công!'
                          '\nHệ thống chỉ ghi nhận thời gian chấm công trong thời gian đăng ký công tác ngoài!'
                      : _showErrorText.replaceAll('mới Đã', 'mới\nĐã'),
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 26),
                      color: _showErrorText == '' ? gradient_start_color.withOpacity(0.8) : txt_fail_color),
                ),
              ),
            ),
            Expanded(flex: 1, child: Image.asset(work_outside))
          ],
        ));
  }

  Widget _buildTransport() {
    return TextFieldCustom(
        controller: _transportEdtController,
        hintText: Utils.getString(context, txt_hint_text_transport),
        forceError: _forceErrorTransport,
        onSubmit: (value) {

        },
        onChange: (changeValue) {
          if (_genRow['transport']['allowNull'] != 'True') {
            setState(() {
              _forceErrorTransport = _transportEdtController.text.trimRight().isEmpty;
            });
          }
        });
  }

  Widget _iconTime() {
    return Container(
      height: Utils.resizeHeightUtil(context, 140) + 4,
      child: Column(
        children: <Widget>[
          _iconCircleTime(),
          Expanded(
            child: Container(
              width: 2,
              color: button_color,
            ),
          ),
          _iconCircleTime()
        ],
      ),
    );
  }

  Widget _iconCircleTime() {
    return Container(
      width: Utils.resizeWidthUtil(context, 23),
      height: Utils.resizeWidthUtil(context, 23),
      decoration: BoxDecoration(
          border: Border.all(color: button_color, width: Utils.resizeWidthUtil(context, 5)),
          borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 11.4))),
    );
  }

  Widget _buildTimeOutside(BaseViewModel model) {
    return Row(
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
                  initialDate: dateTimeFormat.parse(_dateTimeStartController.text),
                  initialTime: TimeOfDay(hour: 7, minute: 30),
                  firstDate: DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day),
                  callBack: (date, time) async {
                    if (date == null || time == null) return;
                    _startWorkingTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    _dateTimeStartController.text = dateTimeFormat.format(_startWorkingTime);
                    if (_startWorkingTime.isAfter(_endWorkingTime)) {
                      var _dailyEndWorkingTime =
                          DateTime(_startWorkingTime.year, _startWorkingTime.month, _startWorkingTime.day, 17, 30);
                      var _newEndWorkingTime;
                      if (_startWorkingTime.isBefore(_dailyEndWorkingTime)) {
                        _newEndWorkingTime =
                            DateTime(_startWorkingTime.year, _startWorkingTime.month, _startWorkingTime.day, 17, 30);
                      } else {
                        _newEndWorkingTime = DateTime(
                            _startWorkingTime.year, _startWorkingTime.month, _startWorkingTime.day + 1, 17, 30);
                      }
                      _endWorkingTime = _newEndWorkingTime;
                      _dateTimeEndController.text = dateTimeFormat.format(_newEndWorkingTime);
                    }
                    await checkDouble(model);
                    getQuotaOutside(model);
                    setState(() {});
                  }),
              SizedBox(
                height: Utils.resizeHeightUtil(context, 30),
              ),
              DateTimePickerCustomModify(
                  controller: _dateTimeEndController,
                  initialDate: dateTimeFormat.parse(_dateTimeEndController.text),
                  firstDate: DateTime(_startWorkingTime.year, _startWorkingTime.month, _startWorkingTime.day),
                  initialTime: TimeOfDay(hour: 17, minute: 30),
                  callBack: (date, time) async {
                    if (DateTime(date.year, date.month, date.day, time.hour, time.minute).isBefore(_startWorkingTime)) {
                      showMessageDialog(context,
                          description: Utils.getString(context, txt_error_is_less_than_time),
                          onPress: () => Navigator.pop(context));
                      return;
                    }
                    _endWorkingTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    _dateTimeEndController.text = dateTimeFormat.format(_endWorkingTime);
                    await checkDouble(model);
                    getQuotaOutside(model);
                    setState(() {});
                  }),
            ],
          ),
        )
      ],
    );
  }
}
