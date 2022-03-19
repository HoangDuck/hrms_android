import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/title_content_widget.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_title_edit_card.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

DateFormat dateFormat = DateFormat('dd/MM/yyyy');

DateFormat timeFormat = DateFormat('HH:mm');

class CompensationRegisterView extends StatefulWidget {
  @override
  _CompensationRegisterViewState createState() =>
      _CompensationRegisterViewState();
}

class _CompensationRegisterViewState extends State<CompensationRegisterView> {
  BaseResponse _user;

  TextEditingController _dateController = TextEditingController();

  TextEditingController _timeController = TextEditingController();

  TextEditingController _reasonController = TextEditingController();

  List<dynamic> _listCompensationType = [];

  int _typeSelected = 0;

  String _startTime;

  String _endTime;

  int _countCompensation;

  DateTime initialDate = DateTime.now();

  String _timeID;

  @override
  void initState() {
    super.initState();
    _dateController.value = TextEditingValue(
        text: dateFormat.format(DateTime.now()),
        selection: _dateController.selection);
  }

  @override
  void dispose() {
    if (!mounted) {
      _dateController.dispose();
      _timeController.dispose();
      _reasonController.dispose();
    }
    super.dispose();
  }

  bool checkEmpty() {
    if (_reasonController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty) {
      showMessageDialog(context,
          description: Utils.getString(context, txt_text_field_empty),
          onPress: () => Navigator.pop(context));
      return false;
    }
    return true;
  }

  void checkSelected(String selected) {
    for (int i = 0; i < _listCompensationType.length; i++) {
      if (_listCompensationType[i][1] == selected) {
        setState(() {
          _typeSelected = i;
          if (i == 0) {
            _timeController.text = _startTime;
          } else
            _timeController.text = _endTime;
        });
      }
    }
  }

