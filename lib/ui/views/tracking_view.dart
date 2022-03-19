import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import 'main_view.dart';

class TrackingView extends StatefulWidget {
  final String title;

  TrackingView(this.title);

  @override
  _MoveHistoryViewState createState() => _MoveHistoryViewState();
}

class _MoveHistoryViewState extends State<TrackingView> {
  DateFormat dateFormatAPI = DateFormat('yyyy/MM/dd HH:mm');

  List<dynamic> listHistory = [];

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  ScrollController controller;

  int nextIndex = 0;

  int numRow = 10;

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  DateTime dateTimeNow = DateTime.now();

  List<dynamic> apiKeyList = [];

  bool isLoading = true;

  bool _showLoadMore = false;

  List<dynamic> _assignerList = [];

  dynamic _userSortSelected;

  var stateSelectAssign, stateSelectUserSort;

  String searchTextUserSort = '';

  int nextIndexSelectedUserSort = 0;

  String filter = '';

  int totalRow;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshDateTime();
  }

  _refreshDateTime() {
    _dateTimeStartController.value =
        TextEditingValue(text: Utils.getString(context, txt_from), selection: _dateTimeStartController.selection);

    _dateTimeEndController.value =
        TextEditingValue(text: Utils.getString(context, txt_to), selection: _dateTimeEndController.selection);

    _startWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));

    _endWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));
  }

  _scrollListener(BaseViewModel model) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      if (listHistory.length < totalRow) {
        nextIndex += 10;
        getListHistory(model, nextIndex, isLoadMore: true);
      }
    }
  }

  getListHistory(BaseViewModel model, int currentIndex, {bool isRefresh = false, bool isLoadMore = false}) async {
    if (isRefresh) {
      listHistory.clear();
      nextIndex = 0;
    }
    if (!isLoadMore)
      isLoading = true;
    else
      _showLoadMore = true;
    setState(() {});
    var response = await model.callApis(
        {'condition': filter == '' ? '1 = 1' : filter, 'current_index': currentIndex}, GetHistoryTracking, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var item in response.data['data']) {
        if (item['location_address']['v'] == '') {
          for (var keyItem in apiKeyList) {
            if (item['lat']['v'] != '' || item['long']['v'] != '') {
              var addressResponse = await http.get(Uri.parse('https://maps.google.com/maps/api/geocode/json?'
                  'key=$keyItem'
                  '&language=en&'
                  'latlng=${item['lat']['v']},${item['long']['v']}'));
              if (addressResponse.statusCode == 200) {
                item['location_address']['v'] = jsonDecode(addressResponse.body)['results'][0]['formatted_address'];
                listHistory.add(item);
                break;
              }
            } else
              break;
          }
        }
        listHistory.add(item);
      }
      setState(() {
        isLoading = false;
        _showLoadMore = false;
      });
    }
  }

  getGoogleApiKey(BaseViewModel model) async {
    var response =
        await model.callApis({}, googleApiKey, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      apiKeyList = jsonDecode(response.data['data'][0]['GoogleApiKey']['v']);
      await SecureStorage().saveCustomString(SecureStorage.GOOGLE_KEY, response.data['data'][0]['GoogleApiKey']['v']);
    }
    await getListHistory(model, nextIndex);
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

  void getTotalRow(BaseViewModel model) async {
    print(filter);
    var response = await model.callApis(
        {"condition": filter == '' ? '1 = 1' : filter}, GetTotalHistoryTracking, method_post,
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

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        controller.addListener(() => _scrollListener(model));
        getGoogleApiKey(model);
        getTotalRow(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
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
                    return _modalBottomSheetFilter(setModalState, model);
                  })),
            ),
          );
        }, Utils.getString(context, txt_history_move), Icons.sort),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: bg_view_color,
          padding: EdgeInsets.symmetric(
              vertical: Utils.resizeWidthUtil(context, 30), horizontal: Utils.resizeWidthUtil(context, 20)),
          child: isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : listHistory.length == 0
                  ? Center(
                      child: TKText('Không có dữ liệu'),
                    )
                  : RefreshIndicator(
                      onRefresh: () => getListHistory(model, nextIndex, isRefresh: true),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                                itemCount: listHistory.length,
                                controller: controller,
                                itemBuilder: (context, index) => listItem(index)),
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
                    ),
        ),
      ),
    );
  }

  Widget listItem(index) => SingleChildScrollView(
      child: Container(
          margin: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 25)),
          decoration: BoxDecoration(color: white_color, borderRadius: BorderRadius.all(Radius.circular(8.0))),
          padding: EdgeInsets.only(
              top: Utils.resizeWidthUtil(context, 30),
              left: Utils.resizeWidthUtil(context, 30),
              right: Utils.resizeWidthUtil(context, 30),
              bottom: Utils.resizeWidthUtil(context, 14)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _userInfo(index),
              _dashLine(),
              SizedBox(height: Utils.resizeHeightUtil(context, 14)),
              _requestContent(
                  address: listHistory[index]['location_address']['v'],
                  location: LatLng(num.parse(listHistory[index]['lat']['v']), num.parse(listHistory[index]['long']['v'])),
                  time: DateFormat('HH:mm dd/MM/yyyy')
                      .format(DateFormat('MM/dd/yyyy HH:mm:ss').parse(listHistory[index]['time_check']['v']))),
            ],
          )));

  Widget _userInfo(index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
              width: Utils.resizeWidthUtil(context, 160),
              height: Utils.resizeWidthUtil(context, 160),
              padding: EdgeInsets.only(
                  right: Utils.resizeWidthUtil(context, 30), bottom: Utils.resizeWidthUtil(context, 30)),
              child: AspectRatio(
                aspectRatio: 1 / 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                  child: FadeInImage.assetNetwork(
                      fit: BoxFit.cover,
                      placeholder: avatar_default,
                      image: '$avatarUrl${listHistory[index]['avatar']['v']}'),
                ),
              )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(
                  '${listHistory[index]['full_name']['v']} (${listHistory[index]['emp_id']['v']})',
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
                  '${listHistory[index]['name_role']['v']}' + ' (' + '${listHistory[index]['id_role']['v']}' + ')',
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
                      '${listHistory[index]['name_department']['v']}' +
                      ' (' +
                      '${listHistory[index]['id_department']['v']}' +
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

  Widget _requestContent({String address, String time, LatLng location}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Row(
          children: [
            Image.asset(
              ic_distance,
              width: Utils.resizeWidthUtil(context, 40),
              height: Utils.resizeWidthUtil(context, 40),
            ),
            SizedBox(width: Utils.resizeWidthUtil(context, 20)),
            Expanded(
              child: TKText(
                address,
                tkFont: TKFont.SFProDisplayMedium,
                style: TextStyle(
                    decoration: TextDecoration.none, fontSize: Utils.resizeWidthUtil(context, 30), color: only_color),
              ),
            ),
          ],
        ),
        SizedBox(height: Utils.resizeHeightUtil(context, 25)),
        Row(
          children: [
            Image.asset(
              ic_clock,
              width: Utils.resizeWidthUtil(context, 40),
              height: Utils.resizeWidthUtil(context, 40),
            ),
            SizedBox(width: Utils.resizeWidthUtil(context, 20)),
            TKText(
              time,
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: Utils.resizeWidthUtil(context, 24),
                  color: txt_grey_color_v4),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routers.mapTrackingView,
                      arguments: {
                        'location': location,
                        'title': address
                      });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Image.asset(
                      ic_map,
                      width: Utils.resizeWidthUtil(context, 40),
                      height: Utils.resizeWidthUtil(context, 40),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                    TKText(
                      'Xem bản đồ',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          decoration: TextDecoration.none,
                          fontSize: Utils.resizeWidthUtil(context, 24),
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        SizedBox(height: Utils.resizeWidthUtil(context, 10)),
      ]);

  Widget _modalBottomSheetFilter(StateSetter setModalState, BaseViewModel model) {
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
                _buildTimeOff(model, setModalState, 'Khoảng thời gian'),
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
                          if (listHistory.length > 0)
                            controller.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);

                          String userSelected =
                              _userSortSelected != null ? 'employee_id = ${_userSortSelected['id']}' : '';

                          String timeSelected = _dateTimeStartController.text != Utils.getString(context, txt_from) &&
                                  _dateTimeEndController.text != Utils.getString(context, txt_to)
                              ? ' from_time BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' '
                                  'AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                              : '';

                          filter = userSelected + '${userSelected != '' ? ' AND ' : ''}' + timeSelected;
                          getTotalRow(model);
                          getListHistory(model, nextIndex, isRefresh: true);
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
                            _userSortSelected = null;
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

  Widget _buildTimeOff(BaseViewModel model, StateSetter setModalState, String title) {
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
}
