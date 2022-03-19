import 'package:dotted_border/dotted_border.dart';
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
import 'package:gsot_timekeeping/ui/views/time_keeping_data_detail_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/date_time_picker_modify.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

DateFormat dateFormat = DateFormat('HH:mm dd/MM/yyyy');

class TimeKeepingDataView extends StatefulWidget {
  final dynamic data;

  TimeKeepingDataView(this.data);

  @override
  _TimeKeepingDataViewState createState() => _TimeKeepingDataViewState();
}

class _TimeKeepingDataViewState extends State<TimeKeepingDataView>
    with TickerProviderStateMixin {
  ScrollController controller;

  List<dynamic> listData = [];

  List<dynamic> listMenu = [
    {'name': 'Tất cả'},
    {
      'name': 'Thành công',
      'icon': Icon(Icons.check_circle, color: txt_success_color)
    },
    {'name': 'Thất bại', 'icon': Icon(Icons.cancel, color: txt_fail_color)},
  ];

  int currentIndex = 0;

  int nextIndex = 10;

  int status = 0;

  String filter = '';

  TextEditingController _dateTimeStartController = TextEditingController();

  TextEditingController _dateTimeEndController = TextEditingController();

  DateTime _startWorkingTime;

  DateTime _endWorkingTime;

  DateFormat dateFormatAPI = DateFormat('yyyy/MM/dd HH:mm');

  bool _compensationChecked = false;
  bool _qrCodeChecked = false;
  bool _nfcChecked = false;

  bool _outsideChecked = false;

  bool _timeChecked = false;

  bool _showLoadMore = false;

  bool _loading = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

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
    _dateTimeStartController.value = TextEditingValue(
        text: Utils.getString(context, txt_from),
        selection: _dateTimeStartController.selection);

    _dateTimeEndController.value = TextEditingValue(
        text: Utils.getString(context, txt_to),
        selection: _dateTimeEndController.selection);

    _startWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));

    _endWorkingTime = dateFormat.parse(dateFormat.format(DateTime.now()));
  }

  Future<String> refreshList(BaseViewModel model) async {
    currentIndex = 0;
    nextIndex = 10;
    getListData(model, currentIndex, nextIndex);
    return 'success';
  }

  _scrollListener(BaseViewModel model) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      if (listData.length < int.parse(listData[0]['total_row']['v'])) {
        currentIndex += 10;
        getListData(model, currentIndex, nextIndex, isLoadMore: true);
      }
    }
  }

  /*status list
  * 0 all
  * 1 success
  * 2 fail*/
  getListData(BaseViewModel model, int currentIndex, int nextIndex,
      {bool isLoadMore = false}) async {
    if (!isLoadMore)
      _loading = true;
    else
      _showLoadMore = true;
    setState(() {});
    List<dynamic> _listData = [];
    var response = await model.callApis({
      "table_name": (widget.data['data'].split('&')[0]).split('=')[1],
      "colname_sort": 'time_check',
      "type_sort": 'DESC',
      "current_index": currentIndex,
      "next_index": nextIndex,
      "moreExp": filter
    }, getListDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      _listData = response.data['data'];
      setState(() {
        if (currentIndex == 0) {
          listData.clear();
        }
        listData.addAll(_listData);
        _showLoadMore = false;
        _loading = false;
      });
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  _getInfo(String key) {
    return context.read<BaseResponse>().data['data'][0][key]['r'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        controller.addListener(() => _scrollListener(model));
        Future.delayed(Duration(seconds: 0), () {
          getListData(model, currentIndex, nextIndex);
        });
      },
      builder: (context, model, child) => Scaffold(
          appBar: appBarCustom(
              context,
              () => Navigator.pop(context),
              () => {
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
                              return _modalBottomSheet(setModalState, model);
                            })),
                      ),
                    )
                  },
              widget.data['title'],
              Icons.sort),
          body: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                width: double.infinity,
                color: bg_view_color,
              ),
              _list(context, model)
            ],
          )),
    );
  }

  Widget _list(BuildContext context, BaseViewModel model) {
    return RefreshIndicator(
        onRefresh: () => refreshList(model),
        key: _refreshIndicatorKey,
        child: _loading
            ? Container(
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : listData.length > 0
                ? Column(
                    children: <Widget>[
                      Expanded(
                        child: DraggableScrollbar.semicircle(
                          labelTextBuilder: (offset) {
                            final int currentItem = controller.hasClients
                                ? (controller.offset /
                                        controller.position.maxScrollExtent *
                                        listData.length)
                                    .floor()
                                : 0;
                            return Text(
                              "${currentItem + 1}",
                              style: TextStyle(color: Colors.white),
                            );
                          },
                          controller: controller,
                          child: ListView.builder(
                              physics: AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                  top: Utils.resizeHeightUtil(context, 25),
                                  left: Utils.resizeHeightUtil(context, 30),
                                  right: Utils.resizeHeightUtil(context, 30)),
                              controller: controller,
                              scrollDirection: Axis.vertical,
                              itemCount: listData.length,
                              itemBuilder: (context, index) => _item(index)),
                          heightScrollThumb:
                              Utils.resizeHeightUtil(context, 70),
                          backgroundColor: gradient_start_color,
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
                  ));
  }

  Widget _item(int index) {
    return InkWell(
        onTap: () {
          Navigator.push(
              context,
              PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 500),
                  pageBuilder: (_, __, ___) => TimeKeepingDataDetailView(
                        data: listData[index],
                        tab: status,
                      )));
        },
        child: Hero(
          tag: listData[index],
          child: SingleChildScrollView(
            child: Container(
                margin: EdgeInsets.only(
                    bottom: Utils.resizeHeightUtil(context, 25)),
                padding: EdgeInsets.only(
                    top: Utils.resizeWidthUtil(context, 30),
                    left: Utils.resizeWidthUtil(context, 30),
                    right: Utils.resizeWidthUtil(context, 30),
                    bottom: Utils.resizeWidthUtil(context, 14)),
                decoration: BoxDecoration(
                    color: white_color,
                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _userInfo(listData[index]['selfie']['r']),
                    _dashLine(),
                    SizedBox(height: Utils.resizeHeightUtil(context, 14)),
                    _processStatus(listData[index]['time_check']['r'],
                        listData[index]['Verify'])
                  ],
                )),
          ),
        ));
  }

  Widget _userInfo(String imageUrl) => Row(
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
                      image: '$avatarUrl$imageUrl'),
                ),
              )),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TKText(
                        _getInfo('full_name'),
                        tkFont: TKFont.SFProDisplayBold,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: Utils.resizeWidthUtil(context, 32),
                            color: txt_grey_color_v2),
                      ),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 24)),
                    Container(
                      height: Utils.resizeHeightUtil(context, 9),
                      width: Utils.resizeWidthUtil(context, 9),
                      decoration: BoxDecoration(
                          color: circle_point_color, shape: BoxShape.circle),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 14)),
                    Expanded(
                      flex: 1,
                      child: TKText(
                        _getInfo('emp_id'),
                        tkFont: TKFont.SFProDisplayMedium,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: TextStyle(
                            decoration: TextDecoration.none,
                            fontSize: Utils.resizeWidthUtil(context, 28),
                            color: txt_grey_color_v1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Utils.resizeHeightUtil(context, 7)),
                TKText(
                  _getInfo('name_role') + ' (' + _getInfo('id_role') + ')',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  tkFont: TKFont.SFProDisplayRegular,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      color: txt_grey_color_v1),
                ),
                SizedBox(height: Utils.resizeHeightUtil(context, 7)),
                TKText(
                  Utils.getString(context, txt_department_name) +
                      ' ' +
                      _getInfo('name_department') +
                      ' (' +
                      _getInfo('id_department') +
                      ')',
                  tkFont: TKFont.SFProDisplayRegular,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      decoration: TextDecoration.none,
                      fontSize: Utils.resizeWidthUtil(context, 28),
                      color: txt_grey_color_v1),
                ),
                SizedBox(height: Utils.resizeWidthUtil(context, 30))
              ],
            ),
          )
        ],
      );

  Widget _processStatus(String time, dynamic verify) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          TKText(
            time == ''
                ? ''
                : DateFormat.Hm()
                        .format(DateFormat('MM/dd/yyyy hh:mm:ss a').parse(time))
                        .toString() +
                    ' | ' +
                    DateFormat('dd/MM/yyyy')
                        .format(DateFormat('MM/dd/yyyy hh:mm:ss a').parse(time))
                        .toString(),
            tkFont: TKFont.SFProDisplayMedium,
            style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: Utils.resizeWidthUtil(context, 28),
                color: txt_grey_color_v2),
          ),
          Container(
              padding: EdgeInsets.only(
                left: Utils.resizeWidthUtil(context, 30),
                right: Utils.resizeWidthUtil(context, 30),
                bottom: Utils.resizeHeightUtil(context, 15),
                top: Utils.resizeHeightUtil(context, 15),
              ),
              decoration: BoxDecoration(
                  color: verify == null || verify['v'] == ''
                      ? txt_fail_color.withOpacity(0.12)
                      : txt_success_color.withOpacity(0.12),
                  borderRadius: BorderRadius.all(Radius.circular(5.0))),
              child: TKText(
                  verify == null || verify['v'] == ''
                      ? listMenu[2]['name']
                      : listMenu[1]['name'],
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    fontSize: Utils.resizeWidthUtil(context, 28),
                    color: verify == null || verify['v'] == ''
                        ? txt_fail_color
                        : txt_success_color,
                  ))),
        ],
      );

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

  Widget _buildTimeOff(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, Utils.getString(context, txt_time_checking)),
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
                    color: txt_grey_color_v1.withOpacity(0.3),
                    borderRadius: BorderRadius.all(Radius.circular(8.0))),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTimeOff(setModalState),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: _checkBox(setModalState, 'QRCode', 'QRCode'),
                  ),
                  Expanded(
                    flex: 5,
                    child: _checkBox(setModalState, 'NFC', 'NFC'),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: _checkBox(
                        setModalState,
                        Utils.getString(context, txt_compensation),
                        'compensation'),
                  ),
                  Expanded(
                    flex: 5,
                    child: _checkBox(setModalState,
                        Utils.getString(context, txt_external), 'outside'),
                  )
                ],
              ),
              boxTitle(
                  context, Utils.getString(context, txt_status_latching_work)),
              Row(
                children: <Widget>[
                  Expanded(
                      flex: 1,
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setModalState(() {
                              status = 0;
                            });
                          },
                          child: status == 0
                              ? _radioActive(listMenu[0]['name'])
                              : _radioInactive(listMenu[0]['name']))),
                  SizedBox(
                    width: Utils.resizeHeightUtil(context, 20),
                  ),
                  Expanded(
                      flex: 1,
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setModalState(() {
                              status = 1;
                            });
                          },
                          child: status == 1
                              ? _radioActive(listMenu[1]['name'])
                              : _radioInactive(listMenu[1]['name']))),
                  SizedBox(
                    width: Utils.resizeHeightUtil(context, 20),
                  ),
                  Expanded(
                      flex: 1,
                      child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            setModalState(() {
                              status = 2;
                            });
                          },
                          child: status == 2
                              ? _radioActive(listMenu[2]['name'])
                              : _radioInactive(listMenu[2]['name'])))
                ],
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
                      onPress: () async {
                        Navigator.of(context).pop();
                        nextIndex = 0;
                        if (listData.length > 0)
                          controller.animateTo(0.0,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        String _status = status != 0
                            ? status == 1
                                ? ' AND IsSuccess = 1'
                                : ' AND IsSuccess = 0'
                            : '';
                        String _time = _status + (_timeChecked
                            ? ' AND time_check BETWEEN \'${dateFormatAPI.format(_startWorkingTime)}\' AND \'${dateFormatAPI.format(_endWorkingTime)}\''
                            : '');
                        String _compensation = _compensationChecked
                            ? 'ISNULL(isBuCong, 0) = 1'
                            : '';
                        String _outside = _compensation + (_outsideChecked && _compensation == ''
                            ? 'ISNULL(isOvertimeCalendar, -1) <> -1'
                            : _outsideChecked && _compensation != ''
                            ? ' OR ISNULL(isOvertimeCalendar, -1) <> -1'
                            : '');
                        String _qrCode = _outside + (_qrCodeChecked && _outside == ''
                            ? 'ISNULL(IsQrCode, 0) = 1'
                            : _qrCodeChecked && _outside != ''
                            ? ' OR ISNULL(IsQrCode, 0) = 1'
                            : '');
                        String _nfc = _qrCode + (_nfcChecked && _qrCode == ''
                            ? 'ISNULL(IsRFID, 0) = 1'
                            : _nfcChecked && _qrCode != ''
                            ? ' OR ISNULL(IsRFID, 0) = 1'
                            : '');
                        filter = _time + (_nfc != '' ? ' AND (' + _nfc + ')' : '');
                        await refreshList(model);
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
                          filter = '';
                          _timeChecked = false;
                          _outsideChecked = false;
                          _compensationChecked = false;
                          status = 0;
                          _startWorkingTime = dateFormat
                              .parse(dateFormat.format(DateTime.now()));
                          _endWorkingTime = dateFormat
                              .parse(dateFormat.format(DateTime.now()));
                          _dateTimeStartController.text =
                              Utils.getString(context, txt_from);
                          _dateTimeEndController.text =
                              Utils.getString(context, txt_to);
                          //refreshList(model);
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
          )
        ],
      ),
    );
  }

  Widget _checkBox(StateSetter setModalState, String title, String check) =>
      ListTileTheme(
        contentPadding:
            EdgeInsets.only(right: Utils.resizeWidthUtil(context, 50)),
        child: CheckboxListTile(
          title: TKText(
            title,
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 32),
                color: txt_grey_color_v3),
          ),
          controlAffinity: ListTileControlAffinity.platform,
          value: check == 'compensation'
              ? _compensationChecked
              : check == 'outside'
                  ? _outsideChecked
                  : check == 'QRCode' ? _qrCodeChecked : _nfcChecked,
          onChanged: (bool value) {
            setModalState(() {
              switch (check) {
                case 'compensation':
                  _compensationChecked = value;
                  break;
                case 'outside':
                  _outsideChecked = value;
                  break;
                case 'QRCode':
                  _qrCodeChecked = value;
                  break;
                case 'NFC':
                  _nfcChecked = value;
              }
            });
          },
          activeColor: white_color,
          checkColor: only_color,
        ),
      );

  Widget _radioActive(String title) {
    return Container(
      height: Utils.resizeHeightUtil(context, 82),
      decoration: BoxDecoration(
          color: txt_yellow.withOpacity(0.07),
          border: Border.all(color: txt_yellow, width: 2),
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
      child: Center(
        child: TKText(
          title,
          tkFont: TKFont.SFProDisplayRegular,
          style: TextStyle(
              color: txt_yellow, fontSize: Utils.resizeWidthUtil(context, 30)),
        ),
      ),
    );
  }

  Widget _radioInactive(String title) {
    return Container(
      height: Utils.resizeHeightUtil(context, 82),
      decoration: BoxDecoration(
          color: bg_text_field,
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
      child: DottedBorder(
          borderType: BorderType.RRect,
          color: border_text_field,
          strokeWidth: Utils.resizeWidthUtil(context, 2),
          radius: Radius.circular(Utils.resizeWidthUtil(context, 10)),
          dashPattern: [
            Utils.resizeWidthUtil(context, 6),
            Utils.resizeWidthUtil(context, 3)
          ],
          child: Center(
            child: TKText(
              title,
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  color: txt_grey_color_v3,
                  fontSize: Utils.resizeWidthUtil(context, 30)),
            ),
          )),
    );
  }
}
