import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class SalaryView extends StatefulWidget {
  final String title;

  SalaryView(this.title);

  @override
  _SalaryViewState createState() => _SalaryViewState();
}

class _SalaryViewState extends State<SalaryView> {
  DateTime dateTimeCalendar;
  String dateForApi;
  DateFormat dateTimeFormat = DateFormat('yyyy-MM-dd');
  DateFormat calendarFormat = DateFormat('MM/yyyy');
  String calendarTextHeader;
  List<dynamic> salaryListData = [];

  @override
  void initState() {
    super.initState();
    dateForApi = dateTimeFormat.format(DateTime.now());
    dateTimeCalendar = DateTime.now();
    calendarTextHeader = calendarFormat.format(DateTime.now());
  }

  getData(BaseViewModel model, String date) async {
    salaryListData.clear();
    var salPayrollDataMonth = await model.callApis({'month': date}, getCalendarTableSalPayrollDataMonth, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false, isShowError: true);
    try {
      if (salPayrollDataMonth.status.code == 200)
        for (var item in salPayrollDataMonth.data['data'])
          salaryListData.add({
            'name': item['Name']['v'],
            'value': item['Value']['v'],
            'IsBold': item['IsBold']['v'] == 'False' ? false : true,
            'VnName': item['VnName']['v'],
            'VnValue': item['VnValue']['v']
          });
    } catch (e) {
      print(e);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getData(model, dateForApi);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () => {}, widget.title, null),
        body: Container(
          decoration: BoxDecoration(color: main_background),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              _headerCalendar(context, model),
              salaryListData.length > 0 ? _titleWidget() : SizedBox.shrink(),
              Expanded(child: _bodyDashboard())
            ],
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
                getData(model, dateForApi);
                dateTimeCalendar = date;
                calendarTextHeader = calendarFormat.format(date);
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

  Widget _bodyDashboard() {
    return salaryListData.length > 0
        ? Container(
            margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 15)),
            decoration: BoxDecoration(color: Colors.white),
            child: ListView.builder(
                //physics: NeverScrollableScrollPhysics(),
                itemCount: salaryListData.length,
                //shrinkWrap: true,
                itemBuilder: (context, index) {
                  return _itemBody(
                      salaryListData[index]['name'],
                      salaryListData != null ? salaryListData[index]['value'] : Utils.getString(context, txt_waiting),
                      salaryListData[index]['IsBold']);
                }))
        : Center(
      child: TKText(
        Utils.getString(context, txt_non_request_data),
        tkFont: TKFont.SFProDisplayRegular,
        style: TextStyle(color: txt_grey_color_v6, fontSize: Utils.resizeWidthUtil(context, 30)),
      ),
    );
  }

  Widget _titleWidget() {
    return Padding(
        padding: EdgeInsets.fromLTRB(Utils.resizeWidthUtil(context, 30), Utils.resizeWidthUtil(context, 30),
            Utils.resizeWidthUtil(context, 30), Utils.resizeWidthUtil(context, 20)),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TKText(
                salaryListData[0]['VnName'],
                tkFont: TKFont.SFProDisplayBold,
                style: TextStyle(color: txt_grey_color_v6, fontSize: Utils.resizeWidthUtil(context, 32)),
              ),
            ),
            TKText(
              salaryListData[0]['VnValue'],
              tkFont: TKFont.SFProDisplayBold,
              style: TextStyle(color: txt_grey_color_v6, fontSize: Utils.resizeWidthUtil(context, 32)),
            )
          ],
        ));
  }

  Widget _itemBody(String title, String value, bool isBold) {
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
                    fontSize: Utils.resizeWidthUtil(context, 30),
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            TKText(
              value,
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  color: txt_grey_color_v3,
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            )
          ],
        ));
  }
}
