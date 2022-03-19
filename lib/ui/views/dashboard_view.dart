import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/compensation_register_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:table_calendar/table_calendar.dart';

final _normalStyle = TextStyle(
    color: txt_black_color,
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
    fontFamily: 'SFProDisplay-Regular');

class DashBoardView extends StatefulWidget {
  final String title;

  DashBoardView(this.title);

  @override
  _DashBoardViewState createState() => _DashBoardViewState();
}

class _DashBoardViewState extends State<DashBoardView> {
  String dateForApi;

  CalendarController _calendarController;

  DateTime _firstWeekDayStartMonth;

  DateTime _secondWeekDayStartMonth;

  DateTime _firstWeekDayEndMonth;

  DateTime _secondWeekDayEndMonth;

  String calendarTextHeader;

  DateTime dateTimeCalendar;

  DateFormat calendarFormat = DateFormat('MM/yyyy');

  DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd');

  //BaseResponse data;
  List<dynamic> data = [];
  List<dynamic> dataSalary = [];

  BaseResponse tableCalendarData;

  dynamic tableCalendarDataSymbol = {};

  FocusNode _focusNodeReason = FocusNode();

  bool isForgotIn = false;

  bool isForgotOut = false;

  dynamic _genRowList = {};

  TextEditingController _reasonController = TextEditingController();

  bool _forceErrorContent = false;

  String _startTimeDefine;

  String _endTimeDefine;

  String _timeChange = '';

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  final SpeechToText speech = SpeechToText();

  bool isOpenModal = false;

  StateSetter _state;

  List<dynamic> _symbolList = [];

  List _listTimeKeeping = [];

  String errorMessage = '';

  dynamic _timeDefineSelected;

  List<dynamic> _timeDefineList = [];
  FToast fToast;

  String congTL;
  String congTongTL;

