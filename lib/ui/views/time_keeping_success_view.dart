import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/models/working_report_main.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/working_report_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

DateFormat dateFormat = DateFormat('dd/MM/yyyy');
DateFormat defaultFormat = DateFormat('MM/dd/yyyy HH:mm:ss aaa');
DateFormat timeFormat = DateFormat('HH:mm');

class TimeKeepingSuccessView extends StatefulWidget {
  final dynamic data;

  TimeKeepingSuccessView(this.data);

  @override
  _TimeKeepingSuccessViewState createState() => _TimeKeepingSuccessViewState();
}

class _TimeKeepingSuccessViewState extends State<TimeKeepingSuccessView> {

  _getLocationName() {
    return widget.data['msg'].split('.')[1].toString().split(':').last;
  }

  _getTime() {
    return widget.data['msg']
        .split('Thời điểm:')[1]
        .toString()
        .split('.')[0]
        .replaceAll(('.'), '');
  }

  _getTypeTimekeeping() {
    return widget.data['msg'].split('Thời điểm:')[1].toString().split('.')[1];
  }

  _getInfo(String key, BuildContext context) {
    return context.watch<BaseResponse>().data['data'][0][key]['r'].toString();
  }

  String _getData({String key, String type}) {
    switch (type) {
      case 'day':
        if (widget.data['info']['working_day'].length > 0) {
          return widget.data['info']['working_day'][0][key]['r'].toString();
        }
        break;
      case 'month':
        if (widget.data['info']['working_KPI_report_month'].length > 0) {
          return widget.data['info']['working_KPI_report_month'][0][key]['r']
              .toString();
        }
        break;
      case 'plan':
        if (widget.data['info']['working_plan_report'].length > 0) {
          return widget.data['info']['working_plan_report'][0][key]['r'].toString();
        }
    }
    return '';
  }

