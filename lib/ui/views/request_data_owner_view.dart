import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/item_approval_application.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/bottom_sheet_voice.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class RequestDataOwnerView extends StatefulWidget {
  final dynamic data;

  RequestDataOwnerView(this.data);

  @override
  _RequestDataOwnerViewState createState() => _RequestDataOwnerViewState();
}

class _RequestDataOwnerViewState extends State<RequestDataOwnerView> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateFormat dateFormatAPI = DateFormat('yyyy/MM/dd HH:mm');

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  ScrollController controller;

  ScrollController quicklyFilterController;

  List<dynamic> _listData = [];

  List<dynamic> _genRowList = [];

  List<dynamic> _typeOffList = [];

  List<dynamic> _assignerList = [];

  dynamic _userSortSelected;

  List<dynamic> _statusProgressList = [
    {'id': '-1', 'name': 'Tất cả', 'color': '0xFF107EDD'}
  ];

  int _statusProgressSelected = 0;

  int _requestTypeSelected = -1;

  String searchText = '';

  String searchTextUserSort = '';

  int processStatus;

  int currentIndex = 0;

  int nextIndexSelected = 0;

  int nextIndexSelectedUserSort = 0;

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  DateTime dateTimeNow = DateTime.now();

  IconData iconCheckAll = Icons.check_box_outline_blank;

  var stateSelectAssign, stateSelectUserSort, stateSelectTypeOff;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  bool _isShowAction = false;

  AnimationController expandController;

  Animation<double> animation;

  int totalCheck = 0;

  String filter = '';
  String filterQuickStatus = '';

  bool checkAll = false;

  GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<dynamic> _listRequestType = [];

  bool _timeChecked = false;

  int totalRow;

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

  bool _isClickUnApprove = false;

  List<dynamic> pendingApproval = [];

  bool _showLoadMore = false;

  bool _loading = false;

  bool _statusLoading = false;

  var _userProfile;

  @override
  void initState() {
    super.initState();
    _initUserProfile();
    controller = ScrollController();
    quicklyFilterController = ScrollController();
    _prepareAnimations();
    _initSpeechState();
  }

  @override
  void dispose() {
    if (!mounted) {
      controller.dispose();
      _reasonErrorController.dispose();
      _dateTimeStartController.dispose();
      _dateTimeEndController.dispose();
      expandController.dispose();
    }
    super.dispose();
  }

  Future<void> _initSpeechState() async {
    bool hasSpeech = await speech.initialize(onError: errorListener, onStatus: statusListener);
    if (hasSpeech) {
      var systemLocale = await speech.systemLocale();
      debugPrint(systemLocale.localeId);
    }

    if (!mounted) return;
  }

  void _initUserProfile() async {
    _userProfile = await SecureStorage().userProfile;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDateTime();
  }

  void _prepareAnimations() {
    expandController = AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  void _runExpand() {
    if (_isShowAction) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  _refreshDateTime() {
    _dateTimeStartController.value =
        TextEditingValue(text: Utils.getString(context, txt_from), selection: _dateTimeStartController.selection);

    _dateTimeEndController.value =
        TextEditingValue(text: Utils.getString(context, txt_to), selection: _dateTimeEndController.selection);

    _startWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));

    _endWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));
  }

  Future<String> refreshList(BaseViewModel model) async {
    currentIndex = 0;
    _listData.clear();
    setState(() {
      _listKey = GlobalKey();
    });
    totalCheck = 0;
    checkAll = false;
    _isShowAction = false;
    _runExpand();
    getListData(model, currentIndex);
    getTotalQuicklyStatus(model, reload: true);
    return 'success';
  }

  _scrollListener(BaseViewModel model) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      if (_listData.length < totalRow) {
        currentIndex += 10;
        getListData(model, currentIndex, isLoadMore: true);
      }
    }
  }

  // ThongSo = tbName=vw_tb_hrms_nghiphep_absent_history_submit_mobile&tbNameDetail=vw_tb_hrms_nghiphep_absent_history_submit_mobile_detail
  getListData(BaseViewModel model, int currentIndex, {bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _loading = true;
      });
    } else
      setState(() {
        _showLoadMore = true;
      });
    var response = await model.callApis({
      "current_index": currentIndex,
      "next_index": 10,
      "filter_progress": filter + filterQuickStatus
    }, getListDataRequestOwnerUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        if (checkAll) {
          response.data['data'].forEach((f) {
            f['is_checked']['v'] = '1';
          });
          _listData.addAll(response.data['data']);
          totalCheck = _listData.length;
        } else {
          _listData.addAll(response.data['data']);
        }

        if (_listData.length > 0) {
          for (int i = _listData.length - response.data['data'].length; i < _listData.length; i++) {
            if (_listKey.currentState != null) _listKey.currentState.insertItem(i);
          }
        } else {
          for (int i = 0; i < response.data['data'].length; i++) {
            _listKey.currentState.insertItem(i);
          }
        }
        _showLoadMore = false;
        _loading = false;
      });
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getTotalRow(BaseViewModel model) async {
    var response = await model.callApis({"filter_progress": filter}, getTotalRowRequestOwnerUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        totalRow = int.parse(response.data['data'][0]['total_row']['v']);
      });
      print(totalRow);
    } else {
      debugPrint('error');
    }
  }

  Future<void> getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {"TbName": 'vw_tb_hrms_workflow_steps_detail_approve_all'}, getGenRowDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      setState(() {
        _genRowList = response.data['data'];
      });
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getAbsentType(BaseViewModel model,
      {String searchText = '',
      Function callback,
      int nextIndex = 0,
      StateSetter stateModal,
      SelectBoxCustomUtilState state}) async {
    var typeOffList = List<dynamic>();
    var data = {'search_text': searchText, 'next_index': nextIndex, 'num_row': 10};
    var response =
        await model.callApis(data, absentTypeUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var type in response.data['data']) {
        typeOffList.add({'id': type['ID'], 'name': type['name_absent']['v'], 'total_row': type['total_row']['v']});
      }
      _typeOffList.addAll(typeOffList);
      if (state != null) {
        state.updateDataList(_typeOffList);
      }
      if (stateModal != null) stateModal(() {});
      if (callback != null) {
        callback();
      }
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
    }
  }

  void getAssigner(BaseViewModel model,
      {String searchText = '', int nextIndex = 0, StateSetter stateModal, SelectBoxCustomUtilState state}) async {
    List<dynamic> assignerList = [];
    var data = {'search_text': searchText, 'next_index': nextIndex, 'num_row': 10};
    var response =
        await model.callApis(data, allUserUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
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
      if (stateModal != null) stateModal(() {});
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed), onPress: () => Navigator.pop(context));
    }
  }

  void getProgressStatus(BaseViewModel model, {Function callback}) async {
    List<dynamic> statusProgressList = [];
    var response =
        await model.callApis({}, getStatusProgress, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var statusProgress in response.data['data']) {
        statusProgressList.add({
          'id': statusProgress['ID'],
          'name': statusProgress['Name']['v'],
          'color': statusProgress['css_style_text_MobileApp']['v']
        });
      }
      _statusProgressList.addAll(statusProgressList);
      if (callback != null) {
        callback();
      }
      setState(() {});
    } else {
      showMessageDialog(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void callCheck(int index) {
    if (_listData[index]['is_checked']['v'] == '1') {
      _listData[index]['is_checked']['v'] = '0';
    } else {
      _listData[index]['is_checked']['v'] = '1';
    }
    List<dynamic> list = _listData.where((f) => f['is_checked']['v'] == '1').toList();
    if (list.length != 0 && list.length < _listData.length) {
      iconCheckAll = Icons.check_box_outline_blank;
      _isShowAction = true;
      checkAll = false;
      totalCheck = list.length;
    } else if (list.length == 0) {
      _isShowAction = false;
    } else {
      checkAll = true;
      iconCheckAll = Icons.check_box;
      _isShowAction = true;
      totalCheck = list.length;
    }
  }

  void _getRequestType(BaseViewModel model) async {
    List<dynamic> requestType = [];
    var response =
        await model.callApis({}, requestTypeUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        requestType.add({
          'id': list['ID'],
          'name': list['name']['v'],
        });
      }
      setState(() {
        _listRequestType = requestType;
      });
    } else
      showMessageDialogIOS(context, description: Utils.getString(context, txt_get_data_failed));
  }

  Future<void> approveApplicationCall(BaseViewModel model,
      {int rowId = 0, String nodeStepDetail = '', int isAccept = 0, bool isCheckAll = false}) async {
    String tbNameEncrypt = await Utils.encrypt(tb_name_approve_application);
    var response = await model.callApis({
      'tbname': tbNameEncrypt,
      'idrow': rowId,
      'isaccept': isAccept,
      'nodeStepDetail': nodeStepDetail
    }, approveApplicationUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (!isCheckAll) {
        if (pendingApproval.length > 0) pendingApproval.removeAt(0);
      }
    } else {
      showMessageDialogIOS(context, description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getTotalQuicklyStatus(BaseViewModel model, {bool reload = false}) async {
    for (int i = 0; i < _statusProgressList.length; i++) {
      var response = await model.callApis({
        'filter': _statusProgressList[i]['id'] == '-1'
            ? '1 = 1' + filter
            : 'trang_thai_duyet = ${_statusProgressList[i]['id']}' + filter
      }, totalRequestWithStatus, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
      if (response.status.code == 200) {
        if (!reload)
          _statusProgressList[i] = {
            ..._statusProgressList[i],
            ...{'total': int.parse(response.data['data'][0]['total']['v'])}
          };
        else
          _statusProgressList[i]['total'] = int.parse(response.data['data'][0]['total']['v']);
      } else {
        if (!reload)
          _statusProgressList[i] = {
            ..._statusProgressList[i],
            ...{'total': 0}
          };
        else
          _statusProgressList[i]['total'] = 0;
      }
    }
    setState(() {
      _statusLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
        model: BaseViewModel(),
        onModelReady: (model) {
          controller.addListener(() => _scrollListener(model));
          Future.delayed(Duration(seconds: 0), () {
            getProgressStatus(model, callback: () {
              getTotalQuicklyStatus(model);
            });
            _getRequestType(model);
            getListData(model, currentIndex);
            getTotalRow(model);
          });
        },
        builder: (context, model, child) => Stack(
              children: <Widget>[
                Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: bg_view_color,
                    appBar: appBarCustom(context, () async {
                      if (pendingApproval.length > 0) {
                        await approveApplicationCall(model,
                            nodeStepDetail: pendingApproval[0]['nodeStepDetail'],
                            rowId: int.parse(pendingApproval[0]['id']),
                            isAccept: pendingApproval[0]['isAccept']);
                      }
                      Navigator.pop(context);
                    }, () {
                      getGenRowDefine(model).then((value) {
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
                                  return _modalBottomSheet(setModalState, model);
                                })),
                          ),
                        );
                      });
                    }, widget.data['title'], Icons.sort),
                    body: Column(
                      children: <Widget>[
                        Visibility(
                          visible: _statusLoading,
                          child: Container(
                            padding: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 30)),
                            margin: EdgeInsets.only(top: Utils.resizeWidthUtil(context, 20)),
                            height: 25,
                            child: ListView.builder(
                                controller: quicklyFilterController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _statusProgressList.length,
                                itemBuilder: (context, index) {
                                  if (_statusProgressList[index]['total'] == 0)
                                    return SizedBox.shrink();
                                  else
                                    return GestureDetector(
                                      onTap: () {
                                        if (index == 0)
                                          filterQuickStatus = '';
                                        else
                                          filterQuickStatus =
                                              ' AND trang_thai_duyet = ${_statusProgressList[index]['id']}';
                                        _statusProgressSelected = index;
                                        refreshList(model);
                                        getTotalRow(model);
                                      },
                                      child: _statusChooseQuicklyItem(
                                          _statusProgressList[index], index == _statusProgressSelected ? true : false),
                                    );
                                }),
                          ),
                        ),
                        Expanded(
                          child: _loading
                              ? Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _listData.length > 0
                                  ? mainContent(model)
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context).size.height,
                                      child: Center(
                                        child: TKText(
                                          Utils.getString(context, txt_non_request_data),
                                          tkFont: TKFont.SFProDisplayRegular,
                                          style: TextStyle(
                                              color: txt_grey_color_v1, fontSize: Utils.resizeWidthUtil(context, 34)),
                                        ),
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
                    )),
                SizeTransition(
                    axis: Axis.horizontal,
                    axisAlignment: 1.0,
                    sizeFactor: animation,
                    child: SafeArea(
                      child: Container(
                        height: AppBar().preferredSize.height,
                        width: double.infinity,
                        color: white_color,
                        padding: EdgeInsets.only(
                            left: Utils.resizeWidthUtil(context, 10), right: Utils.resizeWidthUtil(context, 30)),
                        child: Row(
                          children: <Widget>[
                            GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  setState(() {
                                    _listData.forEach((f) {
                                      setState(() {
                                        f['is_checked']['v'] = '0';
                                      });
                                    });
                                    _isShowAction = false;
                                    checkAll = false;
                                    _runExpand();
                                  });
                                },
                                child: Padding(
                                    padding: EdgeInsets.all(17),
                                    child: Image.asset(
                                      ic_back,
                                      color: txt_grey_color_v1,
                                    ))),
                            SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                            TKText(
                              totalCheck.toString(),
                              style: TextStyle(
                                  color: txt_grey_color_v1,
                                  fontSize: Utils.resizeWidthUtil(context, 32),
                                  decoration: TextDecoration.none),
                              tkFont: TKFont.SFProDisplayMedium,
                            ),
                            Expanded(
                              child: SizedBox.shrink(),
                            ),
                            GestureDetector(
                              onTap: () async {
                                showLoadingDialog(context);
                                List<dynamic> list = _listData.where((f) => f['is_checked']['v'] == '1').toList();
                                for (dynamic item in list) {
                                  await approveApplicationCall(model,
                                      rowId: int.parse(item['ID']), isAccept: 1, isCheckAll: true);
                                }
                                refreshList(model);
                                Navigator.pop(context);
                              },
                              child: TKText(
                                Utils.getString(context, txt_approve),
                                style: TextStyle(
                                    color: only_color,
                                    fontSize: Utils.resizeWidthUtil(context, 28),
                                    decoration: TextDecoration.none),
                                tkFont: TKFont.SFProDisplayMedium,
                              ),
                            ),
                            SizedBox(width: Utils.resizeWidthUtil(context, 15)),
                            TKText(
                              '|',
                              style: TextStyle(
                                  color: txt_grey_color_v1,
                                  fontSize: Utils.resizeWidthUtil(context, 32),
                                  decoration: TextDecoration.none),
                              tkFont: TKFont.SFProDisplayRegular,
                            ),
                            SizedBox(width: Utils.resizeWidthUtil(context, 15)),
                            GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    builder: (context) => SingleChildScrollView(
                                          child: Container(
                                              padding:
                                                  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                                              decoration: BoxDecoration(
                                                border: Border.all(style: BorderStyle.none),
                                              ),
                                              child: StatefulBuilder(builder: (context, setModalState) {
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
                                                      _bottomSheetError(setModalState, model)
                                                    ],
                                                  ),
                                                );
                                              })),
                                        )).then((value) async {
                                  if (_isClickUnApprove) {
                                    List<dynamic> list = _listData.where((f) => f['is_checked']['v'] == '1').toList();
                                    showLoadingDialog(context);
                                    for (dynamic item in list) {
                                      await approveApplicationCall(model,
                                          nodeStepDetail: _reasonErrorController.text,
                                          rowId: int.parse(item['ID']),
                                          isAccept: 0,
                                          isCheckAll: true);
                                    }
                                    refreshList(model);
                                    Navigator.pop(context);
                                  }
                                  _forceErrorReason = false;
                                  _reasonErrorController.text = '';
                                });
                              },
                              child: TKText(
                                Utils.getString(context, txt_un_approve),
                                style: TextStyle(
                                    color: txt_fail_color,
                                    fontSize: Utils.resizeWidthUtil(context, 28),
                                    decoration: TextDecoration.none),
                                tkFont: TKFont.SFProDisplayMedium,
                              ),
                            ),
                            SizedBox(width: Utils.resizeWidthUtil(context, 30)),
                            GestureDetector(
                                onTap: () {
                                  List<dynamic> list = _listData.where((f) => f['is_checked']['v'] == '1').toList();
                                  if (list.length == 0 || list.length < _listData.length) {
                                    _listData.forEach((f) {
                                      f['is_checked']['v'] = '1';
                                    });
                                    setState(() {
                                      totalCheck = _listData.length;
                                      checkAll = true;
                                      iconCheckAll = Icons.check_box;
                                    });
                                  } else {
                                    _listData.forEach((f) {
                                      setState(() {
                                        f['is_checked']['v'] = '0';
                                      });
                                    });
                                    _isShowAction = false;
                                    checkAll = false;
                                    _runExpand();
                                  }
                                },
                                child: Row(
                                  children: <Widget>[
                                    Icon(iconCheckAll, color: txt_grey_color_v1),
                                    SizedBox(width: Utils.resizeWidthUtil(context, 10)),
                                    TKText(
                                      Utils.getString(context, txt_all),
                                      style: TextStyle(
                                          color: txt_grey_color_v1,
                                          fontSize: Utils.resizeWidthUtil(context, 28),
                                          decoration: TextDecoration.none),
                                      tkFont: TKFont.SFProDisplayRegular,
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ))
              ],
            ));
  }

  Widget mainContent(model) => RefreshIndicator(
      onRefresh: () => refreshList(model),
      key: _refreshIndicatorKey,
      child: Scrollbar(
        child: AnimatedList(
            controller: controller,
            padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
            key: _listKey,
            initialItemCount: _listData.length,
            itemBuilder: (BuildContext context, int index, Animation animation) {
              final item = _listData[index];
              return item['trang_thai_duyet']['v'] == '2' &&
                      item['employeeID']['v']
                              .toString()
                              .split(';')
                              .where((element) => element != _userProfile.data['data'][0]['ID'])
                              .toList()
                              .length >
                          0
                  ? Dismissible(
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
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
                                                _bottomSheetError(setModalState, model)
                                              ],
                                            ),
                                          );
                                        })),
                                  )).then((value) async {
                            if (_isClickUnApprove) {
                              _scaffoldKey.currentState.hideCurrentSnackBar();
                              _isClickUnApprove = false;
                              String warning = Utils.getString(
                                  _scaffoldKey.currentState.context, txt_warning_not_approval_application);
                              pendingApproval.add(
                                  {'id': item['ID'], 'isAccept': 0, 'nodeStepDetail': _reasonErrorController.text});
                              _showSnackBar(model,
                                  context: _scaffoldKey.currentState.context,
                                  index: index,
                                  warning: warning,
                                  item: item);
                            } else {
                              _scaffoldKey.currentState.hideCurrentSnackBar();
                              setState(() {
                                _listData.insert(index, item);
                                _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 500));
                              });
                            }
                            _forceErrorReason = false;
                            _reasonErrorController.text = '';
                          });
                          _listData.removeAt(index);
                          _listKey.currentState.removeItem(index, (context, animation) {
                            return SizeTransition(
                              sizeFactor: CurvedAnimation(parent: animation, curve: Interval(0.0, 1.0)),
                              axisAlignment: 0.0,
                              child: Container(),
                            );
                          });
                          return true;
                        } else {
                          Scaffold.of(context).hideCurrentSnackBar();
                          String warning = Utils.getString(context, txt_warning_approval_application);
                          pendingApproval
                              .add({'id': item['ID'], 'isAccept': 1, 'nodeStepDetail': _reasonErrorController.text});
                          _listData.removeAt(index);
                          _listKey.currentState.removeItem(index, (context, animation) {
                            return SizeTransition(
                              sizeFactor: CurvedAnimation(parent: animation, curve: Interval(0.0, 1.0)),
                              axisAlignment: 0.0,
                              child: Container(),
                            );
                          });
                          _showSnackBar(model, context: context, index: index, warning: warning, item: item);
                          return true;
                        }
                      },
                      secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Image.asset(
                                ic_check,
                                height: Utils.resizeWidthUtil(context, 100),
                                width: Utils.resizeWidthUtil(context, 100),
                                color: txt_success_color,
                              ),
                              TKText(Utils.getString(context, txt_approve),
                                  textAlign: TextAlign.right,
                                  tkFont: TKFont.SFProDisplayBold,
                                  style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 24)))
                            ],
                          )),
                      background: Container(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Image.asset(
                                ic_reject_application,
                                height: Utils.resizeWidthUtil(context, 80),
                                width: Utils.resizeWidthUtil(context, 80),
                              ),
                              TKText(Utils.getString(context, txt_un_approve),
                                  textAlign: TextAlign.right,
                                  tkFont: TKFont.SFProDisplayBold,
                                  style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 24)))
                            ],
                          )),
                      key: UniqueKey(),
                      child: _listData.length > 0 && _statusProgressList.length > 0
                          ? ItemApprovalApplication(
                              callbackRefresh: () => refreshList(model),
                              list: _listData,
                              index: index,
                              statusSelected: _statusProgressSelected,
                              statusProgressList: _statusProgressList,
                              animation: animation,
                              clickSelected: () {
                                setState(() {
                                  callCheck(index);
                                });
                                _runExpand();
                              })
                          : Container(),
                    )
                  : _listData.length > 0 && _statusProgressList.length > 0
                      ? ItemApprovalApplication(
                          callbackRefresh: () => refreshList(model),
                          list: _listData,
                          index: index,
                          statusSelected: _statusProgressSelected,
                          statusProgressList: _statusProgressList,
                          animation: animation,
                          clickSelected: () {
                            setState(() {
                              callCheck(index);
                            });
                            _runExpand();
                          })
                      : Container();
            }),
      ));

  Widget _modalBottomSheet(StateSetter setModalState, BaseViewModel model) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: Utils.resizeHeightUtil(context, 30)),
                SelectBoxCustomUtil(
                    title: _assignerList.length > 0
                        ? _userSortSelected == null
                            ? '${Utils.getString(context, txt_choose)} nhân viên'
                            : _userSortSelected['name']
                        : '${Utils.getString(context, txt_choose)} nhân viên',
                    data: _assignerList,
                    clearCallback: () {
                      setModalState(() {
                        _userSortSelected = null;
                      });
                    },
                    initCallback: (state) {
                      stateSelectUserSort = state;
                      searchTextUserSort = '';
                      nextIndexSelectedUserSort = 0;
                      _assignerList.clear();
                      getAssigner(model, nextIndex: nextIndexSelectedUserSort, state: state, stateModal: setModalState);
                    },
                    loadMoreCallback: (state) {
                      if (_assignerList.length < int.parse(_assignerList[0]['total_row'])) {
                        nextIndexSelectedUserSort += 10;
                        getAssigner(model,
                            nextIndex: nextIndexSelectedUserSort,
                            searchText: searchTextUserSort,
                            stateModal: setModalState,
                            state: state);
                      }
                    },
                    searchCallback: (value, state) {
                      if (value != '') {
                        Future.delayed(Duration(seconds: 2), () {
                          searchTextUserSort = value;
                          nextIndexSelectedUserSort = 0;
                          _assignerList.clear();
                          getAssigner(model,
                              nextIndex: nextIndexSelectedUserSort,
                              searchText: value,
                              state: state,
                              stateModal: setModalState);
                        });
                      }
                    },
                    callBack: (itemSelected) {
                      setModalState(() {
                        print(itemSelected);
                        _userSortSelected = itemSelected;
                      });
                    }),
                _buildTime(setModalState, _genRowList.length > 0 ? Utils.getString(context, txt_time) : ''),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                _buildTitle(Utils.getString(context, txt_request_type)),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _listRequestType.length > 0
                      ? _requestTypeSelected != -1
                          ? _listRequestType[_requestTypeSelected]['name']
                          : Utils.getString(context, txt_request_type)
                      : Utils.getString(context, txt_request_type),
                  data: _listRequestType,
                  selectedItem: _requestTypeSelected,
                  clearCallback: () {
                    setModalState(() {
                      _requestTypeSelected = -1;
                    });
                  },
                  callBack: (itemSelected) {
                    setModalState(() {
                      if (itemSelected != null) {
                        print(itemSelected);
                        _requestTypeSelected = itemSelected;
                      }
                    });
                  },
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                _buildTitle(Utils.getString(context, txt_status_latching_work)),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _statusProgressList.length > 1 ? _statusProgressList[_statusProgressSelected]['name'] : '',
                  data: _statusProgressList,
                  selectedItem: _statusProgressSelected,
                  clearCallback: () {
                    setModalState(() {
                      //_statusProgressSelected = -1;
                    });
                  },
                  callBack: (itemSelected) {
                    setModalState(() {
                      if (itemSelected != null) {
                        _statusProgressSelected = itemSelected;
                      }
                    });
                  },
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 40),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_find),
                        onPress: () {
                          Navigator.of(context).pop();
                          if (_listData.length > 0)
                            controller.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
                          String requestTypeSelected = _requestTypeSelected != -1
                              ? 'AND workflow_define_type_id = ${_listRequestType[_requestTypeSelected]['id']}'
                              : '';
                          String userSelected =
                              _userSortSelected != null ? ' AND employee_id = ${_userSortSelected['id']}' : '';
                          String timeSelected = _timeChecked
                              ? ' AND from_time BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';
                          String statusProgress = _statusProgressSelected == 0
                              ? ''
                              : ' AND trang_thai_duyet = ${_statusProgressList[_statusProgressSelected]['id']}';
                          filter = statusProgress + requestTypeSelected + userSelected + timeSelected;
                          filterQuickStatus = '';
                          refreshList(model);
                          getTotalRow(model);
                          if (_listData.length > 0)
                            quicklyFilterController.animateTo(_statusProgressSelected.toDouble(),
                                duration: Duration(milliseconds: 300), curve: Curves.easeOut);
                        },
                      ),
                    ),
                    SizedBox(
                      width: Utils.resizeHeightUtil(context, 20),
                    ),
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_clear_find),
                        onPress: () {
                          setModalState(() {
                            _refreshDateTime();
                            _requestTypeSelected = -1;
                            _statusProgressSelected = 0;
                            _userSortSelected = null;
                            _timeChecked = false;
//                            for (int i = 0;
//                                i < _statusProgressList.length;
//                                i++) {
//                              if (_statusProgressList[i]['id'] == '2')
//                                _statusProgressSelected = i;
//                            }
                            if (stateSelectTypeOff != null) stateSelectTypeOff.clearData();
                            if (stateSelectUserSort != null) stateSelectUserSort.clearData();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
              ],
            ),
          ],
        ));
  }

  Widget _buildTime(StateSetter setModalState, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTitle(title),
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
                      initialDate: dateFormat.parse(dateFormat.format(_startWorkingTime)),
                      firstDate: DateTime(2020),
                      initialTime: TimeOfDay(hour: _startWorkingTime.hour, minute: _startWorkingTime.minute),
                      callBack: (date, time) {
                        if (date == null) return;
                        setModalState(() {
                          _startWorkingTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          _dateTimeStartController.text = dateFormat.format(_startWorkingTime);
                          if (_startWorkingTime.isAfter(_endWorkingTime) || _dateTimeEndController.text.length < 10) {
                            _endWorkingTime = _startWorkingTime;
                            _dateTimeEndController.text = dateFormat.format(_endWorkingTime);
                            _timeChecked = true;
                          }
                        });
                      }),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                  DateTimePickerCustomModify(
                      controller: _dateTimeEndController,
                      initialTime: TimeOfDay(hour: _endWorkingTime.hour, minute: _endWorkingTime.minute),
                      initialDate: dateFormat.parse(dateFormat.format(_endWorkingTime)),
                      firstDate: DateTime(_startWorkingTime.year, _startWorkingTime.month, _startWorkingTime.day),
                      callBack: (date, time) {
                        if (date == null) return;
                        setModalState(() {
                          _endWorkingTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          _dateTimeEndController.text = dateFormat.format(_endWorkingTime);
                          if (_dateTimeStartController.text.length < 10) {
                            _startWorkingTime = _endWorkingTime;
                            _dateTimeStartController.text = dateFormat.format(_startWorkingTime);
                            _timeChecked = true;
                          }
                        });
                      }),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Utils.resizeHeightUtil(context, 15)),
      child: TKText(
        title,
        tkFont: TKFont.SFProDisplayRegular,
        style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 32), color: txt_grey_color_v3),
      ),
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
          border: Border.all(color: button_color, width: Utils.resizeWidthUtil(context, 5)),
          borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 11.4))),
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
                _forceErrorReason = _reasonErrorController.text.trimRight().isEmpty;
              });
            }),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 20),
        ),
        TKButton(
          Utils.getString(context, txt_un_approve),
          width: double.infinity,
          onPress: () {
            if (_reasonErrorController.text.isEmpty)
              setModalState(() {
                _forceErrorReason = true;
              });
            else {
              Utils.closeKeyboard(context);
              _isClickUnApprove = true;
              Navigator.pop(context);
            }
          },
        )
      ]);

  _showSnackBar(BaseViewModel model, {int index, dynamic item, String warning, BuildContext context}) {
    Scaffold.of(context)
        .showSnackBar(SnackBar(
            duration: Duration(seconds: 2),
            content: Container(
                height: Utils.resizeHeightUtil(context, 70),
                child: Row(
                  children: <Widget>[
                    Expanded(child: TKText(warning, style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 30)))),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          Scaffold.of(context).hideCurrentSnackBar();
                          pendingApproval.clear();
                          setState(() {
                            _listData.insert(index, item);
                            _listKey.currentState.insertItem(index, duration: Duration(milliseconds: 500));
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 15)),
                          child: TKText(Utils.getString(context, txt_undo_approval_application).toUpperCase(),
                              textAlign: TextAlign.right,
                              tkFont: TKFont.SFProDisplayBold,
                              style: TextStyle(fontSize: Utils.resizeWidthUtil(context, 30))),
                        ),
                      ),
                    )
                  ],
                ))))
        .closed
        .then((value) async {
      if (pendingApproval.length > 0) {
        await approveApplicationCall(model,
            nodeStepDetail: pendingApproval[0]['nodeStepDetail'],
            rowId: int.parse(pendingApproval[0]['id']),
            isAccept: pendingApproval[0]['isAccept']);
        getTotalQuicklyStatus(model, reload: true);
      }
    });
  }

  Widget _statusChooseQuicklyItem(dynamic data, bool enable) => Container(
      padding: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 20)),
      margin: EdgeInsets.only(right: Utils.resizeWidthUtil(context, 20)),
      decoration: BoxDecoration(
        color: enable ? Color(int.parse(data['color'])) : white_color,
        borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 18)),
        border: Border.all(width: 1, color: enable ? Color(int.parse(data['color'])) : txt_grey_color_v1),
        //color: Color(int.parse(color))
      ),
      child: Center(
        child: TKText(
          '${data['name']}(${data['total'] != null ? data['total'] : '0'})',
          style: TextStyle(color: enable ? white_color : txt_grey_color_v1),
          tkFont: TKFont.SFProDisplayMedium,
        ),
      ));
}
