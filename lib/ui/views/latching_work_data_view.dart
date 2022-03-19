import 'dart:math';

import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';

class LatchingWorkDataView extends StatefulWidget {
  final String title;

  LatchingWorkDataView(this.title);

  @override
  _LatchingWorkDataViewState createState() => _LatchingWorkDataViewState();
}

class _LatchingWorkDataViewState extends State<LatchingWorkDataView>
    with TickerProviderStateMixin {
  SlidableController slidAbleController = SlidableController();

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  ScrollController controller;

  List<dynamic> data = [];

  List<dynamic> _genRowList = [];

  List<dynamic> _shiftWorkingList = [];

  List<dynamic> _statusWorkingList = [];

  String colNameSort = 'ID';

  String typeSort = 'DESC';

  int numRow = 10;

  int nextIndex = 0;

  int totalRow = 0;

  int timeId = -1;

  int status = -1;

  int _shiftWorkingSelected = -1;

  int _statusWorkingDaySelected = -1;

  DateFormat dateFormat = DateFormat('MM/yyyy');

  DateFormat dateFormatV2 = DateFormat('dd/MM/yyyy');

  DateTime dateTimeNow = DateTime.now();

  DateTime dateTimeSelected;

  Icon iconSort = Icon(Icons.arrow_drop_down, size: 15);

  int positionDetectSpeech = 0;

  bool isOpenModal = false;

  TextEditingController _reasonErrorController = TextEditingController();

  final SpeechToText speech = SpeechToText();

  String lastWords = "";

  String lastError = "";

  String lastStatus = "";

  String _currentLocaleId = "vi_VN";

  double level = 0.0;

  double minSoundLevel = 50000;

  double maxSoundLevel = -50000;

  bool _forceErrorReason = false;

  BaseResponse _user;

  String dateWorking = '';

  bool _showLoadMore = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    _initSpeechState();
    _refreshDateTime();
    _user = context.read<BaseResponse>();
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
      _reasonErrorController.dispose();
    }
    super.dispose();
  }

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  Future<String> refreshList(BaseViewModel model) async {
    nextIndex = 0;
    timeId = -1;
    status = -1;
    dateWorking = '';
    getListData(model,
        dateWorking: dateWorking,
        nextIndex: nextIndex,
        status: status,
        timeId: timeId,
        numRow: numRow);
    return 'success';
  }

  _refreshDateTime() {
    _dateTimeStartController.value = TextEditingValue(
        text: dateFormatV2.format(dateTimeNow),
        selection: _dateTimeStartController.selection);
  }

  _scrollListener(BaseViewModel model) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      if (data.length < totalRow) {
        nextIndex += 10;
        getListData(model,
            dateWorking: dateWorking,
            nextIndex: nextIndex,
            status: status,
            timeId: timeId,
            numRow: numRow,
            isLoadMore: true);
      }
    }
  }

  void getListData(BaseViewModel model,
      {int nextIndex,
      int numRow,
      String dateWorking,
      int timeId,
      int status,
      bool isLoadMore = false}) async {
    if (!isLoadMore)
      _loading = true;
    else
      _showLoadMore = true;
    setState(() {});
    var response = await model.callApis({
      'num_row': numRow,
      'next_index': nextIndex,
      'date_working': dateWorking,
      'time_id': timeId,
      'status': status
    }, latchingWorkDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      var _data = response.data['data'];
      if (_data.length > 0) {
        setState(() {
          totalRow = int.parse(_data[0]['total_row']['v']);
          if (nextIndex == 0) {
            data.clear();
          }
          data.addAll(_data);
          _showLoadMore = false;
          _loading = false;
        });
      } else {
        setState(() {
          totalRow = 0;
          data.clear();
          data.addAll(_data);
        });
      }
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void updateData(BaseViewModel model, String dataID, int index) async {
    var encryptData =
        await Utils.encrypt("vw_tb_hrms_status_working_day_V2_chotcong");
    var response = await model.callApis(
        {'tbname': encryptData, 'dataid': dataID, 'status_ChotCong': 1},
        updateDataUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        data[index]['status_ChotCong']['v'] = '1';
        data[index]['status_ChotCong']['r'] = '1';
        data[index]['name_status']['v'] =
            Utils.getString(context, txt_latching_working_progress);
        data[index]['name_status']['r'] =
            Utils.getString(context, txt_latching_working_progress);
      });
    } else
      showMessageDialog(context, description: txt_update_failed);
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": tb_name_latching_working_data},
        getGenRowDefineUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _genRowList = response.data['data'];
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getTimeDefineFilterResponse(BaseViewModel model) async {
    List<dynamic> shiftWorkingList = [];
    var response = await model.callApis({}, getTimeDefineFilter, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var shiftWorking in response.data['data']) {
        shiftWorkingList.add({
          'id': shiftWorking['ID'],
          'name': shiftWorking['TenHienThi']['v'],
        });
      }
      setState(() {
        _shiftWorkingList = shiftWorkingList;
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getStatusWorkingDayResponse(BaseViewModel model) async {
    List<dynamic> statusWorkingDayList = [];
    var response = await model.callApis({}, getStatusWorkingDay, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var statusWorkingDay in response.data['data']) {
        statusWorkingDayList.add({
          'id': statusWorkingDay['ID'],
          'name': statusWorkingDay['name_status']['v'],
        });
      }
      setState(() {
        _statusWorkingList = statusWorkingDayList;
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void submitReportError(BaseViewModel model, String timeID, String dateWorking,
      String dataID) async {
    var encryptData =
        await Utils.encrypt('vw_tb_hrms_employee_errors_chotcong');
    var response = await model.callApis({
      'tbname': encryptData,
      'employee_id': _user.data['data'][0]['ID'],
      'content_errors': _reasonErrorController.text,
      'date_working': dateWorking,
      'time_id': timeID,
      'working_day_status_v2_id': dataID
    }, addDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_report_error_success),
          onPress: () => Navigator.pop(context));
      _reasonErrorController.text = '';
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed),
          onPress: () => Navigator.pop(context));
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
        model: BaseViewModel(),
        onModelReady: (model) {
          controller.addListener(() => _scrollListener(model));
          Future.delayed(Duration(seconds: 0), () {
            getGenRowDefine(model);
            getTimeDefineFilterResponse(model);
            getStatusWorkingDayResponse(model);
            getListData(model,
                dateWorking: dateWorking,
                nextIndex: nextIndex,
                status: status,
                timeId: timeId,
                numRow: numRow);
          });
        },
        builder: (context, model, child) => Scaffold(
              appBar: appBarCustom(context, () => Navigator.pop(context), () {
                _showBottomSheet(model, context, 'sort');
              }, widget.title, Icons.sort),
              body: _loading
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : data.length > 0
                      ? Container(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: () => refreshList(model),
                                  key: _refreshIndicatorKey,
                                  child: DraggableScrollbar.semicircle(
                                    controller: controller,
                                    labelTextBuilder: (offset) {
                                      final int currentItem =
                                          controller.hasClients
                                              ? (controller.offset /
                                                      controller.position
                                                          .maxScrollExtent *
                                                      data.length)
                                                  .floor()
                                              : 0;
                                      return Text(
                                        "${currentItem + 1}",
                                        style: TextStyle(color: Colors.white),
                                      );
                                    },
                                    heightScrollThumb:
                                        Utils.resizeHeightUtil(context, 80),
                                    backgroundColor: only_color,
                                    child: ListView.builder(
                                        physics:
                                            AlwaysScrollableScrollPhysics(),
                                        controller: controller,
                                        scrollDirection: Axis.vertical,
                                        itemCount: data.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            margin: EdgeInsets.only(
                                                top: Utils.resizeHeightUtil(
                                                    context, 20),
                                                left: Utils.resizeHeightUtil(
                                                    context, 30),
                                                right: Utils.resizeHeightUtil(
                                                    context, 30)),
                                            child: Slidable(
                                              key: Key(data[index]['ID']),
                                              controller: slidAbleController,
                                              actionPane:
                                                  SlidableDrawerActionPane(),
                                              actionExtentRatio: 0.25,
                                              enabled: num.parse(data[index]
                                                          ['status_ChotCong']
                                                      ['v']) ==
                                                  0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                    color: white_color,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                8.0))),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        Utils.resizeWidthUtil(
                                                            context, 30)),
                                                child: _rowItem(model, index),
                                              ),
                                              secondaryActions: <Widget>[
                                                num.parse(data[index][
                                                                'status_ChotCong']
                                                            ['v']) ==
                                                        1
                                                    ? SizedBox.shrink()
                                                    : _swipeButton(
                                                        only_color,
                                                        Icon(
                                                          Icons.check_circle,
                                                          color: only_color,
                                                        ),
                                                        Utils.getString(context,
                                                            txt_latching_work),
                                                        () => {
                                                              showMessageDialog(
                                                                  context,
                                                                  description: Utils
                                                                      .getString(
                                                                          context,
                                                                          txt_confirm_delete),
                                                                  onPress: () {
                                                                Navigator.pop(
                                                                    context);
                                                                updateData(
                                                                    model,
                                                                    data[index]
                                                                        ['ID'],
                                                                    index);
                                                              })
                                                            }),
                                                num.parse(data[index][
                                                                'status_ChotCong']
                                                            ['v']) ==
                                                        1
                                                    ? SizedBox.shrink()
                                                    : _swipeButton(
                                                        Colors.red,
                                                        Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                        ),
                                                        Utils.getString(context,
                                                            txt_report_error),
                                                        () {
                                                        _showBottomSheet(model,
                                                            context, 'error',
                                                            data: data[index]);
                                                      }),
                                              ],
                                            ),
                                          );
                                        }),
                                  ),
                                ),
                              ),
                              if (_showLoadMore)
                                Container(
                                  width: double.infinity,
                                  height: Utils.resizeHeightUtil(context, 100),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                            ],
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Center(
                            child: TKText(
                              Utils.getString(context, txt_non_request_data),
                              tkFont: TKFont.SFProDisplayRegular,
                              style: TextStyle(
                                  color: txt_grey_color_v1,
                                  fontSize: Utils.resizeWidthUtil(context, 34)),
                            ),
                          ),
                        ),
            ));
  }

  _showBottomSheet(BaseViewModel model, BuildContext context, String type,
          {dynamic data}) =>
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
                return _modalBottomSheet(setModalState, model, type,
                    data: data);
              })),
        ),
      );

  Widget _swipeButton(Color color, Icon icon, String title, Function onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: Utils.resizeWidthUtil(context, 120),
          height: Utils.resizeHeightUtil(context, 120),
//          decoration: BoxDecoration(
//              color: white_color,
//              shape: BoxShape.circle,
//              boxShadow: [
//                BoxShadow(
//                  color: txt_grey_color_v1.withOpacity(0.3),
//                  blurRadius: 5,
//                  offset: Offset(0, 0), // changes position of shadow
//                ),
//              ]),
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              icon,
              TKText(
                title,
                tkFont: TKFont.SFProDisplaySemiBold,
                style: TextStyle(
                    color: color, fontSize: Utils.resizeWidthUtil(context, 30)),
              )
            ],
          )),
        ),
      );

  Widget _rowItem(BaseViewModel model, int index) {
    return Container(
      padding: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
      child: _requestContent(data[index]),
    );
  }

  Widget _requestContent(dynamic data) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        TKText(
          _genRowList.length > 0
              ? '${Utils.getTitle(_genRowList, 'month_working')}: '
                  '${dateFormat.format(DateFormat('MM/dd/yyyy HH:mm:ss aaa').parse(data['month_working']['v']))}'
              : '',
          tkFont: TKFont.SFProDisplayBold,
          style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: Utils.resizeWidthUtil(context, 36),
              color: only_color),
        ),
        TKText(
          _genRowList.length > 0
              ? '${Utils.getTitle(_genRowList, 'date_working')}: '
                  '${dateFormatV2.format(DateFormat('MM/dd/yyyy HH:mm:ss aaa').parse(data['date_working']['v']))}'
              : '',
          tkFont: TKFont.SFProDisplayMedium,
          style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: Utils.resizeWidthUtil(context, 28),
              color: only_color),
        ),
        SizedBox(height: Utils.resizeHeightUtil(context, 25)),
        Row(
          children: <Widget>[
            Container(
                height: Utils.resizeWidthUtil(context, 80),
                width: Utils.resizeWidthUtil(context, 80),
                margin:
                    EdgeInsets.only(right: Utils.resizeWidthUtil(context, 30)),
                decoration: BoxDecoration(
                    color: only_color,
                    borderRadius: BorderRadius.all(Radius.circular(5.0))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    TKText(
                      data['Ca']['v'],
                      tkFont: TKFont.SFProDisplayBold,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: Utils.resizeWidthUtil(context, 20),
                          color: white_color),
                    )
                  ],
                )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TKText(
                    data['start_time_timecheck']['v'] != '' &&
                            data['end_time_timecheck']['v'] != ''
                        ? '${DateFormat.Hm().format(DateFormat('MM/dd/yyyy hh:mm:ss a').parse(data['start_time_timecheck']['v']))} '
                            '- ${DateFormat.Hm().format(DateFormat('MM/dd/yyyy hh:mm:ss a').parse(data['end_time_timecheck']['v']))}'
                        : Utils.getString(context, txt_time_check_null),
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 28),
                        color: data['start_time_timecheck']['v'] != '' &&
                                data['end_time_timecheck']['v'] != ''
                            ? txt_grey_color_v3
                            : txt_fail_color),
                  ),
                  SizedBox(height: Utils.resizeHeightUtil(context, 5)),
                  TKText(
                    _genRowList.length > 0
                        ? '${Utils.getTitle(_genRowList, 'working_factor_day')}: '
                            '${data['working_factor_day']['v']}/${data['working_factor']['v']}'
                        : '',
                    tkFont: TKFont.SFProDisplayRegular,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 24),
                        color: txt_grey_color_v3),
                  ),
                  SizedBox(height: Utils.resizeHeightUtil(context, 5)),
                ],
              ),
            ),
          ],
        ),
        _genRowList.length > 0
            ? ItemLatching(data: data, genRowList: _genRowList)
            : SizedBox.shrink(),
        SizedBox(height: Utils.resizeHeightUtil(context, 20)),
        _dashLine(),
        SizedBox(height: Utils.resizeHeightUtil(context, 20)),
        _processStatus(data),
        SizedBox(height: Utils.resizeHeightUtil(context, 20)),
      ]);

  Widget _dashLine() => Row(
        children: List.generate(
            750 ~/ 10,
            (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0 ? Colors.transparent : enable_color,
                    height: Utils.resizeHeightUtil(context, 4),
                  ),
                )),
      );

  Widget _processStatus(dynamic data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TKText(
              data['khong_in_out']['v'] != ''
                  ? data['khong_in_out']['v']
                  : data['khong_cham_cong']['v'] != ''
                      ? data['khong_cham_cong']['v']
                      : '',
              tkFont: TKFont.SFProDisplayRegular,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: Utils.resizeWidthUtil(context, 28),
                  color: txt_grey_color_v3),
            ),
            SizedBox(height: Utils.resizeHeightUtil(context, 5)),
            TKText(
              _genRowList.length > 0
                  ? '${Utils.getTitle(_genRowList, 'symbol')}: ${data['symbol']['v']}'
                  : '',
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: Utils.resizeWidthUtil(context, 28),
                  color: txt_black_color),
            )
          ],
        ),
        Container(
            padding: EdgeInsets.only(
              left: Utils.resizeWidthUtil(context, 30),
              right: Utils.resizeWidthUtil(context, 30),
              bottom: Utils.resizeHeightUtil(context, 15),
              top: Utils.resizeHeightUtil(context, 15),
            ),
            decoration: BoxDecoration(
                color: int.parse(data['status_ChotCong']['v']) == 0
                    ? txt_fail_color.withOpacity(0.12)
                    : txt_success_color.withOpacity(0.12),
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            child: TKText(data['name_status']['v'],
                tkFont: TKFont.SFProDisplayMedium,
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 28),
                    color: int.parse(data['status_ChotCong']['v']) == 0
                        ? txt_fail_color
                        : txt_success_color))),
      ],
    );
  }

  Widget _modalBottomSheet(
      StateSetter setModalState, BaseViewModel model, String type,
      {dynamic data}) {
    return Container(
      padding: EdgeInsets.only(
          left: Utils.resizeWidthUtil(context, 30),
          right: Utils.resizeWidthUtil(context, 30),
          top: Utils.resizeHeightUtil(context, 10),
          bottom: Utils.resizeHeightUtil(context, 20)),
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
                    color: txt_grey_color_v1.withOpacity(0.3),
                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
              ),
            ),
          ),
          type == 'sort'
              ? _bottomSheetSort(setModalState, model)
              : _bottomSheetError(setModalState, model, data)
        ],
      ),
    );
  }

  Widget _bottomSheetSort(StateSetter setModalState, BaseViewModel model) =>
      Column(
        children: <Widget>[
          _buildTimeOff(setModalState),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 20),
          ),
          SelectBoxCustom(
            valueKey: 'name',
            title: _shiftWorkingList.length > 0
                ? _shiftWorkingSelected != -1
                    ? _shiftWorkingList[_shiftWorkingSelected]['name']
                    : Utils.getTitle(_genRowList, 'time_id')
                : Utils.getTitle(_genRowList, 'time_id'),
            data: _shiftWorkingList,
            selectedItem: _shiftWorkingSelected,
            clearCallback: () {
              setModalState(() {
                _shiftWorkingSelected = -1;
              });
            },
            callBack: (itemSelected) {
              setModalState(() {
                if (itemSelected != null) {
                  _shiftWorkingSelected = itemSelected;
                  timeId =
                      int.parse(_shiftWorkingList[_shiftWorkingSelected]['id']);
                }
              });
            },
          ),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 20),
          ),
          SelectBoxCustom(
            valueKey: 'name',
            title: _statusWorkingList.length > 0
                ? _statusWorkingDaySelected != -1
                    ? _statusWorkingList[_statusWorkingDaySelected]['name']
                    : Utils.getTitle(_genRowList, 'status_ChotCong')
                : Utils.getTitle(_genRowList, 'status_ChotCong'),
            data: _statusWorkingList,
            selectedItem: _statusWorkingDaySelected,
            clearCallback: () {
              setModalState(() {
                _statusWorkingDaySelected = -1;
              });
            },
            callBack: (itemSelected) {
              setModalState(() {
                if (itemSelected != null) {
                  _statusWorkingDaySelected = itemSelected;
                  status = int.parse(
                      _statusWorkingList[_statusWorkingDaySelected]['id']);
                }
              });
            },
          ),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 40),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: TKButton(
                  Utils.getString(context, txt_find),
                  width: MediaQuery.of(context).size.width,
                  onPress: () {
                    Navigator.of(context).pop();
                    nextIndex = 0;
                    controller.animateTo(0.0,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                    getListData(model,
                        dateWorking: dateWorking,
                        nextIndex: nextIndex,
                        numRow: numRow,
                        timeId: timeId,
                        status: status);
                  },
                ),
              ),
              SizedBox(
                width: Utils.resizeHeightUtil(context, 20),
              ),
              Expanded(
                child: TKButton(
                  Utils.getString(context, txt_clear_find),
                  width: MediaQuery.of(context).size.width,
                  onPress: () {
                    setModalState(() {
                      _statusWorkingDaySelected = -1;
                      _shiftWorkingSelected = -1;
                      timeId = -1;
                      status = -1;
                      _refreshDateTime();
                    });
                  },
                ),
              ),
            ],
          )
        ],
      );

  Widget _bottomSheetError(
          StateSetter setModalState, BaseViewModel model, dynamic data) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: Utils.resizeHeightUtil(context, 10),
          ),
          boxTitle(context, Utils.getTitle(_genRowList, 'date_working')),
          TextFieldCustom(
              controller: TextEditingController(
                  text: dateFormatV2.format(
                      DateFormat('MM/dd/yyyy HH:mm:ss aaa')
                          .parse(data['date_working']['v']))),
              enable: false),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 10),
          ),
          boxTitle(context, Utils.getTitle(_genRowList, 'time_id')),
          TextFieldCustom(
              controller: TextEditingController(text: data['Ca']['v']),
              enable: false),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 10),
          ),
          boxTitle(context, Utils.getString(context, txt_reason_title)),
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
            Utils.getString(context, txt_report_error),
            width: double.infinity,
            onPress: () {
              if (_reasonErrorController.text.isEmpty)
                setModalState(() {
                  _forceErrorReason = true;
                });
              else {
                submitReportError(
                    model,
                    data['time_id']['v'],
                    dateFormatV2.format(DateFormat('MM/dd/yyyy HH:mm:ss aaa')
                        .parse(data['date_working']['v'])),
                    data['ID']);
                Navigator.pop(context);
              }
            },
          )
        ],
      );

  Widget _buildTimeOff(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(
            context,
            _genRowList.length > 0
                ? Utils.getTitle(_genRowList, 'date_working')
                : ''),
        DateTimePickerCustomModify(
            controller: _dateTimeStartController,
            isShowDateOnly: true,
            initialDate: dateFormatV2.parse(_dateTimeStartController.text),
            firstDate: DateTime(2020),
            callBack: (date, time) {
              if (date == null) return;
              setModalState(() {
                _dateTimeStartController.text = dateFormatV2.format(date);
                dateWorking = dateFormatV2.format(date);
              });
            })
      ],
    );
  }
}