  void getTimeDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"date_late": _dateController.text}, timeDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      if (response.data['data'].length != 0) {
        var responseV2 = await model.callApis(
            {"time_id": response.data['data'][0]['ID']},
            timeDefineCompensationUrl,
            method_post,
            isNeedAuthenticated: true,
            shouldSkipAuth: false);
        if (responseV2.status.code == 200) {
          setState(() {
            _timeID = response.data['data'][0]['ID'];
            _startTime = responseV2.data['data'][0]['start_time']['r'];
            _endTime = responseV2.data['data'][0]['end_time']['r'];
            if (_timeController.text.isEmpty) _timeController.text = _startTime;
          });
        }
      } else
        setState(() {
          _startTime = '';
          _endTime = '';
          _timeController.text = '';
        });
    } else
      return showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
  }

  void getCompensationType(BaseViewModel model) async {
    var listType = List<dynamic>();
    var typeResponse = await model.callApis(
        {}, compensationTypeUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (typeResponse.status.code == 200) {
      for (var type in typeResponse.data['data']) {
        listType.add([type['ID'], type['name_type']['r']]);
      }
      setState(() {
        _listCompensationType = listType;
      });
    }
  }

  void getCompensationSum(BaseViewModel model) async {
    var response = await model.callApis(
        {"date_time_sheet": _dateController.text},
        compensationSumUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _countCompensation = num.parse(response.data['data'][0]['result']['r']);
      });
    }
  }

  void submitData(BaseViewModel model) async {
    if (checkEmpty()) {
      showLoadingDialog(context);
      var encryptData =
          await Utils.encrypt("vw_tb_hrms_chamcong_add_timesheet_submit");
      var data = {
        "tbname": encryptData,
        "employee_id": _user.data['data'][0]['ID'],
        "date_time_sheet": _dateController.text,
        "timesheet_type": _listCompensationType[_typeSelected][0],
        "timesheet": _timeController.text,
        "reason": _reasonController.text,
        "time_id": _timeID
      };
      var submitResponse = await model.callApis(data, addDataUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      Navigator.pop(context);
      if (submitResponse.status.code == 200) {
        Navigator.pop(context, 1);
      } else {
        Navigator.pop(context);
        showMessageDialog(context,
            description: Utils.getString(context, txt_register_failed),
            onPress: () => Navigator.pop(context));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _user = context.watch<BaseResponse>();
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        Future.delayed(new Duration(milliseconds: 0), () {
          getTimeDefine(model);
          getCompensationType(model);
          getCompensationSum(model);
        });
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
          Utils.closeKeyboard(context);
          submitData(model);
        }, Utils.getString(context, txt_register_compensation),
            Icons.file_upload),
        body: Container(
          padding: EdgeInsets.only(
              right: Utils.resizeHeightUtil(context, 10),
              left: Utils.resizeHeightUtil(context, 10)),
          child: GestureDetector(
            onTap: () => Utils.closeKeyboard(context),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                  GestureDetector(
                    onTap: () {
                      showDatePicker(
                        context: context,
                        initialDate: initialDate,
                        firstDate: DateTime(
                            dateFormat
                                .parse(_dateController.text)
                                .year,
                            dateFormat
                                .parse(_dateController.text)
                                .month,
                            dateFormat
                                .parse(_dateController.text)
                                .day - 7),
                        lastDate: DateTime.now(),
                      ).then((value) {
                        setState(() {
                          if (value == null) return;
                          initialDate = value;
                          _dateController.text = dateFormat.format(value);
                          getTimeDefine(model);
                          getCompensationSum(model);
                        });
                      });
                    },
                    child: TKTitleEditCard(_dateController,
                        title: txt_working_day, enable: false),
                  ),
                  Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      child: Container(
                          padding: EdgeInsets.all(
                              Utils.resizeHeightUtil(context, 10)),
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: MediaQuery.of(context).size.width,
                                  height: Utils.resizeHeightUtil(context, 20),
                                  alignment: Alignment.centerLeft,
                                  child: TKText(
                                    Utils.getString(
                                        context, txt_compensation_type),
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize:
                                          Utils.resizeHeightUtil(context, 20) *
                                              0.78,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                    height: Utils.resizeHeightUtil(context, 5)),
                                _listCompensationType.length == 0
                                    ? CircularProgressIndicator()
                                    : Container(
                                        height:
                                            Utils.resizeHeightUtil(context, 33),
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          underline: SizedBox(),
                                          items: _listCompensationType.map(
                                              (dynamic dropDownStringItem) {
                                            return DropdownMenuItem<String>(
                                                value: dropDownStringItem[1],
                                                child: Container(
                                                    child: TKText(
                                                  dropDownStringItem[1],
                                                  style: TextStyle(
                                                      fontSize: Utils
                                                          .resizeHeightUtil(
                                                              context, 20)),
                                                  tkFont: TKFont.BOLD,
                                                  maxLines: 1,
                                                )));
                                          }).toList(),
                                          onChanged: (String selected) {
                                            setState(() {
                                              checkSelected(selected);
                                            });
                                          },
                                          value: _listCompensationType[
                                              _typeSelected][1],
                                        ),
                                      )
                              ]))),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: _startTime == null
                            ? titleContentWidget(context, txt_start_time,
                                Utils.getString(context, txt_waiting),
                                color: disabled_color,
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(10))
                            : titleContentWidget(
                                context, txt_start_time, _startTime,
                                color: disabled_color,
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(10)),
                      ),
                      Expanded(
                        flex: 1,
                        child: _endTime == null
                            ? titleContentWidget(context, txt_start_time,
                                Utils.getString(context, txt_waiting),
                                color: disabled_color,
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(10))
                            : titleContentWidget(
                                context, txt_start_time, _endTime,
                                color: disabled_color,
                                margin: EdgeInsets.all(5),
                                padding: EdgeInsets.all(10)),
                      )
                    ],
                  ),
                  GestureDetector(
                      onTap: () {
                        showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                    DateFormat("HH:mm").parse(_startTime)))
                            .then((value) {
                          if (value.hour.toDouble() >=
                                  TimeOfDay.fromDateTime(
                                          DateFormat("HH:mm").parse(_startTime))
                                      .hour
                                      .toDouble() &&
                              value.hour.toDouble() <=
                                  TimeOfDay.fromDateTime(
                                          DateFormat("HH:mm").parse(_endTime))
                                      .hour
                                      .toDouble()) {
                            setState(() {
                              _timeController.text = timeFormat.format(
                                  timeFormat
                                      .parse("${value.hour}:${value.minute}"));
                            });
                          } else
                            showMessageDialog(context,
                                description: Utils.getString(
                                    context, txt_error_register_day_off_time),
                                onPress: () => Navigator.pop(context));
                        });
                      },
                      child: TKTitleEditCard(_timeController,
                          title: txt_plan_time_late_early, enable: false)),
                  _countCompensation == null
                      ? titleContentWidget(context, txt_compensation_count,
                      Utils.getString(context, txt_waiting),
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10))
                      : titleContentWidget(context, txt_compensation_count,
                      _countCompensation.toString(),
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  TKTitleEditCard(
                    _reasonController,
                    title: txt_reason_title,
                    errMess: Utils.getString(context, txt_text_field_empty),
                    isValidate: true,
                  ),
                  SizedBox(
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.05,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
