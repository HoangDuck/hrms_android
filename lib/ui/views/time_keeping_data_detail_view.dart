import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/show_image_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

DateFormat dateFormat = DateFormat('HH:mm dd/MM/yyyy');

class TimeKeepingDataDetailView extends StatefulWidget {
  final dynamic data;
  final int tab;

  TimeKeepingDataDetailView({this.data, this.tab});

  @override
  _TimeKeepingDataDetailViewState createState() =>
      _TimeKeepingDataDetailViewState();
}

class _TimeKeepingDataDetailViewState extends State<TimeKeepingDataDetailView> {
  Set<Marker> _marker = Set<Marker>();
  dynamic _genRow = {};

  @override
  void initState() {
    super.initState();
    _getGenRow();
    if (widget.data['lat']['r'] != '' || widget.data['long']['r'] != '')
      _marker.add(
        Marker(
          markerId:
              MarkerId(widget.data['lat']['r'] + widget.data['long']['r']),
          position: LatLng(double.parse(widget.data['lat']['r']),
              double.parse(widget.data['long']['r'])),
          icon: BitmapDescriptor.defaultMarker,
        ),
      );
  }

  _getGenRow() async {
    var response = await BaseViewModel().callApis(
        {"TbName": "vw_tb_hrms_chamcong_timesheet_success_all_mobile"},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200) {
      setState(() {
        _genRow = Utils.getTitleGenRowOnly(response.data['data']);
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  _getInfo(String key) {
    return context.watch<BaseResponse>().data['data'][0][key]['r'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_view_color,
      extendBodyBehindAppBar: true,
      appBar: appBarCustom(context, () => Navigator.pop(context), () => {},
          Utils.getString(context, txt_timekeeping_data_detail), null,
          hideBackground: true),
      body: Stack(
        children: <Widget>[
          _background(),
          _content(),
        ],
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

  Widget _content() => SafeArea(
        child: Container(
            child: SingleChildScrollView(
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
              Column(
                children: <Widget>[
                  _info(),
                  _genRow.length > 0
                      ? _contentDetail()
                      : Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          width: MediaQuery.of(context).size.width,
                          child: Center(child: CircularProgressIndicator()),
                        )
                ],
              )
            ],
          ),
        )),
      );

  Widget _info() => Hero(
        tag: widget.data,
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.only(
                left: Utils.resizeWidthUtil(context, 30),
                right: Utils.resizeWidthUtil(context, 30),
                bottom: Utils.resizeHeightUtil(context, 25)),
            padding: EdgeInsets.only(
                top: Utils.resizeWidthUtil(context, 30),
                left: Utils.resizeWidthUtil(context, 30),
                right: Utils.resizeWidthUtil(context, 30),
                bottom: Utils.resizeWidthUtil(context, 14)),
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
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowImageView(
                                  image:
                                      '$avatarUrl${widget.data['selfie']['r']}'),
                            ),
                          );
                        },
                        child: Container(
                          height: Utils.resizeWidthUtil(context, 160),
                          width: Utils.resizeWidthUtil(context, 160),
                          padding: EdgeInsets.only(
                            right: Utils.resizeWidthUtil(context, 30),
                            bottom: Utils.resizeWidthUtil(context, 30),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                Utils.resizeWidthUtil(context, 10)),
                            child: FadeInImage.assetNetwork(
                                fit: BoxFit.cover,
                                placeholder: avatar_default,
                                image:
                                    '$avatarUrl${widget.data['selfie']['r']}'),
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
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 32),
                                      color: txt_grey_color_v2),
                                ),
                              ),
                              SizedBox(
                                  width: Utils.resizeWidthUtil(context, 24)),
                              Container(
                                height: Utils.resizeHeightUtil(context, 9),
                                width: Utils.resizeWidthUtil(context, 9),
                                decoration: BoxDecoration(
                                    color: circle_point_color,
                                    shape: BoxShape.circle),
                              ),
                              SizedBox(
                                  width: Utils.resizeWidthUtil(context, 14)),
                              Expanded(
                                flex: 1,
                                child: TKText(
                                  _getInfo('emp_id'),
                                  tkFont: TKFont.SFProDisplayMedium,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 28),
                                      color: txt_grey_color_v1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Utils.resizeHeightUtil(context, 7)),
                          TKText(
                            _getInfo('name_role') +
                                ' (' +
                                _getInfo('id_role') +
                                ')',
                            tkFont: TKFont.SFProDisplayRegular,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: Utils.resizeWidthUtil(context, 28),
                                color: txt_grey_color_v1),
                          ),
                          SizedBox(height: Utils.resizeHeightUtil(context, 7)),
                          TKText(
                            Utils.getString(context, txt_department_name) +
                                ': ' +
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
                ),
                _dashLine(),
                SizedBox(height: Utils.resizeHeightUtil(context, 14)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    TKText(
                      widget.data['time_check']['r'] == ''
                          ? ''
                          : DateFormat.Hm()
                                  .format(DateFormat('MM/dd/yyyy hh:mm:ss a')
                                      .parse(widget.data['time_check']['r']))
                                  .toString() +
                              ' | ' +
                              DateFormat('dd/MM/yyyy')
                                  .format(DateFormat('MM/dd/yyyy hh:mm:ss a')
                                      .parse(widget.data['time_check']['r']))
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
                            color: widget.data['Verify'] == null ||
                                    widget.data['Verify']['v'] == ''
                                ? txt_fail_color.withOpacity(0.12)
                                : txt_success_color.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: TKText(
                            widget.data['Verify'] == null ||
                                    widget.data['Verify']['v'] == ''
                                ? 'Thất bại'
                                : 'Thành công',
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                              decoration: TextDecoration.none,
                              fontSize: Utils.resizeWidthUtil(context, 28),
                              color: widget.data['Verify'] == null ||
                                      widget.data['Verify']['v'] == ''
                                  ? txt_fail_color
                                  : txt_success_color,
                            ))),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  Widget _contentDetail() => Column(
        children: <Widget>[
          Container(
            width: MediaQuery.of(context).size.width,
            color: white_color,
            padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TKText(
                      _genRow['long']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    TKText(
                      widget.data['long']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TKText(
                      _genRow['lat']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    TKText(
                      widget.data['lat']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['location_id']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                    Expanded(
                      child: TKText(
                        widget.data['location_name']['r'],
                        tkFont: TKFont.SFProDisplaySemiBold,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: only_color),
                      ),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TKText(
                      _genRow['location_distance']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    TKText(
                      widget.data['location_distance']['v'] != ''
                          ? num.parse(widget.data['location_distance']['v'])
                              .toStringAsFixed(2)
                          : '',
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                SizedBox(height: Utils.resizeHeightUtil(context, 27)),
                Container(
                  height: Utils.resizeHeightUtil(context, 388),
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    child: GoogleMap(
                        scrollGesturesEnabled: false,
                        zoomControlsEnabled: false,
                        zoomGesturesEnabled: false,
                        myLocationButtonEnabled: false,
                        initialCameraPosition: CameraPosition(
                            zoom: 16,
                            target: widget.data['lat']['r'] != '' &&
                                    widget.data['long']['r'] != ''
                                ? LatLng(double.parse(widget.data['lat']['r']),
                                    double.parse(widget.data['long']['r']))
                                : Utils.latLngCompany),
                        mapType: MapType.normal,
                        markers: _marker),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: Utils.resizeHeightUtil(context, 20),
            color: bg_view_color,
          ),
          Container(
            color: white_color,
            padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['browser_id']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(
                      height: Utils.resizeHeightUtil(context, 10),
                    ),
                    TKText(
                      widget.data['browser_id']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['browser_id_last']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(
                      height: Utils.resizeHeightUtil(context, 10),
                    ),
                    TKText(
                      widget.data['browser_id_last']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                if ((widget.tab == 0 || widget.tab == 1) &&
                    widget.data['MatchValue']['r'] != '')
                  Column(
                    children: <Widget>[
                      Divider(
                        height: Utils.resizeHeightUtil(context, 30),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          TKText(
                            _genRow['MatchValue']['name'],
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v1),
                          ),
                          TKText(
                            widget.data['MatchValue']['r'] + '%',
                            tkFont: TKFont.SFProDisplaySemiBold,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v2),
                          )
                        ],
                      ),
                    ],
                  )
              ],
            ),
          ),
          Container(
            height: Utils.resizeHeightUtil(context, 20),
            color: bg_view_color,
          ),
          Container(
            color: white_color,
            padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['IsQrCode']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                    widget.data['IsQrCode']['r'] == 'True'
                        ? Icon(
                            Icons.check,
                            color: only_color,
                          )
                        : Icon(
                            Icons.indeterminate_check_box,
                            color: txt_grey_color_v1,
                          )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                if (widget.data['QrCodeAllow']['r'] != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TKText(
                        _genRow['QrCodeAllow']['name'],
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v1),
                      ),
                      SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                      Expanded(
                        child: TKText(
                          widget.data['QrCodeAllow']['r'],
                          tkFont: TKFont.SFProDisplaySemiBold,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: Utils.resizeWidthUtil(context, 30),
                              color: txt_grey_color_v2),
                        ),
                      )
                    ],
                  ),
                if (widget.data['QrCodeAllow']['r'] != '')
                  Divider(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['IsRFID']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                    widget.data['IsRFID']['r'] == 'True'
                        ? Icon(Icons.check)
                        : Icon(
                            Icons.indeterminate_check_box,
                            color: txt_grey_color_v1,
                          )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                if (widget.data['RFIDAllow']['r'] != '')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TKText(
                        _genRow['RFIDAllow']['name'],
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v1),
                      ),
                      SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                      Expanded(
                        child: TKText(
                          widget.data['RFIDAllow']['r'],
                          tkFont: TKFont.SFProDisplaySemiBold,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                              fontSize: Utils.resizeWidthUtil(context, 30),
                              color: txt_grey_color_v2),
                        ),
                      )
                    ],
                  ),
                if (widget.data['RFIDAllow']['r'] != '')
                  Divider(
                    height: Utils.resizeHeightUtil(context, 30),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TKText(
                      _genRow['IsOfflineApp']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                    widget.data['IsOfflineApp']['r'] == 'True'
                        ? Icon(Icons.check)
                        : Icon(
                            Icons.indeterminate_check_box,
                            color: txt_grey_color_v1,
                          )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                if (widget.tab == 0 &&
                    widget.data['reason']['r'].toString() != '' &&
                    widget.data['reason']['r'] == '1')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TKText(
                        _genRow['reason']['name'],
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v1),
                      ),
                      SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                      TKText(
                        widget.data['reason']['r'],
                        tkFont: TKFont.SFProDisplaySemiBold,
                        textAlign: TextAlign.end,
                        maxLines: 4,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v2),
                      )
                    ],
                  ),
                if (widget.data['IsSuccess']['r'] == '0')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TKText(
                        _genRow['reason']['name'],
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v1),
                      ),
                      SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                      TKText(
                        widget.data['reason']['r'],
                        tkFont: TKFont.SFProDisplaySemiBold,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 30),
                            color: txt_grey_color_v2),
                      ),
                      Divider(
                        height: Utils.resizeHeightUtil(context, 30),
                      ),
                    ],
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TKText(
                      _genRow['browser_info']['name'],
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    TKText(
                      widget.data['browser_info']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TKText(
                      'IPAddress',
                      tkFont: TKFont.SFProDisplayRegular,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v1),
                    ),
                    TKText(
                      widget.data['ipaddress']['r'],
                      tkFont: TKFont.SFProDisplaySemiBold,
                      style: TextStyle(
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          color: txt_grey_color_v2),
                    )
                  ],
                ),
                Divider(
                  height: Utils.resizeHeightUtil(context, 30),
                ),
                widget.data['browser_desc']['r'].length > 30
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TKText(
                            _genRow['browser_desc']['name'],
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v1),
                          ),
                          SizedBox(
                            height: Utils.resizeHeightUtil(context, 10),
                          ),
                          TKText(
                            widget.data['browser_desc']['r'],
                            tkFont: TKFont.SFProDisplaySemiBold,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v2),
                          )
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          TKText(
                            _genRow['browser_desc']['name'],
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v1),
                          ),
                          SizedBox(
                            height: Utils.resizeHeightUtil(context, 10),
                          ),
                          TKText(
                            widget.data['browser_desc']['r'],
                            tkFont: TKFont.SFProDisplaySemiBold,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                color: txt_grey_color_v2),
                          )
                        ],
                      )
              ],
            ),
          ),
          Container(
            height: Utils.resizeHeightUtil(context, 30),
            color: bg_view_color,
          )
        ],
      );
}