class ItemLatching extends StatefulWidget {
  final dynamic data;
  final List<dynamic> genRowList;

  ItemLatching({this.data, this.genRowList});

  @override
  _ItemLatchingState createState() => _ItemLatchingState();
}

class _ItemLatchingState extends State<ItemLatching>
    with TickerProviderStateMixin {
  bool _isShowDetail = false;

  AnimationController expandController;

  Animation<double> animation;

  DateFormat _timeFormat = DateFormat('HH:mm');

  DateFormat _timeFormatDefault = DateFormat('MM/dd/yyyy HH:mm:ss aaa');

  @override
  void initState() {
    super.initState();
    _prepareAnimations();
  }

  void _runExpand() {
    if (_isShowDetail) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  void _prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: Utils.resizeWidthUtil(context, 110)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isShowDetail = !_isShowDetail;
                  });
                  _runExpand();
                },
                child: TKText(
                  !_isShowDetail ? 'Xem thêm...' : 'Thu gọn',
                  tkFont: TKFont.SFProDisplaySemiBold,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: Utils.resizeWidthUtil(context, 24),
                      color: only_color),
                ),
              ),
              SizedBox(
                height: Utils.resizeHeightUtil(context, 10),
              ),
              SizeTransition(
                axisAlignment: 1.0,
                sizeFactor: animation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'start_time_define'),
                        widget.data['start_time_define']['v'] != ''
                            ? _timeFormat.format(_timeFormatDefault
                                .parse(widget.data['start_time_define']['v']))
                            : ''),
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'end_time_define'),
                        widget.data['end_time_define']['v'] != ''
                            ? _timeFormat.format(_timeFormatDefault
                                .parse(widget.data['end_time_define']['v']))
                            : ''),
                    _rowItem(
                        Utils.getTitle(
                            widget.genRowList, 'start_time_timecheck'),
                        widget.data['start_time_timecheck']['v'] != ''
                            ? _timeFormat.format(_timeFormatDefault.parse(
                                widget.data['start_time_timecheck']['v']))
                            : ''),
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'end_time_timecheck'),
                        widget.data['end_time_timecheck']['v'] != ''
                            ? _timeFormat.format(_timeFormatDefault
                                .parse(widget.data['end_time_timecheck']['v']))
                            : ''),
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'so_phut_di_tre'),
                        widget.data['so_phut_di_tre']['v']),
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'so_phut_ve_som'),
                        widget.data['so_phut_ve_som']['v']),
                    _rowItem(Utils.getTitle(widget.genRowList, 'khong_in_out'),
                        widget.data['khong_in_out']['v']),
                    _rowItem(
                        Utils.getTitle(widget.genRowList, 'khong_cham_cong'),
                        widget.data['khong_cham_cong']['v']),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _rowItem(String title, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TKText(
            title,
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(
              color: txt_grey_color_v1,
              fontSize: Utils.resizeWidthUtil(context, 24),
            ),
          ),
          TKText(
            value,
            tkFont: TKFont.SFProDisplaySemiBold,
            style: TextStyle(
              color: txt_grey_color_v2,
              fontSize: Utils.resizeWidthUtil(context, 24),
            ),
          ),
        ],
      );
}
