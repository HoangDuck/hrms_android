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

class SupportedRegisterView extends StatefulWidget {
  final BaseResponse _user;

  SupportedRegisterView(this._user);

  @override
  _SupportedRegisterViewState createState() => _SupportedRegisterViewState();
}

class _SupportedRegisterViewState extends State<SupportedRegisterView> {
  TextEditingController _companyEmailEdtController = TextEditingController();

  TextEditingController _phoneEdtController = TextEditingController();

  int _typeSelected = 0;
  int _typeDetailSelected = 0;

  List<dynamic> _majorsList = [];
  List<dynamic> _majorsDetailsList = [];

  @override
  void initState() {
    super.initState();
    _companyEmailEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['email_company']['r'].trim() ?? '',
        selection: _companyEmailEdtController.selection);

    _phoneEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['phone']['r'].trim() ?? '',
        selection: _phoneEdtController.selection);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        Future.delayed(new Duration(milliseconds: 0), () {
          getMajors(model, () {
            getMajorsDetails(model);
          });
        });
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () {
          Utils.closeKeyboard(context);
        }, Utils.getString(context, txt_title_register_supported),
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
                  TKText("Thông tin người dùng"),
                  titleContentWidget(
                      context, txt_support_code, "MANV/YY/MM/DD/XXXX",
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  titleContentWidget(context, txt_full_name,
                      widget._user.data['data'][0]['full_name']['r'],
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  titleContentWidget(
                      context, txt_company_name, "Công ty GSOT(C08)",
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  titleContentWidget(context, txt_department_name,
                      "Truyền thông Online(D0008)",
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  titleContentWidget(context, txt_role_name,
                      "Bán hàng doanh nghiệp(C08-D08-P023)",
                      color: disabled_color,
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.all(10)),
                  TKTitleEditCard(_companyEmailEdtController,
                      title: txt_company_email,
                      errMess: Utils.getString(context, txt_text_field_empty),
                      isValidate: true),
                  TKTitleEditCard(_phoneEdtController,
                      title: txt_phone,
                      errMess: Utils.getString(context, txt_text_field_empty),
                      isValidate: true),
                  SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                  TKText("Thông tin hỗ trợ"),
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
                                    Utils.getString(context, txt_majors),
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
                                Container(
                                  height: Utils.resizeHeightUtil(context, 33),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: _majorsList
                                        .map<DropdownMenuItem<String>>(
                                            (dynamic dropDownStringItem) {
                                      return DropdownMenuItem<String>(
                                          value: dropDownStringItem[1],
                                          child: Container(
                                              child: TKText(
                                            dropDownStringItem[1],
                                            style: TextStyle(
                                                fontSize:
                                                    Utils.resizeHeightUtil(
                                                        context, 20)),
                                            tkFont: TKFont.BOLD,
                                            maxLines: 1,
                                          )));
                                    }).toList(),
                                    onChanged: (String selected) {
                                      setState(() {
                                        checkSelected(selected, _majorsList,
                                            'majorsList', model);
                                      });
                                    },
                                    value: _majorsList.length > 0
                                        ? _majorsList[_typeSelected][1]
                                        : '',
                                  ),
                                ),
                              ]))),
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
                                        context, txt_majors_details),
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
                                Container(
                                  height: Utils.resizeHeightUtil(context, 33),
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: _majorsDetailsList
                                        .map<DropdownMenuItem<String>>(
                                            (dynamic dropDownStringItem) {
                                      return DropdownMenuItem<String>(
                                          value: dropDownStringItem[1],
                                          child: Container(
                                              child: TKText(
                                            dropDownStringItem[1],
                                            style: TextStyle(
                                                fontSize:
                                                    Utils.resizeHeightUtil(
                                                        context, 20)),
                                            tkFont: TKFont.BOLD,
                                            maxLines: 1,
                                          )));
                                    }).toList(),
                                    onChanged: (String selected) {
                                      setState(() {
                                        checkSelected(
                                            selected,
                                            _majorsDetailsList,
                                            'majorsDetailsList',
                                            model);
                                      });
                                    },
                                    value: _majorsDetailsList.length > 0
                                        ? _majorsDetailsList[
                                            _typeDetailSelected][1]
                                        : '',
                                  ),
                                ),
                              ]))),
                  SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  dynamic checkValidValue() {
    if (_phoneEdtController.text.isEmpty ||
        _phoneEdtController.text.length < 10 ||
        _companyEmailEdtController.text.isEmpty) {
      showMessageDialog(context,
          description: Utils.getString(context, txt_info_incorrect),
          onPress: () => Navigator.pop(context));
      return null;
    }
    var data = {};

    if (_companyEmailEdtController.text !=
        widget._user.data['data'][0]['email_company']['r'].trim())
      data = {
        ...data,
        ...{"email_company": _companyEmailEdtController.text}
      };

    if (_phoneEdtController.text !=
        widget._user.data['data'][0]['phone']['r'].trim())
      data = {
        ...data,
        ...{"phone": _phoneEdtController.text}
      };

    return data;
  }

  void checkSelected(
      String selected, List<dynamic> list, String type, BaseViewModel model) {
    for (int i = 0; i < list.length; i++) {
      switch (type) {
        case 'majorsList':
          if (list[i][1] == selected)
            setState(() {
              _typeSelected = i;
              getMajorsDetails(model);
            });
          break;
        case 'majorsDetailsList':
          if (list[i][1] == selected)
            setState(() {
              _typeDetailSelected = i;
            });
          break;
      }
    }
  }

  void getMajors(BaseViewModel model, Function callback) async {
    var majorsList = List<dynamic>();
    var response = await model.callApis({}, getMajorsUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var type in response.data['data']) {
        majorsList.add([type['ID'], type['TenChiTietDanhMuc']['r']]);
      }
      setState(() {
        _majorsList = majorsList;
        callback();
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getMajorsDetails(BaseViewModel model) async {
    var groupList = List<dynamic>();
    var response = await model.callApis(
        {"id_nghiepvu": _majorsList[_typeSelected][0]},
        GetMajorsDetailsUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var type in response.data['data']) {
        groupList.add([type['ID'], type['TenDanhMuc']['r']]);
      }
      setState(() {
        _majorsDetailsList = groupList;
      });
    }
  }

  @override
  void dispose() {
    if (!mounted) {
      _companyEmailEdtController.dispose();
      _phoneEdtController.dispose();
    }
    super.dispose();
  }
}
