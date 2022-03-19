import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:intl/intl.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:provider/provider.dart';

class EditEmployeeOwnerView extends StatefulWidget {
  final data;

  EditEmployeeOwnerView(this.data);

  @override
  _EditEmployeeOwnerViewState createState() => _EditEmployeeOwnerViewState();
}

class _EditEmployeeOwnerViewState extends State<EditEmployeeOwnerView> {
  BaseResponse _user;
  final dateTimeFormat = DateFormat("dd/MM/yyyy");

  TextEditingController _idEdtController = TextEditingController();
  TextEditingController _fullNameEdtController = TextEditingController();
  TextEditingController _dobEdtController = TextEditingController();
  TextEditingController _phoneEdtController = TextEditingController();
  TextEditingController _emailEdtController = TextEditingController();
  TextEditingController _emailCompanyEdtController = TextEditingController();
  TextEditingController _idNoEdtController = TextEditingController();
  TextEditingController _currentAddressEdtController = TextEditingController();
  TextEditingController _addressEdtController = TextEditingController();
  TextEditingController _testDateEdtController = TextEditingController();
  TextEditingController _endDateEdtController = TextEditingController();

  dynamic _genRow = {};
  List<dynamic> _genderList = [];
  List<dynamic> _departmentList = [];
  List<dynamic> _roleList = [];
  List<dynamic> _workStatusList = [];

  bool _forceErrorFullName = false;
  bool _forceErrorID = false;
  bool _forceErrorPhone = false;
  bool _forceErrorEmail = false;
  bool _forceErrorEmailCom = false;
  bool _forceErrorNo = false;
  bool _forceErrorCurrentAddress = false;
  bool _forceErrorAddress = false;
  bool _enableUpdateButton = false;
  bool _isUpdated = false;

  dynamic _orgSelected;
  dynamic data;
  dynamic _roleSelected;
  dynamic _statusSelected;

  String _initDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  int _genderSelected = -1;

  @override
  void initState() {
    super.initState();
    _user = context.read<BaseResponse>();
    if (widget.data['type'].contains('update'))
      initData();
    else {
      _fullNameEdtController.addListener(_onTextFieldAddChange);
      _emailEdtController.addListener(_onTextFieldAddChange);
      _idEdtController.addListener(_onTextFieldAddChange);
      _idNoEdtController.addListener(_onTextFieldAddChange);
      _phoneEdtController.addListener(_onTextFieldAddChange);
      _emailCompanyEdtController.addListener(_onTextFieldAddChange);
      _idNoEdtController.addListener(_onTextFieldAddChange);
      _currentAddressEdtController.addListener(_onTextFieldAddChange);
      _addressEdtController.addListener(_onTextFieldAddChange);
    }
  }

  @override
  void dispose() {
    if (!mounted) {
      _idEdtController.dispose();
      _phoneEdtController.dispose();
      _fullNameEdtController.dispose();
      _dobEdtController.dispose();
      _addressEdtController.dispose();
      _emailEdtController.dispose();
      _emailCompanyEdtController.dispose();
      _idNoEdtController.dispose();
      _currentAddressEdtController.dispose();
      _addressEdtController.dispose();
      _testDateEdtController.dispose();
    }
    super.dispose();
  }

