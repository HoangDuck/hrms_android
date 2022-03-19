import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

DateFormat dateFormat = DateFormat('HH:mm dd/MM/yyyy');
DateFormat defaultFormat = DateFormat('MM/dd/yyyy HH:mm:ss aaa');
DateFormat timeFormat = DateFormat('HH:mm');

class RequestDataDetailView extends StatefulWidget {
  final dynamic data;
  final String tabName;
  final String tbName;
  final int permission;
  final dynamic status;

  RequestDataDetailView(
      {this.data, this.tabName, this.tbName, this.permission, this.status});

  @override
  _RequestDataDetailViewState createState() => _RequestDataDetailViewState();
}

class _RequestDataDetailViewState extends State<RequestDataDetailView> {
  List<dynamic> _listData = [];

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

  List<dynamic> listLocation = [];

  @override
  void initState() {
    super.initState();
    _initSpeechState();
    if (widget.data['PathGPS'] != null)
      listLocation = jsonDecode('[${widget.data['PathGPS']['v']}]');
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

  _getDataDetail(BaseViewModel model) async {
    var response = await model.callApis({
      "ID": widget.permission == 1
          ? widget.data['request_id']['v']
          : widget.data['ID'],
      "table_name": widget.tbName
    }, getRequestDataDetailUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _listData = response.data['data'][0]['ChiTietDon']['r']
            .substring(
                0, response.data['data'][0]['ChiTietDon']['r'].length - 1)
            .split('&');
      });
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  _convertListProgress(dynamic list) {
    List<String> _process;
    if (list['ThongTinDuyetDon']['r'] != '') {
      var statusCheckFirst = list['ThongTinDuyetDon']['r']
          .substring(0, list['ThongTinDuyetDon']['r'].length - 1)
          .split('&')
          .where((i) => i.split('#')[2] != '2' && i.split('#')[2] != '1')
          .toList();
      if (statusCheckFirst.length > 0) {
        _process = statusCheckFirst.last.split('#');
      } else {
        var statusCheckSecond = list['ThongTinDuyetDon']['r']
            .substring(0, list['ThongTinDuyetDon']['r'].length - 1)
            .split('&')
            .where((i) => i.split('#')[2] == '2')
            .toList();
        if (statusCheckSecond.length == 0) {
          _process = list['ThongTinDuyetDon']['r']
              .split('&')[list['ThongTinDuyetDon']['r'].split('&').length - 2]
              .split('#');
        } else
          _process = statusCheckSecond[0].split('#');
      }
    } else
      _process = [];

    return _process;
  }

  Future<void> approveApplicationCall(BaseViewModel model,
      {int rowId = 0, String nodeStepDetail = '', int isAccept = 0}) async {
    showLoadingDialog(context);
    String tbNameEncrypt = await Utils.encrypt(tb_name_approve_application);
    var response = await model.callApis({
      'tbname': tbNameEncrypt,
      'idrow': rowId,
      'isaccept': isAccept,
      'nodeStepDetail': nodeStepDetail
    }, approveApplicationUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      showMessageDialogIOS(context,
          description: response.data['data'][0]['result'], onPress: () {
        Navigator.popUntil(
            context, ModalRoute.withName(Routers.requestOwnerData));
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.data['PathGPS'] != null &&
            listLocation != jsonDecode('[${widget.data['PathGPS']['v']}]'))
          Navigator.pop(context, true);
        else
          Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: bg_view_color,
        extendBodyBehindAppBar: true,
        appBar: appBarCustom(context, () {
          if (widget.data['PathGPS'] != null &&
              jsonEncode(listLocation) !=
                  jsonEncode(jsonDecode('[${widget.data['PathGPS']['v']}]')))
            Navigator.pop(context, true);
          else
            Navigator.pop(context, false);
        }, () => {}, Utils.getString(context, txt_request_detail), null,
            hideBackground: true),
        body: BaseView<BaseViewModel>(
            model: BaseViewModel(),
            builder: (context, model, child) {
              return Stack(
                children: <Widget>[
                  _background(),
                  _content(model),
                ],
              );
            }),
      ),
    );
  }

  Widget _background() => Container(
        height: Utils.resizeHeightUtil(context, 246),
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomCenter,
                colors: [gradient_end_color, gradient_start_color])),
      );

  Widget _content(BaseViewModel model) => SafeArea(
        child: Container(
            child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  height: Utils.resizeHeightUtil(context, 116),
                ),
                Container(
                  height: Utils.resizeHeightUtil(context, 210),
                  color: bg_view_color,
                ),
              ],
            ),
            Container(
              height: widget.permission == 1 && widget.status['id'] == '2'
                  ? MediaQuery.of(context).size.height -
                      Utils.resizeHeightUtil(context, 320)
                  : null,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    _info(),
                    widget.permission == 1
                        ? SizedBox.shrink()
                        : _contentResult(),
                    Container(
                      height: Utils.resizeHeightUtil(context, 20),
                      color: bg_view_color,
                    ),
                    _contentDetail(),
                    _reportError(),
                  ],
                ),
              ),
            ),
            widget.permission == 1
                ? widget.status['id'] == '2'
                    ? _buttonBottom(model)
                    : SizedBox.shrink()
                : SizedBox.shrink(),
          ],
        )),
      );

  Widget _info() => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Hero(
              tag: 'info${widget.data}',
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.only(
                      bottom: Utils.resizeHeightUtil(context, 30),
                      left: Utils.resizeWidthUtil(context, 30),
                      right: Utils.resizeWidthUtil(context, 30)),
                  padding: EdgeInsets.only(
                      bottom: Utils.resizeHeightUtil(context, 20),
                      top: Utils.resizeWidthUtil(context, 30),
                      left: Utils.resizeWidthUtil(context, 30),
                      right: Utils.resizeWidthUtil(context, 30)),
                  decoration: BoxDecoration(
                      color: white_color,
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      boxShadow: [
                        BoxShadow(
                          color: txt_grey_color_v1.withOpacity(0.3),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ]),
                  child: Column(
                    children: <Widget>[
                      _userInfo(widget.permission == 0
                          ? context.read<BaseResponse>().data['data'][0]
                          : widget.data),
                      _dashLine(),
                      SizedBox(height: Utils.resizeHeightUtil(context, 14)),
                      widget.permission == 1
                          ? _processStatusOwner()
                          : _processStatus(_convertListProgress(widget.data))
                    ],
                  ),
                ),
              )),
        ],
      );

  Widget _processStatusOwner() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TKText(
          widget.data['completedate']['v'] != ''
              ? DateFormat('HH:mm dd/MM/yyyy').format(
                  DateFormat('MM/dd/yyyy HH:mm:ss a')
                      .parse(widget.data['completedate']['v']))
              : '',
          tkFont: TKFont.SFProDisplayRegular,
          style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: Utils.resizeWidthUtil(context, 24),
              color: txt_grey_color_v4),
        ),
        Container(
            padding: EdgeInsets.only(
              left: Utils.resizeWidthUtil(context, 30),
              right: Utils.resizeWidthUtil(context, 30),
              bottom: Utils.resizeHeightUtil(context, 15),
              top: Utils.resizeHeightUtil(context, 15),
            ),
            decoration: BoxDecoration(
                color:
                    Color(int.parse(widget.status['color'])).withOpacity(0.12),
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            child: TKText(
              widget.status['name'],
              tkFont: TKFont.SFProDisplayMedium,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: Utils.resizeWidthUtil(context, 28),
                  color: Color(int.parse(widget.status['color']))),
            )),
      ],
    );
  }

  Widget _userInfo(dynamic data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: Utils.resizeWidthUtil(context, 160),
          height: Utils.resizeWidthUtil(context, 160),
          padding: EdgeInsets.only(
              right: Utils.resizeWidthUtil(context, 30),
              bottom: Utils.resizeWidthUtil(context, 30)),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
            child: FadeInImage.assetNetwork(
                fit: BoxFit.cover,
                placeholder: avatar_default,
                image: '$avatarUrl${data['avatar']['v'].toString()}'),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TKText(
                widget.permission == 0
                    ? data['full_name']['r'] + ' (' + data['emp_id']['r'] + ')'
                    : '${data['employee_id']['r'].toString()}',
                tkFont: TKFont.SFProDisplayBold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 32),
                    color: txt_grey_color_v2),
              ),
              SizedBox(height: Utils.resizeHeightUtil(context, 7)),
              TKText(
                widget.permission == 0
                    ? '${data['name_role']['r'].toString()}' +
                        ' (' +
                        '${data['id_role']['r'].toString()}' +
                        ')'
                    : '${data['role_id']['r'].toString()}',
                tkFont: TKFont.SFProDisplayRegular,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 28),
                    color: txt_grey_color_v1),
              ),
              SizedBox(height: Utils.resizeHeightUtil(context, 7)),
              TKText(
                widget.permission == 0
                    ? '${data['name_department']['r'].toString()}' +
                        ' (' +
                        '${data['id_department']['r'].toString()}' +
                        ')'
                    : Utils.getString(context, txt_department_name) +
                        ': '
                            '${data['org_id']['r'].toString()}',
                tkFont: TKFont.SFProDisplayRegular,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 28),
                    color: txt_grey_color_v1),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _processStatus(dynamic data) {
    return data.length > 0
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TKText(
                    data[2] != '2' && data[2] != '3' ? data[4] : '',
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 24),
                        color: txt_grey_color_v4),
                  ),
                  Row(
                    children: <Widget>[
                      TKText(
                        data.length == 0
                            ? ''
                            : '${Utils.getString(context, txt_by)} ',
                        tkFont: TKFont.SFProDisplayMedium,
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: Utils.resizeWidthUtil(context, 26),
                            color: txt_grey_color_v4),
                      ),
                      TKText(
                        data.length == 0 ? '' : data[1],
                        tkFont: TKFont.SFProDisplayMedium,
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: Utils.resizeWidthUtil(context, 26),
                            color: txt_grey_color_v3),
                      ),
                    ],
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
                      color: Color(int.parse(data.last)).withOpacity(0.12),
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: TKText(
                    data.length == 0 ? widget.data['trang_thai']['r'] : data[3],
                    tkFont: TKFont.SFProDisplayMedium,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 28),
                        color: Color(int.parse(data.last))),
                  )),
            ],
          )
        : SizedBox.shrink();
  }

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

  Widget _contentDetail() => Container(
        color: white_color,
        padding: EdgeInsets.only(
            top: Utils.resizeHeightUtil(context, 25),
            left: Utils.resizeWidthUtil(context, 30),
            right: Utils.resizeWidthUtil(context, 30),
            bottom: Utils.resizeHeightUtil(context, 25)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TKText(
              'Thông tin đơn ${widget.tabName}',
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 34),
                  color: txt_grey_color_v3),
            ),
            SizedBox(height: Utils.resizeHeightUtil(context, 15)),
            widget.data['PathGPS'] != null && widget.data['PathGPS']['v'] != ''
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: listLocation.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          if (listLocation[index]['calendar_place_file'] != null)
                          if (context
                                  .read<BaseResponse>()
                                  .data['data'][0]
                                  .containsKey('OutsideCalendar_IsWorkflow') &&
                              context.read<BaseResponse>().data['data'][0]
                                      ['OutsideCalendar_IsWorkflow']['v'] ==
                                  'True')
                            Navigator.pushNamed(context, Routers.attachFile,
                                arguments: {
                                  'parent_id': listLocation[index]
                                      ['calendar_id'],
                                  'child_id': listLocation[index]
                                      ['calendar_place_id'],
                                  'address': listLocation[index]['address'],
                                  'permission': widget.permission
                                }).then((value) {
                              if (value != null)
                                setState(() {
                                  listLocation[index]['calendar_place_file'] =
                                      value.toString();
                                });
                            });
                        },
                        child: Column(
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: Utils.resizeHeightUtil(context, 30),
                                  width: Utils.resizeHeightUtil(context, 30),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: only_color),
                                  child: Center(
                                    child: TKText(
                                      (index + 1).toString(),
                                      tkFont: TKFont.SFProDisplayMedium,
                                      style: TextStyle(
                                          decoration: TextDecoration.none,
                                          fontSize: Utils.resizeWidthUtil(
                                              context, 24),
                                          color: white_color),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    width: Utils.resizeWidthUtil(context, 10)),
                                Expanded(
                                  child: TKText(
                                    listLocation[index]['address'],
                                    tkFont: TKFont.SFProDisplayMedium,
                                    style: TextStyle(
                                        decoration: TextDecoration.none,
                                        fontSize:
                                            Utils.resizeWidthUtil(context, 30),
                                        color: only_color),
                                  ),
                                ),
                                SizedBox(
                                    width: Utils.resizeWidthUtil(context, 10)),
                                if (listLocation[index]['calendar_place_file'] != null)
                                if (context
                                        .read<BaseResponse>()
                                        .data['data'][0]
                                        .containsKey(
                                            'OutsideCalendar_IsWorkflow') &&
                                    context.read<BaseResponse>().data['data'][0]
                                                ['OutsideCalendar_IsWorkflow']
                                            ['v'] ==
                                        'True')
                                  Icon(Icons.attach_file,
                                      color: txt_fail_color),
                                if (listLocation[index]['calendar_place_file'] != null)
                                TKText(
                                  listLocation[index]['calendar_place_file'],
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 24),
                                      color: txt_fail_color),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Utils.resizeHeightUtil(
                                  context,
                                  index + 1 ==
                                          jsonDecode(
                                                  '[${widget.data['PathGPS']['v']}]')
                                              .length
                                      ? 0
                                      : 20),
                            )
                          ],
                        ),
                      );
                    })
                : TKText(
                    widget.permission == 0
                        ? widget.data['name_type']['v']
                        : widget.data['request_type']['v'],
                    tkFont: TKFont.SFProDisplayBold,
                    style: TextStyle(
                        fontSize: Utils.resizeWidthUtil(context, 32),
                        color: only_color),
                  ),
            SizedBox(height: Utils.resizeHeightUtil(context, 20)),
            BaseView<BaseViewModel>(
              model: BaseViewModel(),
              onModelReady: (model) => {
                Future.delayed(Duration(seconds: 0), () {
                  _getDataDetail(model);
                })
              },
              builder: (context, model, child) => _listData.length == 0
                  ? Container(
                      height: 100,
                      width: double.infinity,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(
                          top: Utils.resizeHeightUtil(context, 20)),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _listData.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: <Widget>[
                            index == 0
                                ? SizedBox.shrink()
                                : SizedBox(
                                    height:
                                        Utils.resizeHeightUtil(context, 10)),
                             _rowItem(_listData[index].split("#")[0],
                                _listData[index].split("#")[1]),
                            SizedBox(
                                height: Utils.resizeHeightUtil(context, 10)),
                            index + 1 == _listData.length
                                ? SizedBox.shrink()
                                : Divider()
                          ],
                        );
                      }),
            )
          ],
        ),
      );

  Widget _contentResult() => Container(
        width: double.infinity,
        color: white_color,
        padding: EdgeInsets.only(
            top: Utils.resizeWidthUtil(context, 25),
            left: Utils.resizeWidthUtil(context, 30),
            right: Utils.resizeWidthUtil(context, 30),
            bottom: Utils.resizeHeightUtil(context, 25)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            TKText(
              Utils.getString(context, txt_process_result),
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 34),
                  color: txt_grey_color_v3),
            ),
            SizedBox(height: Utils.resizeHeightUtil(context, 25)),
            Stack(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: widget.data['ThongTinDuyetDon']['r']
                                .split('&')
                                .length -
                            1,
                        itemBuilder: (context, index) {
                          return Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      TKText(
                                        widget.data['ThongTinDuyetDon']['r']
                                            .split('&')[index]
                                            .split('#')[0],
                                        tkFont: TKFont.SFProDisplayRegular,
                                        style: TextStyle(
                                            fontSize: Utils.resizeWidthUtil(
                                                context, 30),
                                            color: txt_grey_color_v1),
                                      ),
                                      widget.data['ThongTinDuyetDon']['r']
                                                      .split('&')[index]
                                                      .split('#')
                                                      .toList()[2] !=
                                                  '2' &&
                                              widget.data['ThongTinDuyetDon']
                                                          ['r']
                                                      .split('&')[index]
                                                      .split('#')
                                                      .toList()[2] !=
                                                  '3'
                                          ? TKText(
                                              widget.data['ThongTinDuyetDon']
                                                      ['r']
                                                  .split('&')[index]
                                                  .split('#')[4],
                                              tkFont:
                                                  TKFont.SFProDisplayRegular,
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  fontSize:
                                                      Utils.resizeWidthUtil(
                                                          context, 25),
                                                  color: txt_grey_color_v3),
                                            )
                                          : SizedBox.shrink()
                                    ],
                                  ),
                                  SizedBox(
                                      width:
                                          Utils.resizeWidthUtil(context, 30)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: <Widget>[
                                      TKText(
                                        widget.data['ThongTinDuyetDon']['r']
                                            .split('&')[index]
                                            .split('#')[1],
                                        tkFont: TKFont.SFProDisplaySemiBold,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            fontSize: Utils.resizeWidthUtil(
                                                context, 30),
                                            color: txt_grey_color_v3),
                                      ),
                                      TKText(
                                        widget.data['ThongTinDuyetDon']['r']
                                            .split('&')[index]
                                            .split('#')[3],
                                        tkFont: TKFont.SFProDisplaySemiBold,
                                        textAlign: TextAlign.end,
                                        style: TextStyle(
                                            fontSize: Utils.resizeWidthUtil(
                                                context, 25),
                                            color: widget
                                                        .data['ThongTinDuyetDon']
                                                            ['r']
                                                        .split('&')[index]
                                                        .split('#')[2] ==
                                                    '1'
                                                ? txt_success_color
                                                : widget.data['ThongTinDuyetDon']
                                                                ['r']
                                                            .split('&')[index]
                                                            .split('#')[2] ==
                                                        '2'
                                                    ? txt_yellow
                                                    : widget.data['ThongTinDuyetDon']
                                                                    ['r']
                                                                .split('&')[index]
                                                                .split('#')[2] ==
                                                            '4'
                                                        ? txt_grey_color_v2
                                                        : txt_fail_color),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              index ==
                                      widget.data['ThongTinDuyetDon']['r']
                                              .split('&')
                                              .length -
                                          2
                                  ? SizedBox.shrink()
                                  : Divider(),
                            ],
                          );
                        }),
                  ],
                ),
                widget.data['trang_thai_duyet']['v'] == '3'
                    ? SizedBox.shrink()
                    : Container(
                        alignment: Alignment.center,
                        child: Image.asset(
                          widget.data['trang_thai_duyet']['v'] == '0'
                              ? ic_not_approved
                              : widget.data['trang_thai_duyet']['v'] == '1'
                                  ? ic_approved
                                  : widget.data['trang_thai_duyet']['v'] == '2'
                                      ? ic_wait_approval
                                      : widget.data['trang_thai_duyet']['v'] ==
                                              '4'
                                          ? ic_withdrawal_application
                                          : ic_cancel_application,
                          height: Utils.resizeHeightUtil(context, 108),
                          width: Utils.resizeWidthUtil(context, 185),
                        ),
                      )
              ],
            )
          ],
        ),
      );

  Widget _rowItem(String title, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TKText(
              title,
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  color: txt_grey_color_v1),
            ),
          ),
          SizedBox(width: Utils.resizeWidthUtil(context, 30)),
          Expanded(
              child: TKText(
            value == '' ? '...' : value.replaceAll('\\n', '\n'),
            tkFont: TKFont.SFProDisplayRegular,
            textAlign: TextAlign.end,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 30),
                color: txt_grey_color_v3),
          ))
        ],
      );

  Widget _reportError() => Container(
        height: Utils.resizeHeightUtil(context, 30),
        color: bg_view_color,
      );

  Widget _buttonBottom(BaseViewModel model) {
    return Positioned(
      bottom: 5,
      child: Container(
        decoration: BoxDecoration(color: white_color),
        padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 0.43,
              height: Utils.resizeHeightUtil(context, 100),
              child: TKButton(Utils.getString(context, txt_approve),
                  onPress: () async {
                await approveApplicationCall(model,
                    nodeStepDetail: _reasonErrorController.text,
                    rowId: int.parse(widget.data['ID']),
                    isAccept: 1);
              }),
            ),
            Container(
              width: MediaQuery.of(context).size.width * 0.43,
              height: Utils.resizeHeightUtil(context, 100),
              child: TKButton(Utils.getString(context, txt_un_approve),
                  textColor: button_color,
                  backgroundColor: enable_color, onPress: () {
                showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => SingleChildScrollView(
                          child: Container(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              decoration: BoxDecoration(
                                border: Border.all(style: BorderStyle.none),
                              ),
                              child: StatefulBuilder(
                                  builder: (context, setModalState) {
                                _stateModal = setModalState;
                                return Container(
                                  padding: EdgeInsets.only(
                                      left: Utils.resizeWidthUtil(context, 30),
                                      right: Utils.resizeWidthUtil(context, 30),
                                      top: Utils.resizeHeightUtil(context, 10),
                                      bottom:
                                          Utils.resizeHeightUtil(context, 20)),
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
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Center(
                                          child: Container(
                                            height: 5,
                                            width: Utils.resizeWidthUtil(
                                                context, 100),
                                            decoration: BoxDecoration(
                                                color: txt_grey_color_v1
                                                    .withOpacity(0.3),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(8.0))),
                                          ),
                                        ),
                                      ),
                                      _bottomSheetError(setModalState, model)
                                    ],
                                  ),
                                );
                              })),
                        ));
              }),
            )
          ],
        ),
      ),
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

  Widget _bottomSheetError(StateSetter setModalState, BaseViewModel model) =>
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
          Utils.getString(context, txt_un_approve),
          width: double.infinity,
          onPress: () async {
            if (_reasonErrorController.text.isEmpty)
              setModalState(() {
                _forceErrorReason = true;
              });
            else {
              Utils.closeKeyboard(context);
              Navigator.pop(context);
              await approveApplicationCall(model,
                  nodeStepDetail: _reasonErrorController.text,
                  rowId: int.parse(widget.data['ID']),
                  isAccept: 0);
            }
          },
        )
      ]);
}