   _getWorkingReportMain() async {
     showLoadingDialog(context);
     var data = {'date_working': dateFormat.format(DateTime.now()).toString()};
     var mainReportResponse = await BaseViewModel().callApis(
         data, getWorkingMain, method_post,
         isNeedAuthenticated: true, shouldSkipAuth: false);
     if (mainReportResponse.status.code == 200) {
       WorkingReportMain workingReportMain;
       if (mainReportResponse.data['data'].length > 0) {
         workingReportMain = WorkingReportMain(
             startTimeKeeping: mainReportResponse.data['data'][0]
             ['start_time_timecheck']['v'],
             endTimeKeeping: mainReportResponse.data['data'][0]
             ['end_time_timecheck']['v'],
             salaryWorkDay: '0',
             totalWorkday: '0');
         var dashboardResponse = await BaseViewModel().callApis(
             {'date': DateFormat('yyyy-MM-dd').format(DateTime.now())},
             workingMonthUrl,
             method_post,
             isNeedAuthenticated: true,
             shouldSkipAuth: false);
         Navigator.pop(context);
         if (dashboardResponse.status.code == 200) {
           if (dashboardResponse.data['data'].length > 0) {
             workingReportMain.salaryWorkDay =
             dashboardResponse.data['data'][0]['congtong_tinhluong']['v'];
             workingReportMain.totalWorkday =
             dashboardResponse.data['data'][0]['congchuan']['v'];
           } else {
             workingReportMain =
                 WorkingReportMain(salaryWorkDay: '0', totalWorkday: '0');
           }
         } else {
           workingReportMain =
               WorkingReportMain(salaryWorkDay: '0', totalWorkday: '0');
         }
         context
             .read<WorkingReportService>()
             .addWorkingReport(workingReportMain);
       }
     }
   }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushNamedAndRemoveUntil(context, Routers.main, (r) => false);
        return false;
      },
      child: Scaffold(
          body: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                _buildContent(context),
                _buildHeader(context),
              ],
            ),
          )),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final avatarFileName = context
        .watch<BaseResponse>()
        .data['data'][0]['avatar']['v']
        .toString()
        .replaceAll('/', '-');
    return Container(
      padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(
          top: Utils.resizeHeightUtil(context, 388),
          left: Utils.resizeWidthUtil(context, 30),
          right: Utils.resizeWidthUtil(context, 30)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        boxShadow: [
          BoxShadow(
            color: txt_grey_color_v1.withOpacity(0.3),
            spreadRadius: 3,
            blurRadius: 3,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: Utils.resizeHeightUtil(context, 120),
                width: Utils.resizeHeightUtil(context, 120),
                padding: EdgeInsets.only(
                    right: Utils.resizeWidthUtil(context, 30),
                    bottom: Utils.resizeWidthUtil(context, 30)),
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                  child: avatarFileName != null
                      ? Image.file(
                    Utils().fileFromDocsDir(avatarFileName),
                    fit: BoxFit.cover,
                  )
                      : FadeInImage.assetNetwork(
                      fit: BoxFit.cover,
                      placeholder: avatar_default,
                      image: '$avatarUrl${_getInfo('avatar', context)}'),
                ),
              ),
              Container(
                height: Utils.resizeHeightUtil(context, 120),
                padding:
                EdgeInsets.only(bottom: Utils.resizeWidthUtil(context, 30)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(_getInfo('full_name', context),
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 32),
                            color: txt_grey_color_v2),
                        tkFont: TKFont.SFProDisplaySemiBold),
                    TKText('ID: ' + _getInfo('emp_id', context),
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v1),
                        tkFont: TKFont.SFProDisplayRegular),
                  ],
                ),
              )
            ],
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TKText(Utils.getString(context, txt_position_timekeeping),
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 30),
                      color: txt_grey_color_v1),
                  tkFont: TKFont.SFProDisplayRegular),
              Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(left: Utils.resizeWidthUtil(context, 20)),
                  child: TKText(_getLocationName(),
                      maxLines: 2,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: only_color),
                      tkFont: TKFont.SFProDisplayMedium),
                ),
              ),
            ],
          ),
          SizedBox(height: Utils.resizeHeightUtil(context, 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TKText(Utils.getString(context, txt_time_timekeeping),
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 30),
                      color: txt_grey_color_v1),
                  tkFont: TKFont.SFProDisplayRegular),
              TKText(_getTime(),
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 30),
                      color: only_color),
                  tkFont: TKFont.SFProDisplayMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
            height: Utils.resizeHeightUtil(context, 463),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: [gradient_end_color, gradient_start_color]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  img_timekeeping_success,
                  height: Utils.resizeHeightUtil(context, 138),
                  width: Utils.resizeWidthUtil(context, 121),
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 25),
                ),
                TKText(Utils.getString(context, txt_timekeeping_success),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Utils.resizeWidthUtil(context, 36)),
                    tkFont: TKFont.SFProDisplayMedium),
                if (_getTypeTimekeeping() != ' ')
                  TKText(
                      _getTypeTimekeeping() != ' '
                          ? '(${_getTypeTimekeeping()})'
                          : '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: Utils.resizeWidthUtil(context, 28)),
                      tkFont: TKFont.SFProDisplayRegular),
                /*TKText(
                    data['mqtt'] != null ? 'Đã mở tủ số ${data['mqtt']}' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Utils.resizeWidthUtil(context, 36)),
                    tkFont: TKFont.SFProDisplayMedium),*/
              ],
            )),
        Container(
          height: Utils.resizeHeightUtil(context, 245),
          color: bg_view_color,
        ),
        if (_getData(key: 'date_working', type: 'day') != '')
          Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(
                  (_getData(key: 'date_working', type: 'day')) == ''
                      ? Utils.getString(context, txt_work_data_day) + ''
                      : Utils.getString(context, txt_work_data_day) +
                      ' ' +
                      dateFormat.format(defaultFormat.parse(
                          _getData(key: 'date_working', type: 'day'))),
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 34),
                      color: txt_grey_color_v3),
                  tkFont: TKFont.SFProDisplaySemiBold,
                ),
                SizedBox(height: 10),
                if (_getData(key: 'start_time_timecheck', type: 'day') != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TKText(Utils.getString(context, txt_time_define),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v1,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                      TKText(
                          (_getData(key: 'start_time_define', type: 'day') == ''
                              ? ''
                              : timeFormat.format(defaultFormat.parse(
                              _getData(
                                  key: 'start_time_define',
                                  type: 'day')))) +
                              ' - ' +
                              (_getData(key: 'end_time_define', type: 'day') ==
                                  ''
                                  ? ''
                                  : timeFormat.format(defaultFormat.parse(
                                  _getData(
                                      key: 'end_time_define',
                                      type: 'day')))),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                    ],
                  ),
                if (_getData(key: 'start_time_timecheck', type: 'day') != '' &&
                    _getData(key: 'end_time_timecheck', type: 'day') != '')
                  Divider(height: 10),
                if (_getData(key: 'start_time_timecheck', type: 'day') != '' &&
                    _getData(key: 'end_time_timecheck', type: 'day') != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TKText(Utils.getString(context, txt_timekeeping_in_out),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v1,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                      TKText(
                          '${timeFormat.format(defaultFormat.parse(_getData(key: 'start_time_timecheck', type: 'day')))}' +
                              ' - ' +
                              '${timeFormat.format(defaultFormat.parse(_getData(key: 'end_time_timecheck', type: 'day')))}',
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                    ],
                  ),
                if (_getData(key: 'thoigian_ditre_new', type: 'day') != '' &&
                    _getData(key: 'sophut_thoigian_disom', type: 'day') != '')
                  Divider(height: 10),
                if (_getData(key: 'thoigian_ditre_new', type: 'day') != '' &&
                    _getData(key: 'sophut_thoigian_disom', type: 'day') != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TKText(Utils.getString(context, txt_late),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v1,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                      TKText(
                          '${double.parse(_getData(key: 'thoigian_ditre_new', type: 'day')).toStringAsFixed(1)}\'/${double.parse(_getData(key: 'sophut_thoigian_disom', type: 'day')).toStringAsFixed(1)}\'',
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                    ],
                  ),
                if (_getData(key: 'thoigian_vesom_new', type: 'day') != '' ||
                    _getData(key: 'sophut_thoigian_vetre', type: 'day') != '')
                  Divider(height: 10),
                if (_getData(key: 'thoigian_vesom_new', type: 'day') != '' ||
                    _getData(key: 'sophut_thoigian_vetre', type: 'day') != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TKText(Utils.getString(context, txt_early),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v1,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                      TKText(
                          '${double.parse(_getData(key: 'thoigian_vesom_new', type: 'day')).toStringAsFixed(2)}/'
                              '${double.parse(_getData(key: 'sophut_thoigian_vetre', type: 'day')).toStringAsFixed(2)}',
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                    ],
                  ),
                if (_getData(key: 'working_factor_day', type: 'day') != '')
                  Divider(height: 10),
                if (_getData(key: 'working_factor_day', type: 'day') != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      TKText(Utils.getString(context, txt_work),
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v1,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                      TKText(
                          '${double.parse(_getData(key: 'working_factor_day', type: 'day')).toStringAsFixed(2)}/${_getData(key: 'working_factor', type: 'day')}',
                          tkFont: TKFont.SFProDisplayRegular,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30))),
                    ],
                  ),
              ],
            ),
          ),
        Container(
            height: Utils.resizeHeightUtil(context, 20), color: bg_view_color),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(15),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TKText(
                Utils.getString(context, txt_work_data_month) +
                    (_getData(key: 'date', type: 'month') == ''
                        ? ''
                        : ' ${DateFormat('MM/yyyy').format(defaultFormat.parse(_getData(key: 'date', type: 'month')))}'),
                style: TextStyle(
                    fontSize: Utils.resizeWidthUtil(context, 34),
                    color: txt_grey_color_v3),
                tkFont: TKFont.SFProDisplaySemiBold,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(Utils.getString(context, txt_work_standard),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v1,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                  TKText(
                      '${double.parse(_getData(key: 'congtong_lamviec', type: 'plan')).toStringAsFixed(2)}/${_getData(key: 'congchuan', type: 'plan')}',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                ],
              ),
              Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(Utils.getString(context, txt_off_allow_nonAllow),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v1,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                  TKText(
                      '${_getData(key: 'tong_nghi_co_phep', type: 'month')}/${_getData(key: 'tong_nghi_khong_phep', type: 'month')}',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                ],
              ),
              Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(Utils.getString(context, txt_count_late_early),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v1,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                  TKText(
                      '${_getData(key: 'tong_so_lan_ditre', type: 'month')}/${_getData(key: 'tong_so_lan_vesom', type: 'month')}',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                ],
              ),
              Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(Utils.getString(context, txt_count_early_late),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v1,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                  TKText(
                      '${_getData(key: 'tong_so_lan_disom', type: 'month')}/${_getData(key: 'tong_so_lan_vetre', type: 'month')}',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                ],
              ),
              Divider(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(Utils.getString(context, txt_lunch),
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v1,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                  TKText(widget.data['info']['working_plan_report'][0]['comtrua'] != null ? widget.data['info']['working_plan_report'][0]['comtrua']['v'] : '',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30))),
                ],
              ),
              SizedBox(height: 20),
              TKButton(
                Utils.getString(context, txt_go_home),
                width: MediaQuery.of(context).size.width,
                backgroundColor: gradient_end_color,
                onPress: () async {
                  await _getWorkingReportMain();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
