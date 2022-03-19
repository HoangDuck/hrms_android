import 'dart:convert';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class RequestDataView extends StatefulWidget {
  final dynamic data;

  RequestDataView(this.data);

  @override
  _RequestDataViewState createState() => _RequestDataViewState();
}

class _RequestDataViewState extends State<RequestDataView>
    with TickerProviderStateMixin {
  DateFormat dateFormatAPI = DateFormat('yyyy/MM/dd HH:mm');

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  ScrollController controller;

  TabController _tabController;

  List<Tab> _tabList = [];

  List<dynamic> _tabContent = [];

  List<dynamic> _genRowList = [];

  List<dynamic> _typeOffList = [];

  dynamic _typeSelected;

  List<dynamic> _assignerList = [];

  dynamic _userSelected;

  List<dynamic> _statusProgressList = [];

  int _statusProgressSelected = -1;

  List<dynamic> _listLateType = [];

  int _typeLateSelected = -1;

  List<dynamic> _listCompensationType = [];

  int _typeCompensationSelected = -1;

  List<dynamic> _shiftWorkingList = [];

  int _shiftWorkingSelected = -1;

  String searchText = '';

  List<dynamic> _popupMenuItem = [
    ['Rút đơn', Icon(Icons.assignment_return, color: txt_orange_color)]
  ];

  int processStatus;

  int nextIndex = 0;

  int numRow = 10;

  int nextIndexSelected = 0;

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  DateTime dateTimeNow = DateTime.now();

  var stateSelectAssign, stateSelectTypeOff;

  bool _timeChecked = false;

  bool _showLoadMore = false;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    _tabController = TabController(
        vsync: this, initialIndex: 0, length: widget.data['data'].length);
    _tabController.addListener(_tabChange);
    //_tabController.animation.addListener(() => print('Animation value:' + _tabController.animation.value.toString()));
    for (int i = 0; i < widget.data['data'].length; i++) {
      _tabList.add(Tab(text: widget.data['data'][i]['Ten']['v']));
      _tabContent.add({
        'id': widget.data['data'][i]['ID'],
        'name': widget.data['data'][i]['Ten']['v'],
        'listData': [],
        'key': GlobalKey<RefreshIndicatorState>(),
        'filter': '',
        'nextIndex': 0
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDateTime();
  }

  _refreshDateTime() {
    _dateTimeStartController.value = TextEditingValue(
        text: Utils.getString(context, txt_from),
        selection: _dateTimeStartController.selection);

    _dateTimeEndController.value = TextEditingValue(
        text: Utils.getString(context, txt_to),
        selection: _dateTimeEndController.selection);

    _startWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));

    _endWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));
  }

  _tabChange() {
    nextIndex = 0;
    _timeChecked = false;
    _refreshDateTime();
    _statusProgressSelected = -1;
  }

  Future<String> refreshList(BaseViewModel model) async {
    _tabContent[_tabController.index]['nextIndex'] = 0;
    numRow = 10;
    _tabContent[_tabController.index]['filter'] = '';
    getListData(model, _tabContent[_tabController.index]['nextIndex'], numRow,
        tab: _tabController.index, refresh: true);
    return 'success';
  }

  _convertListProgress(List<dynamic> list, int index) {
    List<String> _process;
    if (list[index]['ThongTinDuyetDon']['r'] != '') {
      var statusCheckFirst = list[index]['ThongTinDuyetDon']['r']
          .substring(0, list[index]['ThongTinDuyetDon']['r'].length - 1)
          .split('&')
          .where((i) => i.split('#')[2] != '2' && i.split('#')[2] != '1')
          .toList();
      if (statusCheckFirst.length > 0) {
        _process = statusCheckFirst.last.split('#');
      } else {
        var statusCheckSecond = list[index]['ThongTinDuyetDon']['r']
            .substring(0, list[index]['ThongTinDuyetDon']['r'].length - 1)
            .split('&')
            .where((i) => i.split('#')[2] == '2')
            .toList();
        if (statusCheckSecond.length == 0) {
          _process = list[index]['ThongTinDuyetDon']['r']
              .split('&')[
                  list[index]['ThongTinDuyetDon']['r'].split('&').length - 2]
              .split('#');
        } else
          _process = statusCheckSecond[0].split('#');
      }
    } else
      _process = [];
    return _process;
  }

  _scrollListener(BaseViewModel model) {
    List<dynamic> list = [];
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      list = _tabContent[_tabController.index]['listData'];
      if (list.length < int.parse(list[0]['total_row']['v'])) {
        _tabContent[_tabController.index]['nextIndex'] += 10;
        getListData(
            model, _tabContent[_tabController.index]['nextIndex'], numRow,
            tab: _tabController.index, isLoadMore: true);
      }
    }
  }

  // ThongSo = tbName=vw_tb_hrms_nghiphep_absent_history_submit_mobile&tbNameDetail=vw_tb_hrms_nghiphep_absent_history_submit_mobile_detail
  getListData(BaseViewModel model, int currentIndex, int nextIndex,
      {int tab = 0, bool refresh = false, bool isLoadMore = false}) async {
    if (!isLoadMore)
      _loading = true;
    else
      _showLoadMore = true;
    setState(() {});
    List<dynamic> _listData = [];
    String tbName;
    for (int i = tab; i < widget.data['data'].length; i++) {
      if (widget.data['data'][i]['ThongSo']['v'] != '') {
        tbName = (widget.data['data'][i]['ThongSo']['v'].split('&')[0])
            .split('=')[1];
        var response = await model.callApis({
          "table_name": tbName,
          "type_sort": 'DESC',
          "current_index": currentIndex,
          "next_index": nextIndex,
          "filter_progress": _tabContent[_tabController.index]['filter']
        }, getListDataRequestUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        if (response.status.code == 200) {
          _listData = response.data['data'];
          String id = widget.data['data'][i]['ID'];
          var _tabContentObject =
              (_tabContent.where((i) => i['id'] == id).toList())[0];
          setState(() {
            if (refresh) {
              _tabContent[_tabContent.indexOf(_tabContentObject)]['listData']
                  .clear();
            }
            _tabContent[_tabContent.indexOf(_tabContentObject)]['listData']
                .addAll(_listData);
            _showLoadMore = false;
            _loading = false;
          });
        } else {
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_get_data_failed));
          break;
        }
        if ((refresh || isLoadMore) && i == _tabController.index) break;
      }
    }
  }

  _getType(String type, String tabName) {
    var tabContentObject =
        (_tabContent.where((i) => i['name'] == tabName).toList())[0];
    if (type == 'key') return tabContentObject['key'];
    if (type == 'list') return tabContentObject['listData'];
    if (type == 'title') return tabContentObject['name'];
  }

  Future<void> getGenRowDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis({
      "TbName": (widget.data['data'][_tabController.index]['ThongSo']['v']
              .split('&')[0])
          .split('=')[1]
    }, getGenRowDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      setState(() {
        _genRowList = response.data['data'];
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getAbsentType(BaseViewModel model,
      {String searchText = '',
      Function callback,
      int nextIndex = 0,
      StateSetter stateModal,
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
      if (stateModal != null) stateModal(() {});
      if (callback != null) {
        callback();
      }
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getAssigner(BaseViewModel model,
      {String searchText = '',
      int nextIndex = 0,
      StateSetter stateModal,
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
      if (stateModal != null) stateModal(() {});
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getProgressStatus(BaseViewModel model) async {
    List<dynamic> statusProgressList = [];
    var response = await model.callApis({}, getStatusProgress, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var statusProgress in response.data['data']) {
        statusProgressList.add({
          'id': statusProgress['ID'],
          'name': statusProgress['Name']['v'],
        });
      }
      setState(() {
        _statusProgressList = statusProgressList;
      });
//      for(int i = 0; i < _statusProgressList.length; i++){
//        if(_statusProgressList[i]['id'] == '2') _statusProgressSelected = i;
//      }
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void getLateEarlyType(BaseViewModel model) async {
    var response = await model.callApis({}, lateEarlyTypeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      List<dynamic> _list = [];
      for (var listItem in response.data['data']) {
        _list.add({'id': listItem['ID'], 'name': listItem['Type']['v']});
      }
      setState(() {
        _listLateType = _list;
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getCompensationType(BaseViewModel model) async {
    var listType = List<dynamic>();
    var typeResponse = await model.callApis(
        {}, compensationTypeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (typeResponse.status.code == 200) {
      for (var type in typeResponse.data['data']) {
        listType.add({'id': type['ID'], 'name': type['name_type']['r']});
      }
      setState(() {
        _listCompensationType = listType;
      });
    }
  }

  void getTimeDefineResponse(BaseViewModel model) async {
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
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  void withDrawApplicationCall(BaseViewModel model,
      {String tbName = '', int rowId = 0}) async {
    showLoadingDialog(context);
    String tbNameEncrypt = await Utils.encrypt(tbName);
    var response = await model.callApis(
        {'tbname': tbNameEncrypt, 'idrow': rowId},
        withDrawApplication,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    Navigator.pop(context);
    if (response.status.code == 200) {
      if (response.data['data'][0]['result'] ==
          Utils.getString(context, txt_status_withdraw_success)) {
        debugPrint('success');
      } else {
        debugPrint('failed');
      }
      showMessageDialogIOS(context,
          description: response.data['data'][0]['result'], onPress: () {
        Navigator.pop(context);
        refreshList(model);
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        controller.addListener(() => _scrollListener(model));
        Future.delayed(Duration(seconds: 0), () {
          getProgressStatus(model);
          getLateEarlyType(model);
          getCompensationType(model);
          getTimeDefineResponse(model);
          getListData(model, nextIndex, numRow, tab: _tabController.index);
        });
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
          if (_tabController.index.toDouble() == _tabController.animation.value)
            getGenRowDefine(model).then((value) {
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
                        return _tabController.index == 0
                            ? _modalBottomSheetDayOff(setModalState, model)
                            : _tabController.index == 1
                                ? _modalBottomSheetLateEarly(
                                    setModalState, model)
                                : _tabController.index == 2
                                    ? _modalBottomSheetCompensation(
                                        setModalState, model)
                                    : _modalBottomSheetExternalWorking(
                                        setModalState, model);
                      })),
                ),
              );
            });
        }, widget.data['title'], Icons.sort),
        body: DefaultTabController(
            length: widget.data['data'].length,
            initialIndex: 0,
            child: Column(
              children: <Widget>[
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: only_color,
                  labelStyle: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      fontFamily: 'SFProDisplay-Medium'),
                  unselectedLabelColor: txt_black_color.withOpacity(0.5),
                  unselectedLabelStyle: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      fontFamily: 'SFProDisplay-Medium'),
                  labelColor: txt_black_color,
                  tabs: _tabList,
                ),
                Expanded(
                    child: TabBarView(controller: _tabController, children: [
                  ..._tabContent.map((value) => _list(context, model, value))
                ]))
              ],
            )),
      ),
    );
  }

  Widget _list(BuildContext context, BaseViewModel model, dynamic tabContent) {
    return Stack(
      children: <Widget>[
        Container(
          height: double.infinity,
          width: double.infinity,
          color: bg_view_color,
        ),
        RefreshIndicator(
            onRefresh: () => refreshList(model),
            key: tabContent['key'],
            child: _loading
                ? Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : tabContent['listData'].length > 0
                    ? Column(
                        children: <Widget>[
                          Expanded(
                            child: DraggableScrollbar.semicircle(
                              labelTextBuilder: (offset) {
                                final int currentItem = controller.hasClients
                                    ? (controller.offset /
                                            controller
                                                .position.maxScrollExtent *
                                            tabContent['listData'].length)
                                        .floor()
                                    : 0;
                                return Text(
                                  "${currentItem + 1}",
                                  style: TextStyle(color: Colors.white),
                                );
                              },
                              controller: controller,
                              heightScrollThumb:
                                  Utils.resizeHeightUtil(context, 80),
                              backgroundColor: only_color,
                              child: ListView.builder(
                                  physics: AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.all(
                                      Utils.resizeWidthUtil(context, 30)),
                                  controller: controller,
                                  scrollDirection: Axis.vertical,
                                  itemCount: tabContent['listData'].length,
                                  itemBuilder: (context, index) {
                                    return _item(index, tabContent['listData'],
                                        tabContent['name'], model);
                                  }),
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
                      )),
      ],
    );
  }

  // ThongSo = tbName=vw_tb_hrms_nghiphep_absent_history_submit_mobile&tbNameDetail=vw_tb_hrms_nghiphep_absent_history_submit_mobile_detail
  Widget _item(
      int index, List<dynamic> list, String tabName, BaseViewModel model) {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  pageBuilder: (_, __, ___) => RequestDataDetailView(
                      data: list[index],
                      tabName: _tabList[_tabController.index].text.toString(),
                      tbName: (widget.data['data'][_tabController.index]
                                  ['ThongSo']['v']
                              .split('&')[1])
                          .split('=')[1],
                      permission: 0))).then((value) {
            if (value) refreshList(model);
          });
          //permission 0: employee
          //permission 1: owner
        },
        child: Hero(
          tag: 'info${list[index]}',
          child: SingleChildScrollView(
              child: Stack(
            children: <Widget>[
              Container(
                  margin: EdgeInsets.only(
                      bottom: Utils.resizeHeightUtil(context, 25)),
                  decoration: BoxDecoration(
                      color: white_color,
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                  padding: EdgeInsets.only(
                      top: Utils.resizeWidthUtil(context, 30),
                      left: Utils.resizeWidthUtil(context, 30),
                      right: Utils.resizeWidthUtil(context, 30),
                      bottom: Utils.resizeWidthUtil(context, 14)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _userInfo(),
                      _dashLine(),
                      SizedBox(height: Utils.resizeHeightUtil(context, 14)),
                      _requestContent(
                          title: _getType('title', tabName),
                          type: list[index]['name_type']['r'],
                          value: list[index]['value']['r'],
                          valueType: list[index]['value_type']['r'],
                          time: list[index]['time']['r'],
                          reason: list[index]['reason']['r'],
                          list: list[index]),
                      SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                      _processStatus(
                          _convertListProgress(list, index), list[index]),
                    ],
                  )),
              if (list[index]['trang_thai_duyet']['v'] == '2')
                Positioned(
                    right: -5,
                    top: -5,
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<dynamic>(
                        onSelected: (value) {
                          withDrawApplicationCall(model,
                              tbName: (widget.data['data'][_tabController.index]
                                          ['ThongSo']['v']
                                      .split('&')[2])
                                  .split('=')[1],
                              rowId: int.parse(list[index]['ID']));
                        },
                        itemBuilder: (context) {
                          return _popupMenuItem.map((dynamic choice) {
                            return PopupMenuItem<dynamic>(
                              value: choice,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  TKText(
                                    choice[0],
                                    tkFont: TKFont.SFProDisplaySemiBold,
                                    style: TextStyle(
                                        fontSize:
                                            Utils.resizeWidthUtil(context, 30)),
                                  ),
                                  SizedBox(
                                    width: 2,
                                  ),
                                  choice[1]
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ))
            ],
          )),
        ));
  }

  Widget _requestContent(
          {String title,
          String type,
          String value,
          String valueType,
          String time,
          String reason,
          dynamic list}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        list['PathGPS'] != null
            ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: jsonDecode('[${list['PathGPS']['v']}]').length,
                itemBuilder: (context, index) {
                  return Column(
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            height: Utils.resizeHeightUtil(context, 30),
                            width: Utils.resizeHeightUtil(context, 30),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: only_color),
                            child: Center(
                              child: TKText(
                                (index + 1).toString(),
                                tkFont: TKFont.SFProDisplayMedium,
                                style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 24),
                                    color: white_color),
                              ),
                            ),
                          ),
                          SizedBox(width: Utils.resizeWidthUtil(context, 10)),
                          Expanded(
                            child: TKText(
                              jsonDecode('[${list['PathGPS']['v']}]')[index]
                                  ['address'],
                              tkFont: TKFont.SFProDisplayMedium,
                              style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: Utils.resizeWidthUtil(context, 30),
                                  color: only_color),
                            ),
                          ),
                          if (jsonDecode('[${list['PathGPS']['v']}]')[index]
                                      ['calendar_place_file'] !=
                                  null &&
                              jsonDecode('[${list['PathGPS']['v']}]')[index]
                                      ['calendar_place_file'] !=
                                  '0')
                            Icon(Icons.attach_file, color: txt_fail_color),
                          if (jsonDecode('[${list['PathGPS']['v']}]')[index]
                                      ['calendar_place_file'] !=
                                  null &&
                              jsonDecode('[${list['PathGPS']['v']}]')[index]
                                      ['calendar_place_file'] !=
                                  '0')
                            TKText(
                              jsonDecode('[${list['PathGPS']['v']}]')[index]
                                  ['calendar_place_file'],
                              tkFont: TKFont.SFProDisplayMedium,
                              style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontSize: Utils.resizeWidthUtil(context, 24),
                                  color: txt_fail_color),
                            ),
                        ],
                      ),
                      SizedBox(
                        height: Utils.resizeHeightUtil(
                            context,
                            index + 1 ==
                                    jsonDecode('[${list['PathGPS']['v']}]')
                                        .length
                                ? 0
                                : 10),
                      )
                    ],
                  );
                })
            : TKText(
                type,
                tkFont: TKFont.SFProDisplayMedium,
                style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 30),
                    color: only_color),
              ),
        SizedBox(height: Utils.resizeHeightUtil(context, 25)),
        Row(
          children: <Widget>[
            Container(
                height: Utils.resizeWidthUtil(context, 76),
                width: Utils.resizeWidthUtil(context, 76),
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
                      value,
                      tkFont: TKFont.SFProDisplayBold,
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: white_color),
                    ),
                    TKText(
                      valueType,
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: Utils.resizeWidthUtil(context, 22),
                          color: white_color),
                    ),
                  ],
                )),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TKText(
                    time,
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 28),
                        color: txt_grey_color_v3),
                  ),
                  SizedBox(height: Utils.resizeHeightUtil(context, 5)),
                  TKText(
                    reason,
                    tkFont: TKFont.SFProDisplayRegular,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 28),
                        color: txt_grey_color_v3),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Utils.resizeHeightUtil(context, 20)),
        _dashLine(),
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

  Widget _processStatus(List<dynamic> progress, dynamic data) {
    return progress.length > 0
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TKText(
                    progress[2] != '2' && progress[2] != '3' ? progress[4] : '',
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 24),
                        color: txt_grey_color_v4),
                  ),
                  Row(
                    children: <Widget>[
                      TKText(
                        progress.length == 0
                            ? ''
                            : '${Utils.getString(context, txt_by)} ',
                        tkFont: TKFont.SFProDisplayMedium,
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: Utils.resizeWidthUtil(context, 26),
                            color: txt_grey_color_v4),
                      ),
                      TKText(
                        progress.length == 0 ? '' : progress[1],
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
                      color: Color(int.parse(progress.last)).withOpacity(0.12),
                      borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  child: TKText(
                    progress.length == 0
                        ? data['trang_thai']['r']
                        : progress[3],
                    tkFont: TKFont.SFProDisplayMedium,
                    style: TextStyle(
                        decoration: TextDecoration.none,
                        fontSize: Utils.resizeWidthUtil(context, 28),
                        color: Color(int.parse(progress.last))),
                  )),
            ],
          )
        : SizedBox.shrink();
  }

  Widget _userInfo() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              width: Utils.resizeWidthUtil(context, 160),
              height: Utils.resizeWidthUtil(context, 160),
              padding: EdgeInsets.only(
                  right: Utils.resizeWidthUtil(context, 30),
                  bottom: Utils.resizeWidthUtil(context, 30)),
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                  child: FadeInImage.assetNetwork(
                      fit: BoxFit.cover,
                      placeholder: avatar_default,
                      image:
                          '$avatarUrl${context.read<BaseResponse>().data['data'][0]['avatar']['v'].toString()}'),
                ),
              )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(
                  '${context.read<BaseResponse>().data['data'][0]['full_name']['r'].toString()} (${context.read<BaseResponse>().data['data'][0]['emp_id']['r'].toString()})',
                  tkFont: TKFont.SFProDisplayBold,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: Utils.resizeWidthUtil(context, 32),
                      color: txt_grey_color_v2),
                ),
                SizedBox(height: Utils.resizeHeightUtil(context, 7)),
                TKText(
                  '${context.read<BaseResponse>().data['data'][0]['name_role']['r'].toString()}' +
                      ' (' +
                      '${context.read<BaseResponse>().data['data'][0]['id_role']['r'].toString()}' +
                      ')',
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
                  Utils.getString(context, txt_department_name) +
                      ' ' +
                      '${context.read<BaseResponse>().data['data'][0]['name_department']['r'].toString()}' +
                      ' (' +
                      '${context.read<BaseResponse>().data['data'][0]['id_department']['r'].toString()}' +
                      ')',
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

  Widget _modalBottomSheetDayOff(
      StateSetter setModalState, BaseViewModel model) {
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
                      color: txt_grey_color_v1.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 10),
                ),
                _buildTimeOff(
                    setModalState,
                    _genRowList.length > 0
                        ? Utils.getTitle(_genRowList, 'from_time')
                        : ''),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustomUtil(
                    title: _typeOffList.length > 0
                        ? _typeSelected != null
                            ? _typeSelected['name']
                            : '${Utils.getString(context, txt_choose)} ${_genRowList.length == 0 ? '' : (Utils.getTitle(_genRowList, 'absent_type_id').toLowerCase())}'
                        : '${Utils.getString(context, txt_choose)} ${_genRowList.length == 0 ? '' : (Utils.getTitle(_genRowList, 'absent_type_id').toLowerCase())}',
                    data: _typeOffList,
                    selectedItem: 0,
                    clearCallback: () {
                      setModalState(() {
                        _typeSelected = null;
                        _typeOffList.clear();
                      });
                    },
                    initCallback: (state) {
                      stateSelectTypeOff = state;
                      searchText = '';
                      nextIndexSelected = 0;
                      _typeOffList.clear();
                      getAbsentType(model,
                          nextIndex: nextIndexSelected,
                          state: state,
                          stateModal: setModalState);
                    },
                    loadMoreCallback: (state) {
                      if (_typeOffList.length <
                          int.parse(_typeOffList[0]['total_row'])) {
                        nextIndexSelected += 10;
                        getAbsentType(model,
                            nextIndex: nextIndexSelected,
                            searchText: searchText,
                            stateModal: setModalState,
                            state: state);
                      }
                    },
                    searchCallback: (value, state) {
                      if (value != '') {
                        Future.delayed(Duration(seconds: 2), () {
                          searchText = value;
                          nextIndexSelected = 0;
                          _typeOffList.clear();
                          getAbsentType(model,
                              nextIndex: nextIndexSelected,
                              searchText: value,
                              state: state,
                              stateModal: setModalState);
                        });
                      }
                    },
                    callBack: (itemSelected) => setModalState(() {
                          _typeSelected = itemSelected;
                        })),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustomUtil(
                    title: _assignerList.length > 0
                        ? _userSelected == null
                            ? '${Utils.getString(context, txt_choose)} ${_genRowList.length == 0 ? '' : (Utils.getTitle(_genRowList, 'assign_employeeID').toLowerCase())}'
                            : _userSelected['name']
                        : '${Utils.getString(context, txt_choose)} ${_genRowList.length == 0 ? '' : (Utils.getTitle(_genRowList, 'assign_employeeID').toLowerCase())}',
                    data: _assignerList,
                    selectedItem: 0,
                    clearCallback: () {
                      setModalState(() {
                        _userSelected = null;
                      });
                    },
                    initCallback: (state) {
                      stateSelectAssign = state;
                      searchText = '';
                      nextIndexSelected = 0;
                      _assignerList.clear();
                      getAssigner(model,
                          nextIndex: nextIndexSelected,
                          state: state,
                          stateModal: setModalState);
                    },
                    loadMoreCallback: (state) {
                      if (_assignerList.length <
                          int.parse(_assignerList[0]['total_row'])) {
                        nextIndexSelected += 10;
                        getAssigner(model,
                            nextIndex: nextIndexSelected,
                            searchText: searchText,
                            stateModal: setModalState,
                            state: state);
                      }
                    },
                    searchCallback: (value, state) {
                      if (value != '') {
                        Future.delayed(Duration(seconds: 2), () {
                          searchText = value;
                          nextIndexSelected = 0;
                          _assignerList.clear();
                          getAssigner(model,
                              nextIndex: nextIndexSelected,
                              searchText: value,
                              state: state,
                              stateModal: setModalState);
                        });
                      }
                    },
                    callBack: (itemSelected) {
                      setModalState(() {
                        _userSelected = itemSelected;
                      });
                    }),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _statusProgressList.length > 0
                      ? _statusProgressSelected != -1
                          ? _statusProgressList[_statusProgressSelected]['name']
                          : Utils.getTitle(_genRowList, 'trang_thai_duyet')
                      : Utils.getTitle(_genRowList, 'trang_thai_duyet'),
                  data: _statusProgressList,
                  selectedItem: _statusProgressSelected,
                  clearCallback: () {
                    setModalState(() {
                      _statusProgressSelected = -1;
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
                  children: <Widget>[
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_find),
                        width: MediaQuery.of(context).size.width,
                        onPress: () {
                          Navigator.of(context).pop();
                          nextIndex = 0;
//                          controller.animateTo(0.0,
//                              duration: Duration(milliseconds: 300),
//                              curve: Curves.easeOut);
                          String idStatusProgress = _statusProgressSelected !=
                                  -1
                              ? ' AND (trang_thai_duyet = ${_statusProgressList[_statusProgressSelected]['id']})'
                              : '';
                          String typeSelected = _typeSelected != null
                              ? ' AND absent_type_id = ${_typeSelected['id']}'
                              : '';
                          String userSelected = _userSelected != null
                              ? ' AND assign_employeeID = ${_userSelected['id']}'
                              : '';
                          String timeSelected = _timeChecked
                              ? ' AND from_time BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';
                          _tabContent[_tabController.index]['filter'] =
                              typeSelected +
                                  userSelected +
                                  idStatusProgress +
                                  timeSelected;
                          getListData(model, nextIndex, numRow,
                              tab: _tabController.index, refresh: true);
                        },
                      ),
                    ),
                    SizedBox(
                      width: Utils.resizeHeightUtil(context, 30),
                    ),
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_clear_find),
                        width: MediaQuery.of(context).size.width,
                        onPress: () {
                          setModalState(() {
                            _refreshDateTime();
                            _userSelected = null;
                            _typeSelected = null;
                            _statusProgressSelected = -1;
                            if (stateSelectTypeOff != null)
                              stateSelectTypeOff.clearData();
                            if (stateSelectAssign != null)
                              stateSelectAssign.clearData();
                          });
                        },
                      ),
                    )
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

  Widget _modalBottomSheetLateEarly(
      StateSetter setModalState, BaseViewModel model) {
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
                      color: txt_grey_color_v1.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTimeOff(
                    setModalState,
                    _genRowList.length > 0
                        ? Utils.getTitle(_genRowList, 'date_late')
                        : ''),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _listLateType.length > 0
                      ? _typeLateSelected != -1
                          ? _listLateType[_typeLateSelected]['name']
                          : Utils.getTitle(_genRowList, 'late_history_type')
                      : Utils.getTitle(_genRowList, 'late_history_type'),
                  data: _listLateType,
                  selectedItem: _typeLateSelected,
                  clearCallback: () {
                    setModalState(() {
                      _typeLateSelected = -1;
                    });
                  },
                  callBack: (itemSelected) {
                    setModalState(() {
                      if (itemSelected != null) {
                        _typeLateSelected = itemSelected;
                      }
                    });
                  },
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _statusProgressList.length > 0
                      ? _statusProgressSelected != -1
                          ? _statusProgressList[_statusProgressSelected]['name']
                          : Utils.getTitle(_genRowList, 'trang_thai_duyet')
                      : Utils.getTitle(_genRowList, 'trang_thai_duyet'),
                  data: _statusProgressList,
                  selectedItem: _statusProgressSelected,
                  clearCallback: () {
                    setModalState(() {
                      _statusProgressSelected = -1;
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
                  children: <Widget>[
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_find),
                        width: MediaQuery.of(context).size.width,
                        onPress: () {
                          Navigator.of(context).pop();
                          nextIndex = 0;
//                          controller.animateTo(0.0,
//                              duration: Duration(milliseconds: 300),
//                              curve: Curves.easeOut);
                          String idStatusProgress = _statusProgressSelected !=
                                  -1
                              ? ' AND (trang_thai_duyet = ${_statusProgressList[_statusProgressSelected]['id']})'
                              : '';
                          String typeLateSelected = _typeLateSelected != -1
                              ? ' AND (late_history_type = ${_listLateType[_typeLateSelected]['id']})'
                              : '';
                          String timeSelected = _timeChecked
                              ? ' AND date_late BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';
                          _tabContent[_tabController.index]['filter'] =
                              typeLateSelected +
                                  idStatusProgress +
                                  timeSelected;
                          getListData(model, nextIndex, numRow,
                              tab: _tabController.index, refresh: true);
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
                            _refreshDateTime();
                            _statusProgressSelected = -1;
                            _typeLateSelected = -1;
                            _timeChecked = false;
                          });
                        },
                      ),
                    )
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

  Widget _modalBottomSheetCompensation(
      StateSetter setModalState, BaseViewModel model) {
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
                      color: txt_grey_color_v1.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTimeOff(
                    setModalState,
                    _genRowList.length > 0
                        ? Utils.getTitle(_genRowList, 'date_time_sheet')
                        : ''),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _listCompensationType.length > 0
                      ? _typeCompensationSelected != -1
                          ? _listCompensationType[_typeCompensationSelected]
                              ['name']
                          : Utils.getTitle(_genRowList, 'timesheet_type')
                      : Utils.getTitle(_genRowList, 'timesheet_type'),
                  data: _listCompensationType,
                  selectedItem: _typeCompensationSelected,
                  clearCallback: () {
                    setModalState(() {
                      _typeCompensationSelected = -1;
                    });
                  },
                  callBack: (itemSelected) {
                    setModalState(() {
                      if (itemSelected != null) {
                        _typeCompensationSelected = itemSelected;
                      }
                    });
                  },
                ),
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
                      }
                    });
                  },
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _statusProgressList.length > 0
                      ? _statusProgressSelected != -1
                          ? _statusProgressList[_statusProgressSelected]['name']
                          : Utils.getTitle(_genRowList, 'trang_thai_duyet')
                      : Utils.getTitle(_genRowList, 'trang_thai_duyet'),
                  data: _statusProgressList,
                  selectedItem: _statusProgressSelected,
                  clearCallback: () {
                    setModalState(() {
                      _statusProgressSelected = -1;
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
                  children: <Widget>[
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_find),
                        width: MediaQuery.of(context).size.width,
                        onPress: () {
                          Navigator.of(context).pop();
                          nextIndex = 0;
//                          controller.animateTo(0.0,
//                              duration: Duration(milliseconds: 300),
//                              curve: Curves.easeOut);
                          String idStatusProgress = _statusProgressSelected !=
                                  -1
                              ? ' AND (trang_thai_duyet = ${_statusProgressList[_statusProgressSelected]['id']})'
                              : '';
                          String timeSheetType = _typeCompensationSelected != -1
                              ? ' AND (timesheet_type = ${_listCompensationType[_typeCompensationSelected]['id']})'
                              : '';
                          String timeId = _shiftWorkingSelected != -1
                              ? ' AND (time_id = ${_shiftWorkingList[_shiftWorkingSelected]['id']})'
                              : '';
                          String timeSelected = _timeChecked
                              ? ' AND date_time_sheet BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';
                          _tabContent[_tabController.index]['filter'] =
                              timeSheetType +
                                  timeId +
                                  idStatusProgress +
                                  timeSelected;
                          getListData(model, nextIndex, numRow,
                              tab: _tabController.index, refresh: true);
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
                            _refreshDateTime();
                            _statusProgressSelected = -1;
                            _shiftWorkingSelected = -1;
                            _typeCompensationSelected = -1;
                          });
                        },
                      ),
                    )
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

  Widget _modalBottomSheetExternalWorking(
      StateSetter setModalState, BaseViewModel model) {
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
                      color: txt_grey_color_v1.withOpacity(0.3),
                      borderRadius: BorderRadius.all(Radius.circular(8.0))),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildTimeOff(
                    setModalState,
                    _genRowList.length > 0
                        ? Utils.getTitle(_genRowList, 'from_time')
                        : ''),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                SelectBoxCustom(
                  valueKey: 'name',
                  title: _statusProgressList.length > 0
                      ? _statusProgressSelected != -1
                          ? _statusProgressList[_statusProgressSelected]['name']
                          : Utils.getTitle(_genRowList, 'trang_thai_duyet')
                      : Utils.getTitle(_genRowList, 'trang_thai_duyet'),
                  data: _statusProgressList,
                  selectedItem: _statusProgressSelected,
                  clearCallback: () {
                    setModalState(() {
                      _statusProgressSelected = -1;
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
                  children: <Widget>[
                    Expanded(
                      child: TKButton(
                        Utils.getString(context, txt_find),
                        width: MediaQuery.of(context).size.width,
                        onPress: () {
                          Navigator.of(context).pop();
                          nextIndex = 0;
//                          controller.animateTo(0.0,
//                              duration: Duration(milliseconds: 300),
//                              curve: Curves.easeOut);
                          String idStatusProgress = _statusProgressSelected !=
                                  -1
                              ? ' AND (trang_thai_duyet = ${_statusProgressList[_statusProgressSelected]['id']})'
                              : '';
                          String timeSelected = _timeChecked
                              ? ' AND from_time BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';
                          _tabContent[_tabController.index]['filter'] =
                              idStatusProgress + timeSelected;
                          getListData(model, nextIndex, numRow,
                              tab: _tabController.index, refresh: true);
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
                            _refreshDateTime();
                            _statusProgressSelected = -1;
                          });
                        },
                      ),
                    )
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

  Widget _buildTimeOff(StateSetter setModalState, String title) {
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
                      initialDate: dateFormat
                          .parse(dateFormat.format(_startWorkingTime)),
                      firstDate: DateTime(2020),
                      initialTime: TimeOfDay(
                          hour: _startWorkingTime.hour,
                          minute: _startWorkingTime.minute),
                      callBack: (date, time) {
                        if (date == null) return;
                        setModalState(() {
                          _startWorkingTime = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                          _dateTimeStartController.text =
                              dateFormat.format(_startWorkingTime);
                          if (_startWorkingTime.isAfter(_endWorkingTime) ||
                              _dateTimeEndController.text.length < 10) {
                            _endWorkingTime = _startWorkingTime;
                            _dateTimeEndController.text =
                                dateFormat.format(_endWorkingTime);
                            _timeChecked = true;
                          }
                        });
                      }),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                  DateTimePickerCustomModify(
                      controller: _dateTimeEndController,
                      initialTime: TimeOfDay(
                          hour: _endWorkingTime.hour,
                          minute: _endWorkingTime.minute),
                      initialDate:
                          dateFormat.parse(dateFormat.format(_endWorkingTime)),
                      firstDate: DateTime(_startWorkingTime.year,
                          _startWorkingTime.month, _startWorkingTime.day),
                      callBack: (date, time) {
                        if (date == null) return;
                        setModalState(() {
                          _endWorkingTime = DateTime(date.year, date.month,
                              date.day, time.hour, time.minute);
                          _dateTimeEndController.text =
                              dateFormat.format(_endWorkingTime);
                          if (_dateTimeStartController.text.length < 10) {
                            _startWorkingTime = _endWorkingTime;
                            _dateTimeStartController.text =
                                dateFormat.format(_startWorkingTime);
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
}