  initData() {
    _idEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['emp_id']['v'].trim() ?? '',
        selection: _idEdtController.selection);
    _fullNameEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['full_name']['v'].trim() ?? '',
        selection: _fullNameEdtController.selection);
    if (widget.data['dataItem']['test_date']['v'] != '')
      _testDateEdtController.value = TextEditingValue(
          text: dateTimeFormat.format(DateFormat("MM/dd/yyyy HH:mm:ss aaa")
              .parse(widget.data['dataItem']['test_date']['v'])),
          selection: _testDateEdtController.selection);
    _fullNameEdtController.addListener(_onTextFieldUpdateChange);

    /*_orgSelected = _departmentList
        .where((item) =>
    item['id'] == widget.data['dataItem']['org_id']['v'].trim())
        .toList()[0];*/
  }

  _onTextFieldAddChange() {
    if (((_fullNameEdtController.text.isEmpty &&
                _genRow['full_name']['allowNull']) ||
            _fullNameEdtController.text.isNotEmpty) &&
        ((_idEdtController.text.isEmpty && _genRow['emp_id']['allowNull']) ||
            _idEdtController.text.isNotEmpty) &&
        ((_dobEdtController.text.isEmpty && _genRow['dob']['allowNull']) ||
            _dobEdtController.text.isNotEmpty) &&
        ((_genderSelected == null && _genRow['sex']['allowNull']) ||
            _genderSelected != null) &&
        ((_phoneEdtController.text.isEmpty && _genRow['phone']['allowNull']) ||
            _phoneEdtController.text.isNotEmpty) &&
        ((_emailEdtController.text.isEmpty && _genRow['email']['allowNull']) ||
            _emailEdtController.text.isNotEmpty) &&
        ((_emailCompanyEdtController.text.isEmpty &&
                _genRow['email_company']['allowNull']) ||
            _emailCompanyEdtController.text.isNotEmpty) &&
        ((_idNoEdtController.text.isEmpty && _genRow['id_no']['allowNull']) ||
            _idNoEdtController.text.isNotEmpty) &&
        ((_currentAddressEdtController.text.isEmpty &&
                _genRow['tmp_address']['allowNull']) ||
            _currentAddressEdtController.text.isNotEmpty) &&
        ((_addressEdtController.text.isEmpty &&
                _genRow['permanent_address']['allowNull']) ||
            _addressEdtController.text.isNotEmpty) &&
        ((_orgSelected == null && _genRow['OrgID']['allowNull']) ||
            _orgSelected != null) &&
        ((_roleSelected == null && _genRow['PositionID']['allowNull']) ||
            _roleSelected != null)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  _onTextFieldUpdateChange() {
    if ((_fullNameEdtController.text !=
                widget.data['dataItem']['full_name']['v'].trim() ||
            _orgSelected['id'] !=
                widget.data['dataItem']['org_id']['v'].trim() ||
            (_roleSelected != null &&
                _roleSelected['id'] !=
                    widget.data['dataItem']['role_id']['v'].trim()) ||
            (_statusSelected['id'] !=
                    widget.data['dataItem']['emp_status']['v'].trim() &&
                (_statusSelected['id'] == '1' ??
                    _endDateEdtController.text.isNotEmpty)) ||
            _testDateEdtController.text !=
                dateTimeFormat.format(DateFormat("MM/dd/yyyy HH:mm:ss aaa")
                    .parse(widget.data['dataItem']['test_date']['v']))) &&
        ((_statusSelected['id'] == '1' &&
                _endDateEdtController.text.isNotEmpty) ||
            _statusSelected['id'] != '1')) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis({"TbName": "tb_hrms_nhanvien_employee"},
        getGenRowDefineUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      setState(() {
        _genRow =
            Utils.getListGenRow(response.data['data'], widget.data['type']);
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  dynamic checkValidValueAdd() async {
    var data = {};
    if (_fullNameEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'full_name': _fullNameEdtController.text}
      };
    if (_dobEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'dob': _dobEdtController.text}
      };
    if (_genderSelected != -1)
      data = {
        ...data,
        ...{'sex': _genderList[_genderSelected]['id']}
      };
    if (_phoneEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'phone': _phoneEdtController.text}
      };
    if (_emailEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'email': _emailEdtController.text}
      };
    if (_emailCompanyEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'email_company': _emailCompanyEdtController.text}
      };
    if (_idNoEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'id_no': _idNoEdtController.text}
      };
    if (_currentAddressEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'tmp_address': _currentAddressEdtController.text}
      };
    if (_addressEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'permanent_address': _addressEdtController.text}
      };
    if (_orgSelected != null)
      data = {
        ...data,
        ...{'OrgID': _orgSelected['id']}
      };
    if (_roleSelected != null)
      data = {
        ...data,
        ...{'PositionID': _roleSelected['id']}
      };
    data = {
      ...data,
      ...{'test_date': _testDateEdtController.text}
    };

    data = {
      ...data,
      ...{'emp_status': _statusSelected['id']}
    };

   data = {
      ...data,
      ...{'CompanyEmpID': _user.data['data'][0]['company_id']['v']}
    };

    return data;
  }

  dynamic checkValidValueUpdate() async {
    var data = {};
    if (_fullNameEdtController.text !=
        widget.data['dataItem']['full_name']['v'].trim())
      data = {
        ...data,
        ...{'full_name': _fullNameEdtController.text}
      };
    if (_orgSelected['id'] != widget.data['dataItem']['org_id']['v'].trim())
      data = {
        ...data,
        ...{'OrgID': _orgSelected['id']}
      };
    if (_roleSelected != null &&
        _roleSelected['id'] != widget.data['dataItem']['role_id']['v'].trim())
      data = {
        ...data,
        ...{'PositionID': _roleSelected['id']}
      };
    if (_testDateEdtController.text !=
        dateTimeFormat.format(DateFormat("MM/dd/yyyy HH:mm:ss aaa")
            .parse(widget.data['dataItem']['test_date']['v'])))
      data = {
        ...data,
        ...{'test_date': _testDateEdtController.text}
      };
    if (_statusSelected['id'] != widget.data['dataItem']['emp_status']['v'])
      data = {
        ...data,
        ...{'emp_status': _statusSelected['id']}
      };
    if (_statusSelected['id'] == '1')
      data = {
        ...data,
        ...{'end_date': _endDateEdtController.text}
      };

    return data;
  }

  void getGender(BaseViewModel model) async {
    List<dynamic> genderList = [];
    var response = await model.callApis({}, getGenderUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var gender in response.data['data']) {
        genderList.add({
          'id': gender['ID'],
          'name': gender['TenGioiTinh']['v'],
        });
      }
      setState(() {
        _genderList = genderList;
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getOrganize(BaseViewModel model,
      {String searchText = '', SelectBoxCustomUtilState state}) async {
    _departmentList.clear();
    List<dynamic> _list = [];
    var response = await model.callApis({}, getDepartmentUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      for (var list in response.data['data']) {
        _list.add({
          'id': list['ID'],
          'code': list['ma_org']['v'],
          'name': list['name']['v']
        });
        if (widget.data['type'].contains('update')) if (list['ID'] ==
            widget.data['dataItem']['org_id']['v'])
          _orgSelected = {
            'id': list['ID'],
            'code': list['ma_org']['v'],
            'name': list['name']['v']
          };
      }
    _departmentList.addAll(_list);
    if (widget.data['type'].contains('update')) getRole(model);
    if (state != null) {
      state.updateDataList(_departmentList);
    }
    setState(() {});
  }

  void getRole(BaseViewModel model,
      {String searchText = '',
        SelectBoxCustomUtilState state,
        bool reload = false}) async {
    _roleList.clear();
    List<dynamic> _list = [];
    var response = await model.callApis({
      'org_id': 'org_id = ${_orgSelected['id']}',
      'search_text': searchText,
    }, orgRoleUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    print(_orgSelected['id']);
    if (response.status.code == 200)
      for (var list in response.data['data']) {
        _list.add({
          'id': list['ID'],
          'code': list['role_id']['v'],
          'name': list['name_role']['v']
        });
        if (widget.data['type'].contains('update') && !reload) if (list['ID'] ==
            widget.data['dataItem']['role_id']['v'])
          _roleSelected = {
            'id': list['ID'],
            'code': list['role_id']['v'],
            'name': list['name_role']['v']
          };
      }
    _roleList.addAll(_list);
    if (state != null) {
      state.updateDataList(_roleList);
    }
    setState(() {});
  }

  void addNew(BaseViewModel model) async {
    showLoadingDialog(context);
    var check = await checkValidValueAdd();
    if (check.length > 0) {
      var encryptData = await Utils.encrypt("tb_hrms_nhanvien_employee");
      var response = await model.callApis(
          {'tbname': encryptData, ...check}, addDataUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      Navigator.pop(context);
      if (response.status.code == 200) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_register_success),
            onPress: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            });
      } else
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_register_failed));
    }
  }

  void updateData(BaseViewModel model) async {
    var dataChange = await checkValidValueUpdate();
    if (dataChange.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_nhanvien_employee");
      var response = await model.callApis({
        'tbname': encryptData,
        'dataid': widget.data['dataItem']['ID'],
        ...dataChange
      }, updateDataUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      Navigator.pop(context);
      if (response.status.code == 200) {
        _isUpdated = true;
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success));
      } else
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_failed));
    }
  }

  void employeeWorkStatus(BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await model.callApis({}, employeeWorkStatusUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data'])
        _list.add({'id': list['ID'], 'name': list['Name']['v']});
      setState(() {
        _workStatusList.addAll(_list);
        if (widget.data['type'].toString().contains('add'))
          _statusSelected =
              _workStatusList.where((item) => item['id'] == '2').toList()[0];
        else
          _statusSelected = _workStatusList
              .where((item) =>
                  item['id'] == widget.data['dataItem']['emp_status']['v'])
              .toList()[0];
      });
    } else
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        getGenRowDefine(model);
        getGender(model);
        getOrganize(model);
        employeeWorkStatus(model);
      },
      model: BaseViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () async {
          if (_isUpdated)
            Navigator.pop(context, true);
          else
            Navigator.pop(context);
        }, () {
          Utils.closeKeyboard(context);
        }, widget.data['appbarTitle'], null),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              Utils.closeKeyboard(context);
            },
            child: _genRow.length > 0
                ? Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Utils.resizeWidthUtil(context, 30)),
                    child: _content(model))
                : Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Center(child: CircularProgressIndicator())),
          ),
        ),
      ),
    );
  }

  Widget _content(BaseViewModel model) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _buildContentText(
            keyName: 'emp_id',
            controller: _idEdtController,
            forceError: _forceErrorID,
            allowNull: _genRow['emp_id']['allowNull'],
            isEnable: _genRow['emp_id']['allowEdit'],
            textCapitalization: TextCapitalization.words),
        _buildContentText(
            keyName: 'full_name',
            controller: _fullNameEdtController,
            forceError: _forceErrorFullName,
            allowNull: _genRow['full_name']['allowNull'],
            isEnable: true,
            textCapitalization: TextCapitalization.words),
        if (widget.data['type'].contains('add')) _contentAdd(),
        boxTitle(context, _genRow['OrgID']['name']),
        _buildSelectOrganize(model),
        boxTitle(context, _genRow['PositionID']['name']),
        _buildEmpPosition(model),
        _buildContentText(
            keyName: 'test_date',
            controller: _testDateEdtController,
            icon: ic_calendar,
            hintText: '',
            isEnable: false,
            onPress: _genRow['test_date']['allowEdit']
                ? () {
                    showDatePicker(
                            context: context,
                            initialDate: DateFormat('yyyy-MM-dd').parse(
                                _testDateEdtController.text != ''
                                    ? DateFormat('dd/MM/yyyy')
                                        .parse(_testDateEdtController.text)
                                        .toString()
                                    : DateTime.now().toString()),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100))
                        .then((value) {
                      if (value == null) return;
                      _testDateEdtController.text =
                          dateTimeFormat.format(value);
                      if (widget.data['type'].contains('update'))
                        _onTextFieldUpdateChange();
                      else
                        _onTextFieldAddChange();
                    });
                  }
                : () {}),
        boxTitle(context, _genRow['emp_status']['name']),
        _buildEmpWorkStatus(),
        if (_statusSelected['id'] == '1')
          _buildContentText(
              keyName: 'end_date',
              controller: _endDateEdtController,
              icon: ic_calendar,
              hintText: '',
              isEnable: false,
              onPress: _genRow['end_date']['allowEdit']
                  ? () {
                      showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100))
                          .then((value) {
                        if (value == null) return;
                        setState(() {
                          _endDateEdtController.text =
                              dateTimeFormat.format(value);
                        });
                        _onTextFieldUpdateChange();
                      });
                    }
                  : () {}),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 50),
        ),
        TKButton(Utils.getString(context, txt_save),
            enable: _enableUpdateButton, width: double.infinity, onPress: () {
          FocusScope.of(context).unfocus();
          if (widget.data['type'].contains('add'))
            addNew(model);
          else
            updateData(model);
        }),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 30),
        ),
      ]);

  Widget _contentAdd() => Column(
        children: <Widget>[
          _buildContentText(
              keyName: 'dob',
              controller: _dobEdtController,
              icon: ic_calendar,
              hintText: '',
              isEnable: false,
              onPress: _genRow['dob']['allowEdit']
                  ? () {
                      showDatePicker(
                              context: context,
                              initialDate: DateFormat('yyyy-MM-dd').parse(
                                  DateFormat('dd/MM/yyyy')
                                      .parse(_initDate)
                                      .toString()),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100))
                          .then((value) {
                        if (value == null) return;
                        _dobEdtController.text = dateTimeFormat.format(value);
                        _initDate = _dobEdtController.text;
                        _onTextFieldAddChange();
                      });
                    }
                  : () {}),
          _buildContentSelectBoxGender(),
          _buildContentText(
              keyName: 'phone',
              forceError: _forceErrorPhone,
              allowNull: _genRow['phone']['allowNull'],
              isEnable: _genRow['phone']['allowEdit'],
              controller: _phoneEdtController,
              textInputType: TextInputType.phone),
          _buildContentText(
              keyName: 'email',
              forceError: _forceErrorEmail,
              allowNull: _genRow['email']['allowNull'],
              isEnable: _genRow['email']['allowEdit'],
              controller: _emailEdtController,
              textInputType: TextInputType.emailAddress),
          _buildContentText(
              keyName: 'email_company',
              forceError: _forceErrorEmailCom,
              allowNull: _genRow['email_company']['allowNull'],
              isEnable: _genRow['email_company']['allowEdit'],
              controller: _emailCompanyEdtController,
              textInputType: TextInputType.emailAddress),
          _buildContentText(
              keyName: 'id_no',
              allowNull: _genRow['id_no']['allowNull'],
              isEnable: _genRow['id_no']['allowEdit'],
              controller: _idNoEdtController,
              forceError: _forceErrorNo,
              textInputType: TextInputType.number),
//        _buildContentText(Utils.getTitle(_genRowList, 'issue_date'),
//            controller: _issueDateEdtController),
//        _buildContentText(Utils.getTitle(_genRowList, 'IDPlace'),
//            controller: _idPlaceEdtController),
          _buildContentText(
              forceError: _forceErrorCurrentAddress,
              keyName: 'tmp_address',
              allowNull: _genRow['tmp_address']['allowNull'],
              isEnable: _genRow['tmp_address']['allowEdit'],
              controller: _currentAddressEdtController),
          _buildContentText(
              forceError: _forceErrorAddress,
              allowNull: _genRow['permanent_address']['allowNull'],
              isEnable: _genRow['permanent_address']['allowEdit'],
              keyName: 'permanent_address',
              controller: _addressEdtController),
        ],
      );

  Widget _buildContentText(
      {String keyName = '',
      bool isEnable = true,
      bool isExpand = false,
      bool forceError = false,
      bool allowNull = true,
      TextEditingController controller,
      Function onPress,
      String icon,
      TextInputType textInputType = TextInputType.text,
      String hintText = '',
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (onPress != null) {
          onPress();
        } else {
          Utils.closeKeyboard(context);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            boxTitle(context, _genRow[keyName]['name']),
            TextFieldCustom(
                controller: controller,
                enable: isEnable,
                imgLeadIcon: icon,
                expandMultiLine: isExpand,
                hintText: hintText,
                textCapitalization: textCapitalization,
                textInputType: textInputType,
                forceError: forceError,
                onChange: (changeValue) {
                  setState(() {
                    if (!allowNull)
                      switch (keyName) {
                        case 'emp_id':
                          _forceErrorID = controller.text.trimRight().isEmpty;
                          break;
                        case 'full_name':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'phone':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'email':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'email_company':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'id_no':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'tmp_address':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'permanent_address':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                      }
                  });
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSelectBoxGender() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, _genRow['sex']['name']),
        SelectBoxCustom(
            valueKey: 'name',
            title: _genderList.length > 0
                ? _genderSelected == -1
                    ? 'Chọn'
                    : _genderList[_genderSelected]['name']
                : 'Chọn',
            data: _genderList,
            selectedItem: _genderSelected == -1 ? 0 : _genderSelected,
            callBack: (itemSelected) => setState(() {
                  if (itemSelected != null) {
                    _genderSelected = itemSelected;
                  }
                })),
      ],
    );
  }

  Widget _buildSelectOrganize(BaseViewModel model) => SelectBoxCustomUtil(
      title: _departmentList.length > 0
          ? _orgSelected == null ? 'Chọn phòng ban' : _orgSelected['name']
          : '',
      data: _departmentList,
      selectedItem: 0,
      enableSearch: false,
      clearCallback: () {},
      initCallback: (state) {},
      loadMoreCallback: (state) {},
      searchCallback: (value, state) {
//        if (value != '') {
//          Future.delayed(Duration(seconds: 2), () {
//            _departmentList.clear();
//            getOrganize(model, searchText: value, state: state);
//          });
//        }
      },
      callBack: (itemSelected) {
        setState(() {
          _orgSelected = itemSelected;
          _roleSelected = null;
        });
        getRole(model, reload: true);
        if (widget.data['type'].toString().contains('update'))
          _onTextFieldUpdateChange();
        else
          _onTextFieldAddChange();
      });

  Widget _buildEmpPosition(BaseViewModel model) => SelectBoxCustomUtil(
      title: _roleSelected == null ? 'Chọn chức vụ' : _roleSelected['name'],
      data: _roleList,
      selectedItem: 0,
      initCallback: (state) {},
      loadMoreCallback: (state) {},
      enableSearch: false,
      enable: _orgSelected == null ? false : true,
      clearCallback: () {},
      searchCallback: (value, state) {
        if (value != '') {
          Future.delayed(Duration(seconds: 2), () {
            getRole(model, searchText: value, state: state);
          });
        }
      },
      callBack: (itemSelected) {
        setState(() {
          _roleSelected = itemSelected;
          if (_fullNameEdtController.text.isNotEmpty &&
              _emailEdtController.text.isNotEmpty) {
            _enableUpdateButton = true;
          }
        });
        if (widget.data['type'].toString().contains('update'))
          _onTextFieldUpdateChange();
        else
          _onTextFieldAddChange();
      });

  Widget _buildEmpWorkStatus() => SelectBoxCustomUtil(
      title: _workStatusList.length > 0
          ? _statusSelected != null ? _statusSelected['name'] : 'Vui lòng đợi'
          : '',
      data: _workStatusList,
      selectedItem: 0,
      enableSearch: false,
      initCallback: (state) {},
      loadMoreCallback: (state) {},
      enable: true,
      clearCallback: () {},
      searchCallback: (value, state) {},
      callBack: (itemSelected) {
        setState(() {
          _statusSelected = itemSelected;
        });
        if (widget.data['type'].toString().contains('update'))
          _onTextFieldUpdateChange();
        else
          _onTextFieldAddChange();
      });
}
