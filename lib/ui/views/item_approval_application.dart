import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ItemApprovalApplication extends StatefulWidget {
  final List<dynamic> list;

  final List<dynamic> statusProgressList;

  final int statusSelected;

  final int index;

  final Function clickSelected;

  final Function callbackRefresh;

  final Animation animation;

  ItemApprovalApplication(
      {this.list,
      this.index = 0,
      this.clickSelected,
      this.statusSelected,
      this.animation,
      this.callbackRefresh,
      this.statusProgressList});

  @override
  _ItemApprovalApplicationState createState() =>
      _ItemApprovalApplicationState();
}

class _ItemApprovalApplicationState extends State<ItemApprovalApplication> {

  List<dynamic> listLocation = [];

  @override
  void initState() {
    super.initState();
    if(widget.list[widget.index]['PathGPS'] != null && widget.list[widget.index]['PathGPS']['v'] != '')
      try {
        listLocation = jsonDecode('[${widget.list[widget.index]['PathGPS']['v']}]');
      } catch (e) {
        print(e);
      }
  }

  @override
  Widget build(BuildContext context) {
    dynamic statusProgress = widget.statusProgressList.where((item) => item['id'] == widget.list[widget.index]['trang_thai_duyet']['v']).toList()[0];
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: widget.animation, curve: Interval(0.5, 1.0)),
      axisAlignment: 0.5,
      child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                PageRouteBuilder(
                    transitionDuration: Duration(milliseconds: 500),
                    pageBuilder: (_, __, ___) => RequestDataDetailView(
                        permission: 1,
                        data: widget.list[widget.index],
                        tabName: widget.list[widget.index]
                            ['workflow_define_type_id']['r'],
                        tbName: widget.list[widget.index]['detail_name']['v'],
                        status: statusProgress))).then(
                (value) => widget.callbackRefresh());
            //permission 0: employee
            //permission 1: owner
          },
          child: Hero(
            tag: 'info${widget.list[widget.index]}',
            child: SingleChildScrollView(
                child: Container(
                    margin: EdgeInsets.only(
                        bottom: Utils.resizeHeightUtil(context, 25)),
                    decoration: BoxDecoration(
                        color:
                            widget.list[widget.index]['is_checked']['v'] == '0'
                                ? white_color
                                : only_color.withOpacity(0.1),
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
                        _userInfo(widget.list[widget.index], widget.index),
                        SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                        _dashLine(),
                        SizedBox(height: Utils.resizeHeightUtil(context, 14)),
                        _requestContent(
                            title: widget.list[widget.index]
                                ['workflow_define_type_id'],
                            type: widget.list[widget.index]['request_type']
                                ['v'],
                            value: widget.list[widget.index]['quota']['v'],
                            valueType: widget.list[widget.index]['quota_type']
                                ['v'],
                            time: widget.list[widget.index]
                                            ['workflow_define_type_id']['v'] ==
                                        '3' ||
                                    widget.list[widget.index]
                                            ['workflow_define_type_id']['v'] ==
                                        '4'
                                ? widget.list[widget.index]['to_time']['r']
                                : widget.list[widget.index]['from_time']['r'] +
                                    ' - ' +
                                    widget.list[widget.index]['to_time']['r'],
                            reason: widget.list[widget.index]['content']['r']),
                        SizedBox(height: Utils.resizeHeightUtil(context, 20)),
                        _processStatus(widget.list[widget.index], statusProgress),
                      ],
                    ))),
          )),
    );
//    );
  }

  Widget _userInfo(dynamic user, int index) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              widget.clickSelected();
            },
            child: Container(
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
                  child: widget.list[index]['is_checked']['v'] == '0'
                      ? FadeInImage.assetNetwork(
                          fit: BoxFit.cover,
                          placeholder: avatar_default,
                          image: '$avatarUrl${user['avatar']['v'].toString()}')
                      : Image.asset(
                          ic_check,
                          color: only_color,
                        ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TKText(
                  '${user['employee_id']['r'].toString()}',
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
                  '${user['role_id']['r'].toString()}',
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
                      ': '
                          '${user['org_id']['r'].toString()}',
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

  Widget _requestContent(
          {dynamic title,
          String type,
          String value,
          String valueType,
          String time,
          String reason}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        TKText(
          '${Utils.getString(context, txt_request)} ${title['r']}',
          tkFont: TKFont.SFProDisplayBold,
          style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: Utils.resizeWidthUtil(context, 36),
              color: only_color),
        ),
        SizedBox(height: Utils.resizeHeightUtil(context, 10),),
        widget.list[widget.index]['PathGPS'] != null && widget.list[widget.index]['PathGPS']['v'] != ''
            ? ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: listLocation.length,
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
                                '[${widget.list[index]['PathGPS']['v']}]')
                                .length
                            ? 0
                            : 20),
                  )
                ],
              );
            }) :
        TKText(
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

  Widget _processStatus(dynamic data, dynamic statusProgress) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        TKText(
          data['completedate']['v'] != ''
              ? DateFormat('HH:mm dd/MM/yyyy').format(
                  DateFormat('MM/dd/yyyy HH:mm:ss a')
                      .parse(data['completedate']['v']))
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
                color: Color(int.parse(statusProgress['color']))
                    .withOpacity(0.12),
                borderRadius: BorderRadius.all(Radius.circular(5.0))),
            child: TKText(
              statusProgress['name'],
              tkFont: TKFont.SFProDisplayMedium,
              style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: Utils.resizeWidthUtil(context, 28),
                  color: Color(int.parse(statusProgress['color']))),
            )),
      ],
    );
  }
}