  int maxLimit = 0;
  int minLimit = 14;
  String errorLimitMax = 'Không thể bù công vì bạn đã chọn ngày lớn hơn so với ngày làm việc hiện tại';
  String errorLimitMin = 'Không thể bù công vì bạn đã chọn quá 14 ngày so với ngày làm việc hiện tại';

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
    initSpeechState();
    dateForApi = dateTimeFormat.format(DateTime.now());
    _calendarController = CalendarController();
    dateTimeCalendar = DateTime.now();
    calendarTextHeader = calendarFormat.format(DateTime.now());
  }

  @override
  void dispose() {
    _calendarController.dispose();
    FToast().removeCustomToast();
    super.dispose();
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

  void startListening(StateSetter state) {
    _reasonController.text = '';
    lastError = "";
    speech.listen(
        onResult: (result) => resultListener(result, state: state),
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
    setState(() {});
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

  void resultListener(SpeechRecognitionResult result, {StateSetter state}) {
    debugPrint(result.recognizedWords);
    state(() {
      _reasonController.text = result.recognizedWords;
      _forceErrorContent = _reasonController.text.trimRight().isEmpty;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    setState(() {
      this.level = level;
    });
  }

  void _initValueDay() {
    if (_calendarController.visibleDays != null) {
      List<DateTime> _listDateTime = _calendarController.visibleDays;
      _firstWeekDayStartMonth = _listDateTime.first;
      _secondWeekDayStartMonth = _firstWeekDayStartMonth.add(Duration(days: 6));
      _firstWeekDayEndMonth = _listDateTime.last;
      _secondWeekDayEndMonth = _firstWeekDayEndMonth.subtract(Duration(days: 6));
    }
  }

  void getDashboard(BaseViewModel model, String date, {Function callBack}) async {
    showLoadingDialog(context);
    var dashboardResponse = await model
        .callApis({'date': date}, workingMonthUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (dashboardResponse.status.code == 200) {
      data.clear();
      if (dashboardResponse.data['data'].length > 0)
        setState(() {
          dashboardResponse.data['data'][0].forEach((k, v) {
            if (k != 'ID' &&
                k != 'ID_Slug' &&
                k != 'UserAccount_ID' &&
                k != 'colAccountID' &&
                k != 'colAccountID_Modified' &&
                k != 'colDateAdd' &&
                k != 'colDateModified' &&
                k != 'colStatus' &&
                k != 'colLog' &&
                _genRowList[k]['status'].toString() == '0') {
              if (k == 'congtong_tinhluong') congTongTL = v['r'];
              if (k == 'congchuan') congTL = v['r'];
              data.add({
                'name': _genRowList[k]['name'],
                'value': v['r'],
                'enable': _genRowList[k]['allowEdit'],
                'keyName': k,
                'dataType': _genRowList[k]['dataType'],
                'show': _genRowList[k]['show'].toString().contains('hide') ||
                        _genRowList[k]['show'].toString().contains('hidden')
                    ? false
                    : true
              });
            }
          });
        });
      callBack();
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
    }
  }

  void getTableCalendar(BaseViewModel model, String date) async {
    //DateTime dateTime = dateTimeFormat.parse(date);
    var tableCalendarResponse = await model.callApis({'month': date}, getCalendarTableDataMonthUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    //Navigator.pop(context);
    if (tableCalendarResponse.status.code == 200) {
      setState(() {
        tableCalendarData = tableCalendarResponse;
      });
      if (data.length == 0) {
        return;
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_data_null), onPress: () => Navigator.pop(context));
      }
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
    }
  }

  void getTableCalendarSymbol(BaseViewModel model, String date) async {
    var tableCalendarResponse = await model.callApis({'date': date}, getCalendarTableDataV2, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (tableCalendarResponse.status.code == 200) {
      setState(() {
        tableCalendarDataSymbol = tableCalendarResponse;
      });
      if (data.length == 0) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_data_null), onPress: () => Navigator.pop(context));
      }
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
    }
  }

  void getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_status_working_KPI_report_month_mobile"}, getGenRowDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      _genRowList = Utils.getListGenRow(response.data['data'], 'update');
      setState(() {});
    } else {
      showMessageDialogIOS(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getDataWorkingDay(BaseViewModel model) async {
    var response =
        await model.callApis({}, getDataWorkingSymbol, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      _symbolList = response.data['data'];
      setState(() {});
    } else {
      showMessageDialogIOS(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  bool checkEmpty(StateSetter modelState) {
    if (_reasonController.text.isEmpty) {
      modelState(() {
        _forceErrorContent = true;
      });
      return false;
    }
    return true;
  }

  void getTimeDefine(BaseViewModel model, String date, {SelectBoxCustomUtilState state}) async {
    List<dynamic> _list = [];
    var response = await BaseViewModel().callApis({'date': date}, timeDefineByEmployeeUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in jsonDecode(response.data['data'][0]['Column1']['v']))
        _list.add({
          'id': list['status_working_id'],
          'name': list['time_name'],
          'time_id': list['time_id'],
          'start_time_define':
              DateFormat('HH:mm').format(DateFormat('yyyy-MM-dd HH:mm').parse(list['start_time_define'])),
          'end_time_define': DateFormat('HH:mm').format(DateFormat('yyyy-MM-dd HH:mm').parse(list['end_time_define']))
        });
      _timeDefineList = _list;
      _timeDefineSelected = _timeDefineList[0];
      _state(() {
        _startTimeDefine = _timeDefineSelected['start_time_define'];
        _endTimeDefine = _timeDefineSelected['end_time_define'];
        _timeChange = _startTimeDefine;
        isForgotIn = true;
        isForgotOut = false;
      });
      getAllTimekeepingInDay(model, date);
      if (state != null) {
        state.updateDataList(_timeDefineList);
      }
      setState(() {});
    }
  }

  Future<dynamic> checkDouble(BaseViewModel model, String date) async {
    var response = await model.callApis({
      "from_time": isForgotIn ? '$_timeChange $date' : '$_startTimeDefine $date',
      "to_time": isForgotOut ? '$_timeChange $date' : '$_endTimeDefine $date',
      "time_id": _timeDefineSelected['time_id'],
      "timesheet_type": isForgotIn ? 0 : 1,
    }, checkDoubleCompensationUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (_state != null)
        _state(() {
          errorMessage = response.data['data'][0]['result']['v'];
        });
      return response.data['data'][0]['result']['v'];
    } else
      return null;
  }

  void submitData(BaseViewModel model, String date, String time, StateSetter modelState) async {
    if (checkEmpty(modelState)) {
      showLoadingDialog(context);
      var check = await checkDouble(model, date);
      if (check == "") {
        var encryptData = await Utils.encrypt("vw_tb_hrms_chamcong_add_timesheet_submit");
        var data = {
          "tbname": encryptData,
          "employee_id": context.read<BaseResponse>().data['data'][0]['ID'].toString(),
          "date_time_sheet": date,
          "timesheet_type": isForgotIn ? 0 : 1,
          "timesheet": time,
          "reason": _reasonController.text,
          "time_id": _timeDefineSelected['time_id'],
          "iscomplete": true,
          "status": 5
        };
        var submitResponse =
            await model.callApis(data, addDataUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.pop(context);
        if (submitResponse.status.code == 200) {
          Navigator.pop(context);
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_register_success), onPress: () => Navigator.pop(context));
        } else {
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_register_failed), onPress: () => Navigator.pop(context));
        }
      } else if (check == null) {
        Navigator.pop(context);
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
      } else
        Navigator.pop(context);
    }
  }

  void getAllTimekeepingInDay(BaseViewModel model, String date) async {
    var response = await model.callApis({
      "date": DateFormat('dd/MM/yyyy').format(DateFormat('yyyy/MM/dd').parse(date))
    }, allTimekeepingInDay, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (_state != null) {
        if(!mounted)
          _state(() {
            _listTimeKeeping = response.data['data'];
          });
      }
    }
  }

  getLimitCompensation(BaseViewModel model) async {
    var response =
        await model.callApis({}, limitCompensationUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      dynamic data = jsonDecode(response.data['data'][0]['LimitCompensation']['v'])[0];
      setState(() {
        maxLimit = num.parse(data['timesheet_quota_max']).abs();
        minLimit = num.parse(data['timesheet_quota_min']).abs();
        errorLimitMin = data['timesheet_notes_min'];
        errorLimitMax = data['timesheet_notes_max'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) => {
        Future.delayed(new Duration(milliseconds: 0), () {
          getDataWorkingDay(model);
          getGenRowDefine(model);
          getDashboard(model, dateForApi, callBack: () {
            getTableCalendar(model, dateForApi);
            getTableCalendarSymbol(model, dateForApi);
            getLimitCompensation(model);
          });
        })
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
          fToast.showToast(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3,
              margin: EdgeInsets.only(top: 0),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                color: Colors.grey.withOpacity(0.9),
              ),
              child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 5),
                  itemCount: _symbolList.length,
                  itemBuilder: (BuildContext ctx, int index) {
                    return TKText(
                      '${_symbolList[index]['kytu_bangcong']['v']}: ${_symbolList[index]['ten_kytu_bangcong']['v']}',
                      style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 26)),
                    );
                  }),
            ),
            gravity: ToastGravity.BOTTOM,
            toastDuration: Duration(seconds: 5),
          );
        }, widget.title, Icons.info_outline),
        body: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(color: main_background),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                _headerCalendar(context, model),
                _buildTableCalendarWithBuilders(model),
                _bodyDashboard()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCalendar(BuildContext context, BaseViewModel model) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 10)),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 2.0,
          offset: Offset(
            0,
            3,
          ),
        )
      ], color: Colors.white),
      height: Utils.resizeHeightUtil(context, 82),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          showMonthPicker(
                  context: context,
                  firstDate: DateTime(DateTime.now().year - 10, 2, 0),
                  lastDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
                  initialDate: dateTimeCalendar)
              .then((date) {
            if (date != null) {
              setState(() {
                dateForApi = dateTimeFormat.format(date);
                getDashboard(model, dateForApi, callBack: () {
                  getTableCalendar(model, dateForApi);
                  getTableCalendarSymbol(model, dateForApi);
                });
                dateTimeCalendar = date;
                calendarTextHeader = calendarFormat.format(date);
                _calendarController.setFocusedDay(date);
              });
            }
          });
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Image.asset(ic_calendar,
                    width: Utils.resizeWidthUtil(context, 40), height: Utils.resizeHeightUtil(context, 40)),
              ),
            ),
            Expanded(
                flex: 8,
                child: TKText('${Utils.getString(context, txt_month_dashboard_view)} ${calendarTextHeader.toString()}',
                    tkFont: TKFont.SFProDisplayMedium, style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 28)))),
            Expanded(
              child: Container(
                child: Image.asset(ic_arrow_down,
                    width: Utils.resizeWidthUtil(context, 8), height: Utils.resizeHeightUtil(context, 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _openModalBottom(DateTime date, BaseViewModel model) {
    List<dynamic> itemCalendar = _returnItemCell(date);
    if (itemCalendar[0]['working_factor_day']['v'] != itemCalendar[0]['working_factor']['v']) {
      getTimeDefine(model, DateFormat('yyyy/MM/dd').format(date));
      showModalBottomSheet(
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        context: context,
        builder: (context) => SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              decoration: BoxDecoration(
                border: Border.all(style: BorderStyle.none),
              ),
              child: StatefulBuilder(builder: (context, setModalState) {
                _state = setModalState;
                return _modalBottomSheet(
                    DateFormat('dd/MM/yyyy').format(date),
                    num.parse(
                      _returnItemCell(date)[0]['trang_thai_cong']['v'],
                    ),
                    setModalState,
                    model);
              })),
        ),
      );
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_enough_working_plan), onPress: () => Navigator.pop(context));
  }

  Widget _buildTableCalendarWithBuilders(BaseViewModel model) {
    return Container(
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 10)),
      padding: EdgeInsets.only(
          top: Utils.resizeHeightUtil(context, 15),
          left: Utils.resizeWidthUtil(context, 5),
          right: Utils.resizeWidthUtil(context, 5)),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        children: <Widget>[
          TableCalendar(
              rowHeight: Utils.resizeHeightUtil(context, 130),
              headerVisible: false,
              calendarController: _calendarController,
              weekendDays: const [DateTime.sunday],
              initialCalendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableGestures: AvailableGestures.none,
              onCalendarCreated: (first, last, format) => _initValueDay(),
              onVisibleDaysChanged: (first, last, format) => _initValueDay(),
              availableCalendarFormats: const {CalendarFormat.month: ''},
              calendarStyle: CalendarStyle(highlightToday: false),
              daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: txt_grey_color_v4, fontSize: Utils.resizeWidthUtil(context, 24)),
                  weekendStyle: TextStyle(color: txt_grey_color_v4, fontSize: Utils.resizeWidthUtil(context, 24)),
                  dowTextBuilder: (date, locale) => Utils().convertDate(date)),
              builders: CalendarBuilders(dayBuilder: (context, date, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().add(Duration(days: maxLimit)).toUtc().millisecondsSinceEpoch) {
                      showMessageDialogIOS(context, description: errorLimitMax, onPress: () => Navigator.pop(context));
                    } else if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().subtract(Duration(days: minLimit)).toUtc().millisecondsSinceEpoch) {
                      errorMessage = '';
                      _openModalBottom(date, model);
                    } else {
                      showMessageDialogIOS(context, description: errorLimitMin, onPress: () => Navigator.pop(context));
                    }
                  },
                  child: _itemCalendar(
                      isWeekend: false, isSelected: false, isUnavailable: false, isToday: false, date: date),
                );
              }, weekendDayBuilder: (context, date, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().add(Duration(days: maxLimit)).toUtc().millisecondsSinceEpoch) {
                      showMessageDialogIOS(context, description: errorLimitMax, onPress: () => Navigator.pop(context));
                    } else if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().subtract(Duration(days: minLimit)).toUtc().millisecondsSinceEpoch) {
                      errorMessage = '';
                      _openModalBottom(date, model);
                    } else {
                      showMessageDialogIOS(context, description: errorLimitMin, onPress: () => Navigator.pop(context));
                    }
                  },
                  child: _itemCalendar(
                      isWeekend: true, isSelected: false, isUnavailable: false, isToday: false, date: date),
                );
              }, selectedDayBuilder: (context, date, _) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().add(Duration(days: maxLimit)).toUtc().millisecondsSinceEpoch) {
                      showMessageDialogIOS(context, description: errorLimitMax, onPress: () => Navigator.pop(context));
                    } else if (date.toUtc().millisecondsSinceEpoch >
                        DateTime.now().subtract(Duration(days: minLimit)).toUtc().millisecondsSinceEpoch) {
                      errorMessage = '';
                      _openModalBottom(date, model);
                    } else {
                      showMessageDialogIOS(context, description: errorLimitMin, onPress: () => Navigator.pop(context));
                    }
                  },
                  child: _itemCalendar(
                      isWeekend: false, isSelected: true, isUnavailable: false, isToday: false, date: date),
                );
              }, todayDayBuilder: (context, date, _) {
                return _itemCalendar(
                    isWeekend: false, isSelected: false, isUnavailable: false, isToday: true, date: date);
              }, outsideDayBuilder: (context, date, _) {
                return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => debugPrint('click to unavailable2'),
                    child: _itemCalendar(
                        isWeekend: false, isSelected: false, isUnavailable: true, isToday: false, date: date));
              }, outsideWeekendDayBuilder: (context, date, _) {
                return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => debugPrint('click to unavailable3'),
                    child: _itemCalendar(
                        isWeekend: true, isSelected: false, isUnavailable: true, isToday: false, date: date));
              })),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: Utils.resizeWidthUtil(context, 30), vertical: Utils.resizeHeightUtil(context, 25)),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 7,
                  child: TKText(Utils.getString(context, txt_total_working_day),
                      tkFont: TKFont.SFProDisplayMedium,
                      style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 32), color: txt_grey_color_v3)),
                ),
                data != null && data.length > 0
                    ? TKText(congTongTL,
                        tkFont: TKFont.SFProDisplaySemiBold,
                        style: TextStyle(color: txt_color_working_day, fontSize: Utils.resizeWidthUtil(context, 40)))
                    : Container(),
                data != null && data.length > 0
                    ? TKText('  /$congTL',
                        tkFont: TKFont.SFProDisplayMedium,
                        style: TextStyle(color: txt_grey_color_v5, fontSize: Utils.resizeWidthUtil(context, 32)))
                    : Container()
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _itemCalendar({bool isWeekend, bool isSelected, bool isUnavailable, bool isToday, DateTime date}) {
    List<dynamic> itemCalendar = _returnItemCell(date);
    return Container(
        margin: EdgeInsets.only(left: 1, right: 1, bottom: 1, top: checkFirstWeek(date)),
        decoration: BoxDecoration(
            color: isWeekend
                ? bg_weekend_day
                : isSelected
                    ? bg_selected_day
                    : (itemCalendar.length > 0 && itemCalendar[0]['trang_thai_cong']['v'] == '1')
                        ? bg_fully_timekeeping
                        : bg_normal_day,
            borderRadius: checkDateEquals(date)),
        child: isUnavailable
            ? null
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Container(
                      width: Utils.resizeWidthUtil(context, 63),
                      height: Utils.resizeHeightUtil(context, 50),
                      decoration: /*isWeekend || */itemCalendar.length == 0
                          ? null
                          : BoxDecoration(
                              color: bg_kp_calendar,
                              borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 8))),
                      child: /*isWeekend || */itemCalendar.length == 0
                          ? null
                          : Center(
                              child: TKText(
                                  tableCalendarDataSymbol.data['data'][0]['NT${date.day}']['r'] != ""
                                      ? tableCalendarDataSymbol.data['data'][0]['NT${date.day}']['r']
                                      : '--',
                                  textAlign: TextAlign.center,
                                  tkFont: TKFont.SFProDisplayRegular,
                                  style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 14)))),
                    ),
                    TKText(
                      '${date.day}',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: isToday ? txt_item_today_unselected : txt_grey_color_v2),
                    ),
                  ],
                ),
              ));
  }

  Widget _bodyDashboard() {
    return Container(
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 15)),
      decoration: BoxDecoration(color: Colors.white),
      child: _genRowList.length > 0
          ? ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              itemCount: data.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return _itemBody(
                    data[index]['name'],
                    data != null
                        ? data[index]['value']
                        : Utils.getString(context, txt_waiting));
              })
          : SizedBox.shrink(),
    );
  }

  Widget _itemBody(String title, String value) {
    return Padding(
        padding: EdgeInsets.symmetric(
            vertical: Utils.resizeHeightUtil(context, 30), horizontal: Utils.resizeWidthUtil(context, 30)),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TKText(
                title,
                tkFont: TKFont.SFProDisplayRegular,
                style: TextStyle(
                    color: txt_grey_color_v6,
                    fontSize: Utils.resizeWidthUtil(context, 30)),
              ),
            ),
            TKText(
              value,
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(
                  color: txt_grey_color_v3,
                  fontSize: Utils.resizeWidthUtil(context, 30)),
            )
          ],
        ));
  }

  Widget _modalBottomSheet(String date, int status, StateSetter setModalState, BaseViewModel model) {
    return Container(
      padding: EdgeInsets.only(
          left: Utils.resizeWidthUtil(context, 30),
          right: Utils.resizeWidthUtil(context, 30),
          top: Utils.resizeHeightUtil(context, 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
          topRight: Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
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
                    color: txt_grey_color_v1.withOpacity(0.3), borderRadius: BorderRadius.all(Radius.circular(8.0))),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 22),
                ),
                Container(
                  width: double.infinity,
                  child: TKText(
                    Utils.getString(context, txt_register_compensation),
                    tkFont: TKFont.SFProDisplaySemiBold,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 36), color: txt_black_color),
                  ),
                ),
                if (errorMessage != '')
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 10),
                  ),
                if (errorMessage != '')
                  Container(
                    width: double.infinity,
                    child: TKText(
                      errorMessage.replaceAll(';', '.'),
                      tkFont: TKFont.SFProDisplayRegular,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 28), color: txt_fail_color),
                    ),
                  ),
                if (errorMessage != '')
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 10),
                  ),
                boxTitle(context, Utils.getString(context, txt_time_checking)),
                Container(
                  width: double.infinity,
                  height: Utils.resizeWidthUtil(context, 60),
                  child: _listTimeKeeping.length > 0
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: _listTimeKeeping.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 10)),
                              padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 15)),
                              decoration: BoxDecoration(color: only_color, borderRadius: BorderRadius.circular(5)),
                              child: Center(
                                child: TKText(
                                  DateFormat.Hm()
                                      .format(DateFormat('MM/dd/yyyy hh:mm:ss a')
                                          .parse(_listTimeKeeping[index]['time_check']['v']))
                                      .toString(),
                                  tkFont: TKFont.SFProDisplaySemiBold,
                                  style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 26)),
                                ),
                              ),
                            );
                          },
                        )
                      : TKText(
                          Utils.getString(context, txt_do_not_timekeeping),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30)),
                        ),
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                _buildTimeDefineAllowed(model, date, setModalState),
                boxTitle(context, Utils.getString(context, txt_compensatory_type)),
                Row(
                  children: <Widget>[
                    Expanded(
                        flex: 1,
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setModalState(() {
                                isForgotIn = true;
                                isForgotOut = false;
                                _timeChange = _startTimeDefine;
                              });
                              checkDouble(model, date);
                            },
                            child: isForgotIn
                                ? _compensatoryActive(txt_forgot_in)
                                : _compensatoryInactive(txt_forgot_in))),
                    SizedBox(
                      width: Utils.resizeWidthUtil(context, 30),
                    ),
                    Expanded(
                        flex: 1,
                        child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setModalState(() {
                                isForgotIn = false;
                                isForgotOut = true;
                                _timeChange = _endTimeDefine;
                              });
                              checkDouble(model, date);
                            },
                            child: isForgotOut
                                ? _compensatoryActive(txt_forgot_out)
                                : _compensatoryInactive(txt_forgot_out)))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(flex: 1, child: boxTitle(context, Utils.getString(context, txt_working_day))),
                    SizedBox(width: Utils.resizeHeightUtil(context, 20)),
                    Expanded(flex: 1, child: boxTitle(context, Utils.getString(context, txt_time)))
                  ],
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.only(right: Utils.resizeHeightUtil(context, 10)),
                        padding: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 20)),
                        height: Utils.resizeHeightUtil(context, 82),
                        decoration: BoxDecoration(
                            border: Border.all(color: border_text_field, width: 1),
                            borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
                        child: Row(
                          children: <Widget>[
                            Image.asset(ic_calendar,
                                color: txt_grey_color_v1,
                                width: Utils.resizeWidthUtil(context, 44),
                                height: Utils.resizeHeightUtil(context, 44)),
                            SizedBox(
                              width: Utils.resizeWidthUtil(context, 20),
                            ),
                            TKText(date,
                                tkFont: TKFont.SFProDisplayRegular,
                                style:
                                    TextStyle(color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 30))),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () async {
                          var time = await showTimePicker(
                              context: context, initialTime: TimeOfDay.fromDateTime(timeFormat.parse(_timeChange)));
                          if (time == null) return;
                          var timeCheck = DateFormat('HH:mm')
                              .parse(time.toString().replaceAll('TimeOfDay(', '').replaceAll(')', ''));
                          if (timeCheck.isBefore(DateFormat('HH:mm').parse(_startTimeDefine)) ||
                              timeCheck.isAfter(DateFormat('HH:mm').parse(_endTimeDefine))) return;
                          setModalState(() {
                            _timeChange = time.toString().replaceAll('TimeOfDay(', '').replaceAll(')', '');
                          });
                          checkDouble(model, date);
                        },
                        child: Container(
                          margin: EdgeInsets.only(left: Utils.resizeHeightUtil(context, 10)),
                          padding: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 20)),
                          height: Utils.resizeHeightUtil(context, 82),
                          decoration: BoxDecoration(
                              border: Border.all(color: border_text_field, width: 1),
                              borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.access_time,
                                color: only_color,
                              ),
                              SizedBox(
                                width: Utils.resizeWidthUtil(context, 20),
                              ),
                              TKText(_timeChange,
                                  tkFont: TKFont.SFProDisplayRegular,
                                  style: TextStyle(
                                      color: txt_grey_color_v3, fontSize: Utils.resizeWidthUtil(context, 30))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                boxTitle(context, Utils.getString(context, txt_reason_compensatory)),
                TextFieldCustom(
                    onSpeechPress: () {
                      isOpenModal = true;
                      startListening(setModalState);
                      Future.delayed(Duration(seconds: 5), () {
                        isOpenModal = false;
                        _forceErrorContent = _reasonController.text.trimRight().isEmpty;
                        Navigator.pop(context);
                      });
                    },
                    controller: _reasonController,
                    forceError: _forceErrorContent,
                    expandMultiLine: true,
                    onChange: (changeValue) {
                      setModalState(() {
                        _forceErrorContent = _reasonController.text.trimRight().isEmpty;
                      });
                    }),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                TKButton(Utils.getString(context, txt_button_send_compensatory),
                    width: Utils.resizeWidthUtil(context, 690), onPress: () {
                  _forceErrorContent = _reasonController.text.trimRight().isEmpty;
                  _focusNodeReason.unfocus();
                  Utils.closeKeyboard(context);
                  submitData(model, date, _timeChange, setModalState);
                }),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeDefineAllowed(BaseViewModel model, String date, StateSetter stateSetter) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          TKText(Utils.getString(context, txt_time_define), style: _normalStyle),
          SizedBox(width: Utils.resizeWidthUtil(context, 20)),
          Expanded(
            child: SelectBoxCustomUtil(
              title: _timeDefineSelected != null ? _timeDefineSelected['name'] : '',
              data: _timeDefineList,
              selectedItem: 0,
              enableSearch: false,
              enable: _timeDefineList.length > 1,
              initCallback: (state) {
                getTimeDefine(model, DateFormat('yyyy/MM/dd').format(DateFormat('dd/MM/yyyy').parse(date)),
                    state: state);
              },
              clearCallback: () {},
              callBack: (selected) {
                stateSetter(() {
                  _timeDefineSelected = selected;
                  _startTimeDefine = _timeDefineSelected['start_time_define'];
                  _endTimeDefine = _timeDefineSelected['end_time_define'];
                  _timeChange = _startTimeDefine;
                  isForgotIn = true;
                  isForgotOut = false;
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _compensatoryActive(String title) {
    return Container(
      height: Utils.resizeHeightUtil(context, 82),
      decoration: BoxDecoration(
          color: txt_yellow.withOpacity(0.07),
          border: Border.all(color: txt_yellow, width: 2),
          borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
      child: Stack(children: <Widget>[
        Positioned(
          left: Utils.resizeWidthUtil(context, 22),
          top: Utils.resizeHeightUtil(context, 24),
          child: Image.asset(ic_checkbox_compensatory,
              width: Utils.resizeWidthUtil(context, 34), height: Utils.resizeHeightUtil(context, 34)),
        ),
        Center(
          child: TKText(
            Utils.getString(context, title),
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(color: txt_yellow, fontSize: Utils.resizeWidthUtil(context, 30)),
          ),
        )
      ]),
    );
  }

  Widget _compensatoryInactive(String title) {
    return Container(
      height: Utils.resizeHeightUtil(context, 82),
      decoration:
          BoxDecoration(color: bg_text_field, borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
      child: DottedBorder(
          borderType: BorderType.RRect,
          color: border_text_field,
          strokeWidth: Utils.resizeWidthUtil(context, 2),
          radius: Radius.circular(Utils.resizeWidthUtil(context, 10)),
          dashPattern: [Utils.resizeWidthUtil(context, 6), Utils.resizeWidthUtil(context, 3)],
          child: Center(
            child: TKText(
              Utils.getString(context, title),
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(color: txt_grey_color_v3, fontSize: Utils.resizeWidthUtil(context, 30)),
            ),
          )),
    );
  }

  BorderRadiusGeometry checkDateEquals(DateTime date) {
    if (date == _firstWeekDayStartMonth)
      return BorderRadius.only(
        topLeft: const Radius.circular(20.0),
      );
    else if (date == _secondWeekDayStartMonth)
      return BorderRadius.only(
        topRight: const Radius.circular(20.0),
      );
    else if (date == _secondWeekDayEndMonth)
      return BorderRadius.only(
        bottomLeft: const Radius.circular(20.0),
      );
    else if (date == _firstWeekDayEndMonth)
      return BorderRadius.only(
        bottomRight: const Radius.circular(20.0),
      );
    else
      return BorderRadius.all(Radius.circular(0.0));
  }

  List<dynamic> _returnItemCell(DateTime date) {
    List<dynamic> itemCalendar = [];
    if (tableCalendarData != null && tableCalendarData.data['data'].length > 0) {
      itemCalendar = List<dynamic>.from(tableCalendarData.data['data'].where((value) {
        return value['date_working']['r'] == DateFormat('dd/MM/yyyy').format(date).toString();
      }));
      return itemCalendar;
    }
    return [];
  }

  double checkFirstWeek(DateTime date) {
    if (date.difference(_firstWeekDayStartMonth).inDays <= 6)
      return 10.0;
    else
      return 1.0;
  }
}
