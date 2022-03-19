import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:provider/provider.dart';

class EditLocationOwner extends StatefulWidget {
  final data;

  EditLocationOwner(this.data);

  @override
  _EditLocationOwnerState createState() => _EditLocationOwnerState();
}

class _EditLocationOwnerState extends State<EditLocationOwner> {
  final dateTimeFormat = DateFormat("dd/MM/yyyy");
  dynamic _genRow = {};
  List<dynamic> _departmentApplyList = [];
  List<dynamic> _roleApplyList = [];
  List<dynamic> _defineTypeApplyList = [];
  List<dynamic> _employeeApplyList = [];
  List<dynamic> _dataShowList = [];
  TextEditingController _idEdtController = TextEditingController();
  TextEditingController _nameEdtController = TextEditingController();
  TextEditingController _startDateEdtController = TextEditingController();
  TextEditingController _locationEdtController = TextEditingController();
  TextEditingController _longEdtController = TextEditingController();
  TextEditingController _latEdtController = TextEditingController();
  TextEditingController _ipEdtController = TextEditingController();
  TextEditingController _distanceEdtController = TextEditingController();
  TextEditingController _searchEdtController = TextEditingController();

  bool _errID = false;
  bool _errName = false;
  bool _errLocation = false;
  bool _errLong = false;
  bool _errLat = false;
  bool _errStartDate = false;
  bool _errIP = false;
  bool _errRadius = false;
  bool _enableUpdateButton = false;
  bool _isIP = false;
  bool _active = false;
  bool _isUpdated = false;

  BaseResponse _user;

  @override
  void initState() {
    super.initState();
    _user = context.read<BaseResponse>();
    if (widget.data['type'].contains('update'))
      initData();
    else {
      _idEdtController.addListener(_onTextFieldAddChange);
      _nameEdtController.addListener(_onTextFieldAddChange);
      _locationEdtController.addListener(_onTextFieldAddChange);
      _longEdtController.addListener(_onTextFieldAddChange);
      _latEdtController.addListener(_onTextFieldAddChange);
      _ipEdtController.addListener(_onTextFieldAddChange);
      _distanceEdtController.addListener(_onTextFieldAddChange);
    }
  }

  @override
  void dispose() {
    if (mounted) {
      _idEdtController.dispose();
      _nameEdtController.dispose();
      _startDateEdtController.dispose();
      _locationEdtController.dispose();
      _longEdtController.dispose();
      _latEdtController.dispose();
      _ipEdtController.dispose();
      _distanceEdtController.dispose();
    }
    super.dispose();
  }

  initData() {
    _idEdtController.text =
        widget.data['dataItem']['time_location_id']['v'].trim() ?? '';
    _nameEdtController.text = widget.data['dataItem']['name']['v'].trim() ?? '';
    _locationEdtController.text =
        widget.data['dataItem']['location']['v'].trim() ?? '';
    _longEdtController.text = widget.data['dataItem']['long']['v'].trim() ?? '';
    _latEdtController.text = widget.data['dataItem']['lat']['v'].trim() ?? '';
    if (widget.data['dataItem']['start_date']['v'] != '')
      _startDateEdtController.text = dateTimeFormat.format(
          DateFormat("MM/dd/yyyy HH:mm:ss aaa")
              .parse(widget.data['dataItem']['start_date']['v']));
    _ipEdtController.text =
        widget.data['dataItem']['IPAllow']['v'].trim() ?? '';
    _distanceEdtController.text =
        widget.data['dataItem']['radius']['v'].trim() ?? '';
    widget.data['dataItem']['IsIP']['v'].trim() == 'True'
        ? _isIP = true
        : _isIP = false;
    widget.data['dataItem']['Active']['v'].trim() == 'True'
        ? _active = true
        : _active = false;
    _idEdtController.addListener(_onTextFieldUpdateChange);
    _nameEdtController.addListener(_onTextFieldUpdateChange);
    _locationEdtController.addListener(_onTextFieldUpdateChange);
    _longEdtController.addListener(_onTextFieldUpdateChange);
    _latEdtController.addListener(_onTextFieldUpdateChange);
    _ipEdtController.addListener(_onTextFieldUpdateChange);
    _distanceEdtController.addListener(_onTextFieldUpdateChange);
  }

  _onTextFieldUpdateChange() {
    if ((_idEdtController.text !=
                widget.data['dataItem']['time_location_id']['v'].trim() &&
            ((_idEdtController.text.isEmpty && _genRow['time_location_id']['allowNull']) ||
                _idEdtController.text.isNotEmpty)) ||
        (_nameEdtController.text != widget.data['dataItem']['name']['v'].trim() &&
            ((_nameEdtController.text.isEmpty && _genRow['name']['allowNull']) ||
                _nameEdtController.text.isNotEmpty)) ||
        (_locationEdtController.text != widget.data['dataItem']['location']['v'].trim() &&
            ((_locationEdtController.text.isEmpty && _genRow['location']['allowNull']) ||
                _locationEdtController.text.isNotEmpty)) ||
        (_longEdtController.text != widget.data['dataItem']['long']['v'].trim() &&
            ((_longEdtController.text.isEmpty && _genRow['long']['allowNull']) ||
                _longEdtController.text.isNotEmpty)) ||
        (_latEdtController.text != widget.data['dataItem']['lat']['v'].trim() &&
            ((_latEdtController.text.isEmpty && _genRow['lat']['allowNull']) ||
                _latEdtController.text.isNotEmpty)) ||
        (_ipEdtController.text != widget.data['dataItem']['IPAllow']['v'].trim() &&
            ((_ipEdtController.text.isEmpty && _genRow['IPAllow']['allowNull']) ||
                _ipEdtController.text.isNotEmpty)) ||
        (_distanceEdtController.text != widget.data['dataItem']['radius']['v'].trim() &&
            ((_distanceEdtController.text.isEmpty && _genRow['radius']['allowNull']) ||
                _distanceEdtController.text.isNotEmpty)) ||
        ((widget.data['dataItem']['IsIP']['v'].trim() == 'True' && !_isIP) ||
            (widget.data['dataItem']['IsIP']['v'].trim() == 'False' &&
                _isIP)) ||
        ((widget.data['dataItem']['Active']['v'].trim() == 'True' && !_active) ||
            (widget.data['dataItem']['Active']['v'].trim() == 'False' && _active))) {
      if ((_isIP && _ipEdtController.text.isNotEmpty) || !_isIP)
        _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  _onTextFieldAddChange() {
    if (((_idEdtController.text.isEmpty &&
                _genRow['time_location_id']['allowNull']) ||
            _idEdtController.text.isNotEmpty) &&
        ((_nameEdtController.text.isEmpty && _genRow['name']['allowNull']) ||
            _nameEdtController.text.isNotEmpty) &&
        ((_locationEdtController.text.isEmpty &&
                _genRow['location']['allowNull']) ||
            _locationEdtController.text.isNotEmpty) &&
        ((_longEdtController.text.isEmpty && _genRow['long']['allowNull']) ||
            _longEdtController.text.isNotEmpty) &&
        ((_latEdtController.text.isEmpty && _genRow['lat']['allowNull']) ||
            _latEdtController.text.isNotEmpty) &&
        ((_startDateEdtController.text.isEmpty &&
                _genRow['start_date']['allowNull']) ||
            _startDateEdtController.text.isNotEmpty) &&
        ((_distanceEdtController.text.isEmpty &&
                _genRow['radius']['allowNull']) ||
            _distanceEdtController.text.isNotEmpty)) {
      if ((_isIP && _ipEdtController.text.isNotEmpty) || !_isIP)
        _enableUpdateButton = true;
      else
        _enableUpdateButton = false;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "tb_hrms_chamcong_time_location"},
        getGenRowDefineUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
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

  dynamic _checkApply(List<dynamic> list, String keyChange) {
    String _apply = '';
    dynamic data = {};
    list.forEach((item) {
      if (item['apply']) _apply = _apply + '${item['id']};';
    });

    if (widget.data['type'].contains('update')) {
      if (_apply != '' &&
          _apply.substring(0, _apply.length - 1) !=
              widget.data['dataItem'][keyChange]['v'])
        data = {
          ...data,
          ...{keyChange: _apply.substring(0, _apply.length - 1)}
        };
    } else if (_apply != '')
      data = {
        ...data,
        ...{keyChange: _apply.substring(0, _apply.length - 1)}
      };

    return data;
  }

  dynamic checkUpdateValue() {
    var data = {};

    if (_idEdtController.text !=
        widget.data['dataItem']['time_location_id']['v'].trim())
      data = {
        ...data,
        ...{'time_location_id': _idEdtController.text}
      };
    if (_nameEdtController.text != widget.data['dataItem']['name']['v'].trim())
      data = {
        ...data,
        ...{'name': _nameEdtController.text}
      };
    if (_locationEdtController.text !=
        widget.data['dataItem']['location']['v'].trim())
      data = {
        ...data,
        ...{'location': _locationEdtController.text}
      };
    if (_longEdtController.text != widget.data['dataItem']['long']['v'].trim())
      data = {
        ...data,
        ...{'long': _longEdtController.text}
      };
    if (_latEdtController.text != widget.data['dataItem']['lat']['v'].trim())
      data = {
        ...data,
        ...{'lat': _latEdtController.text}
      };
    if (_ipEdtController.text != widget.data['dataItem']['IPAllow']['v'].trim())
      data = {
        ...data,
        ...{'IPAllow': _ipEdtController.text}
      };
    if (_distanceEdtController.text !=
        widget.data['dataItem']['radius']['v'].trim())
      data = {
        ...data,
        ...{'radius': _distanceEdtController.text}
      };
    if (_startDateEdtController.text.isNotEmpty &&
        widget.data['dataItem']['start_date']['v'] !=
            '') if (_startDateEdtController.text !=
        dateTimeFormat.format(DateFormat("MM/dd/yyyy HH:mm:ss aaa")
            .parse(widget.data['dataItem']['start_date']['v'])))
      data = {
        ...data,
        ...{'start_date': _startDateEdtController.text}
      };
    data = {
      ...data,
      ...{'IsIP': _isIP}
    };
    data = {
      ...data,
      ...{'Active': _active}
    };

    //check apply
    data = {
      ...data,
      ..._checkApply(_departmentApplyList, 'org_multi_id'),
      ..._checkApply(_roleApplyList, 'role_multi_id'),
      ..._checkApply(_defineTypeApplyList, 'type_time_multi_id'),
      ..._checkApply(_employeeApplyList, 'employee_multi_id'),
    };

    return data;
  }

  void updateData(BaseViewModel model) async {
    var dataChange = await checkUpdateValue();
    if (dataChange.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_chamcong_time_location");
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

  void addData(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_chamcong_time_location");
    var response = await model.callApis({
      'tbname': encryptData,
      'company_id': _user.data['data'][0]['company_id']['v'],
      'time_location_id': _idEdtController.text,
      'name': _nameEdtController.text,
      'location': _locationEdtController.text,
      'long': _longEdtController.text,
      'lat': _latEdtController.text,
      'start_date': _startDateEdtController.text,
      'IPAllow': _ipEdtController.text,
      'radius': _distanceEdtController.text,
      'IsIP': _isIP,
      'Active': _active,
      ..._checkApply(_departmentApplyList, 'org_multi_id'),
      ..._checkApply(_roleApplyList, 'role_multi_id'),
      ..._checkApply(_defineTypeApplyList, 'type_time_multi_id'),
      ..._checkApply(_employeeApplyList, 'employee_multi_id'),
    }, addDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      });
    else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
  }

  void deleteData(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_chamcong_time_location");
    showLoadingDialog(context);
    var deleteRoleResponse = await model.callApis(
        {"tbname": encryptData, "dataid": widget.data['dataItem']['ID']},
        deleteDataUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    Navigator.pop(context);
    if (deleteRoleResponse.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      });
    } else {
      Navigator.of(context).pop();
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
    }
  }

  Future getDepartment(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis({}, getDepartmentUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200)
      response.data['data'].forEach((item) {
        if (widget.data['type'].contains('update') &&
            widget.data['dataItem']['org_multi_id']['v'] != '') {
          if (widget.data['dataItem']['org_multi_id']['v']
                  .toString()
                  .split(';')
                  .where((itemApply) => itemApply == item['ID'])
                  .length >
              0)
            _departmentApplyList.add({
              'id': item['ID'],
              'name': item['name']['v'],
              'code': item['ma_org']['v'],
              'apply': true
            });
          else
            _departmentApplyList.add({
              'id': item['ID'],
              'name': item['name']['v'],
              'code': item['ma_org']['v'],
              'apply': false
            });
        } else
          _departmentApplyList.add({
            'id': item['ID'],
            'name': item['name']['v'],
            'code': item['ma_org']['v'],
            'apply': false
          });
      });
  }

  Future getRole(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await model.callApis(
        {'org_id': '1 = 1', 'search_text': ''}, orgRoleUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200)
      response.data['data'].forEach((item) {
        if (widget.data['type'].contains('update') &&
            widget.data['dataItem']['role_multi_id']['v'] != '') {
          if (widget.data['dataItem']['role_multi_id']['v']
                  .toString()
                  .split(';')
                  .where((itemApply) => itemApply == item['ID'])
                  .length >
              0)
            _roleApplyList.add({
              'id': item['ID'],
              'name': item['name_role']['v'],
              'code': item['role_id']['v'],
              'apply': true
            });
          else
            _roleApplyList.add({
              'id': item['ID'],
              'name': item['name_role']['v'],
              'code': item['role_id']['v'],
              'apply': false
            });
        } else
          _roleApplyList.add({
            'id': item['ID'],
            'name': item['name_role']['v'],
            'code': item['role_id']['v'],
            'apply': false
          });
      });
  }

  Future getEmployee(BaseViewModel model,
      {int currentIndex = 0, bool loadMore = false}) async {
    if (!loadMore) showLoadingDialog(context);
    var response = await BaseViewModel().callApis({
      "current_index": currentIndex,
      "search_text": '',
      "filter": '',
      "not_include": -1
    }, employeeOwnerUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      response.data['data'].forEach((item) {
        if (widget.data['type'].contains('update') &&
            widget.data['dataItem']['role_multi_id']['v'] != '') {
          if (widget.data['dataItem']['employee_multi_id']['v']
                  .toString()
                  .split(';')
                  .where((itemApply) => itemApply == item['ID'])
                  .length >
              0)
            _employeeApplyList.add({
              'id': item['ID'],
              'name': item['full_name']['v'],
              'code': item['emp_id']['v'],
              'apply': true
            });
          else
            _employeeApplyList.add({
              'id': item['ID'],
              'name': item['full_name']['v'],
              'code': item['emp_id']['v'],
              'apply': false
            });
        } else
          _employeeApplyList.add({
            'id': item['ID'],
            'name': item['full_name']['v'],
            'code': item['emp_id']['v'],
            'apply': false
          });
      });
    if (int.parse(response.data['data'][0]['total_row']['v']) >
        _employeeApplyList.length)
      await getEmployee(model, currentIndex: currentIndex + 10, loadMore: true);
    else
      Navigator.pop(context);
  }

  Future getTimeDefine(BaseViewModel model) async {
    showLoadingDialog(context);
    var response = await BaseViewModel().callApis(
        {}, getTimeTypeUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200)
      response.data['data'].forEach((item) {
        if (widget.data['type'].contains('update') &&
            widget.data['dataItem']['role_multi_id']['v'] != '') {
          if (widget.data['dataItem']['type_time_multi_id']['v']
                  .toString()
                  .split(';')
                  .where((itemApply) => itemApply == item['ID'])
                  .length >
              0)
            _defineTypeApplyList.add({
              'id': item['ID'],
              'name': item['name_time_define']['v'],
              'code': '',
              'apply': true
            });
          else
            _defineTypeApplyList.add({
              'id': item['ID'],
              'name': item['name_time_define']['v'],
              'code': '',
              'apply': false
            });
        } else
          _defineTypeApplyList.add({
            'id': item['ID'],
            'name': item['name_time_define']['v'],
            'code': '',
            'apply': false
          });
      });
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getGenRowDefine(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () async {
          if (_isUpdated)
            Navigator.pop(context, true);
          else {
            Navigator.pop(context);
          }
        }, () {
          Utils.closeKeyboard(context);
          if (widget.data['type'].contains('update'))
            showMessageDialog(context,
                description: Utils.getString(context, txt_confirm_delete),
                onPress: () {
              Navigator.pop(context);
              deleteData(model);
            });
        }, widget.data['appbarTitle'],
            widget.data['type'].contains('update') ? Icons.delete : null),
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

  Widget _content(BaseViewModel model) => Column(
        children: <Widget>[
          _buildContentText(
              keyName: 'time_location_id',
              controller: _idEdtController,
              forceError: _errID,
              allowNull: _genRow['time_location_id']['allowNull'],
              isEnable: _genRow['time_location_id']['allowEdit'],
              textCapitalization: TextCapitalization.characters),
          _buildContentText(
              keyName: 'name',
              controller: _nameEdtController,
              forceError: _errName,
              allowNull: _genRow['name']['allowNull'],
              isEnable: _genRow['name']['allowEdit'],
              textCapitalization: TextCapitalization.words),
          _buildContentText(
              keyName: 'location',
              controller: _locationEdtController,
              forceError: _errLocation,
              allowNull: _genRow['location']['allowNull'],
              isEnable: _genRow['location']['allowEdit'],
              isExpand: true,
              textCapitalization: TextCapitalization.none),
          _buildMap(),
          _buildContentText(
              keyName: 'long',
              controller: _longEdtController,
              forceError: _errLong,
              allowNull: _genRow['long']['allowNull'],
              isEnable: _genRow['long']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'lat',
              controller: _latEdtController,
              forceError: _errLat,
              allowNull: _genRow['lat']['allowNull'],
              isEnable: _genRow['lat']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'start_date',
              controller: _startDateEdtController,
              forceError: _errStartDate,
              icon: ic_calendar,
              hintText: '',
              isEnable: false,
              onPress: () {
                showDatePicker(
                        context: context,
                        initialDate: DateFormat('yyyy-MM-dd').parse(
                            _startDateEdtController.text.isNotEmpty
                                ? DateFormat('dd/MM/yyyy')
                                    .parse(_startDateEdtController.text)
                                    .toString()
                                : DateTime.now().toString()),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100))
                    .then((value) {
                  if (value == null) return;
                  setState(() {
                    _startDateEdtController.text = dateTimeFormat.format(value);
                    if (widget.data['type'].toString().contains('update'))
                      _enableUpdateButton = true;
                  });
                });
              }),
          _buildContentText(
              keyName: 'IPAllow',
              controller: _ipEdtController,
              forceError: _errIP,
              allowNull: _genRow['IPAllow']['allowNull'],
              isEnable: _genRow['IPAllow']['allowEdit'],
              textInputType: TextInputType.text),
          _buildContentText(
              keyName: 'radius',
              controller: _distanceEdtController,
              forceError: _errRadius,
              allowNull: _genRow['radius']['allowNull'],
              isEnable: _genRow['radius']['allowEdit'],
              textInputType: TextInputType.phone),
          _buildApply(
              model: model,
              keyName: 'org_multi_id',
              type: 'department',
              enable: _genRow['org_multi_id']['allowEdit']),
          _buildApply(
              model: model,
              keyName: 'role_multi_id',
              type: 'role',
              enable: _genRow['role_multi_id']['allowEdit']),
          _buildApply(
              model: model,
              keyName: 'type_time_multi_id',
              type: 'define',
              enable: _genRow['type_time_multi_id']['allowEdit']),
          _buildApply(
              model: model,
              keyName: 'employee_multi_id',
              type: 'employee',
              enable: _genRow['employee_multi_id']['allowEdit']),
          _buildCheckBox('IsIP', _isIP),
          _buildCheckBox('Active', _active),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 50),
          ),
          TKButton(Utils.getString(context, txt_save),
              enable: _enableUpdateButton, width: double.infinity, onPress: () {
            FocusScope.of(context).unfocus();
            if (widget.data['type'].contains('add'))
              addData(model);
            else
              updateData(model);
          }),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 30),
          ),
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
      TextCapitalization textCapitalization = TextCapitalization.none,
      bool clearText = false,
      Function onClear}) {
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
                onClear: onClear,
                forceError: forceError,
                onChange: (value) {
                  setState(() {
                    if (!allowNull) {
                      switch (keyName) {
                        case 'time_location_id':
                          _errID = controller.text.trimRight().isEmpty;
                          break;
                        case 'name':
                          _errName = controller.text.trimRight().isEmpty;
                          break;
                        case 'location':
                          _errLocation = controller.text.trimRight().isEmpty;
                          break;
                        case 'long':
                          _errLong = controller.text.trimRight().isEmpty;
                          break;
                        case 'lat':
                          _errLat = controller.text.trimRight().isEmpty;
                          break;
                        case 'start_date':
                          _errStartDate = controller.text.trimRight().isEmpty;
                          break;
                        case 'IPAllow':
                          _errIP = controller.text.trimRight().isEmpty;
                          break;
                        case 'radius':
                          _errRadius = controller.text.trimRight().isEmpty;
                      }
                    }
                  });
                },
                clearText: clearText),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() => Container(
        width: double.infinity,
        child: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, Routers.mapLocationOwner, arguments: {
              'type': widget.data['type'],
              'data': widget.data['type'].contains('update')
                  ? {
                      'address': _locationEdtController.text,
                      'long': double.parse(_longEdtController.text),
                      'lat': double.parse(_latEdtController.text),
                      'radius': double.parse(
                          _distanceEdtController.text.isNotEmpty
                              ? _distanceEdtController.text
                              : '0')
                    }
                  : {}
            }).then((value) {
              if (value != null) {
                dynamic data = value;
                setState(() {
                  _locationEdtController.text = data['address'];
                  _latEdtController.text = data['latitude'].toString();
                  _longEdtController.text = data['longitude'].toString();
                });
              }
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.location_on,
                color: only_color,
              ),
              TKText(
                'Bản đồ',
                tkFont: TKFont.SFProDisplayMedium,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontSize: Utils.resizeWidthUtil(context, 28),
                    //decoration: TextDecoration.underline,
                    color: only_color),
              )
            ],
          ),
        ),
      );

  Widget _buildCheckBox(String keyName, bool check) => GestureDetector(
        onTap: () {
          setState(() {
            if (keyName.contains('IsIP'))
              _isIP = !_isIP;
            else
              _active = !_active;
            if (widget.data['type'].contains('update'))
              _onTextFieldUpdateChange();
            else
              _onTextFieldAddChange();
          });
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: boxTitle(context, _genRow[keyName]['name']),
            ),
            check
                ? Icon(
                    Icons.check_box,
                    color: only_color,
                    size: 30,
                  )
                : Icon(
                    Icons.check_box_outline_blank,
                    color: txt_grey_color_v1,
                    size: 30,
                  )
          ],
        ),
      );

  Widget _buildApply(
          {BaseViewModel model, String keyName, String type, bool enable}) =>
      Container(
        margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
        child: GestureDetector(
          onTap: enable
              ? () async {
                  switch (type) {
                    case 'department':
                      if (_departmentApplyList.length == 0)
                        await getDepartment(model);
                      break;
                    case 'role':
                      if (_roleApplyList.length == 0) await getRole(model);
                      break;
                    case 'define':
                      if (_defineTypeApplyList.length == 0)
                        await getTimeDefine(model);
                      break;
                    case 'employee':
                      if (_employeeApplyList.length == 0)
                        await getEmployee(model);
                  }
                  showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        padding: EdgeInsets.only(
                            top: Utils.resizeHeightUtil(context, 20)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                                Utils.resizeWidthUtil(context, 30.0)),
                            topRight: Radius.circular(
                                Utils.resizeWidthUtil(context, 30.0)),
                          ),
                        ),
                        child:
                            StatefulBuilder(builder: (context, setModalState) {
                          return _listApply(
                              context,
                              setModalState,
                              model,
                              (type.contains('department')
                                      ? _departmentApplyList
                                      : type.contains('role')
                                          ? _roleApplyList
                                          : type.contains('define')
                                              ? _defineTypeApplyList
                                              : _employeeApplyList)
                                  .where((item) => item['apply'])
                                  .toList(),
                              type);
                        })),
                  );
                }
              : () {},
          child: Container(
              decoration: BoxDecoration(
                  color: enable
                      ? Colors.white
                      : txt_grey_color_v1.withOpacity(0.1),
                  border: Border.all(color: border_text_field),
                  borderRadius: BorderRadius.circular(
                      Utils.resizeWidthUtil(context, 10))),
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 10)),
              height: Utils.resizeHeightUtil(context, 90),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  TKText(
                    _genRow[keyName]['name'],
                    tkFont: TKFont.SFProDisplayRegular,
                    style: TextStyle(
                        fontSize: Utils.resizeWidthUtil(context, 32),
                        color: txt_grey_color_v3),
                  ),
                  Icon(Icons.arrow_drop_down,
                      size: Utils.resizeWidthUtil(context, 44))
                ],
              )),
        ),
      );

  Widget _listApply(BuildContext context, StateSetter setModalState,
          BaseViewModel model, List<dynamic> list, String type) =>
      Column(
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
          SizedBox(
            height: Utils.resizeHeightUtil(context, 10),
          ),
          Expanded(
            child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                itemCount: list.length,
                itemBuilder: (context, index) => Container(
                      padding: EdgeInsets.symmetric(
                          vertical: Utils.resizeHeightUtil(context, 20)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              bottom: BorderSide(
                                  color: txt_grey_color_v3.withOpacity(0.2)))),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: Utils.resizeWidthUtil(context, 100),
                          ),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                TKText(
                                  list[index]['name'],
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 28),
                                      color: txt_grey_color_v3),
                                ),
                                TKText(
                                  list[index]['code'],
                                  tkFont: TKFont.SFProDisplayMedium,
                                  style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 28),
                                      color: txt_grey_color_v4),
                                )
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              setModalState(() {
                                list[index]['apply'] = false;
                              });
                            },
                            child: Container(
                              width: Utils.resizeWidthUtil(context, 100),
                              child: Icon(
                                Icons.cancel,
                                size: 30,
                                color: txt_fail_color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
          ),
          Padding(
            padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 20)),
            child: TKButton(
              Utils.getString(context, txt_add),
              width: MediaQuery.of(context).size.width,
              onPress: () {
                List<dynamic> _list = [];
                _list = (type.contains('department')
                        ? _departmentApplyList
                        : type.contains('role')
                            ? _roleApplyList
                            : type.contains('define')
                                ? _defineTypeApplyList
                                : _employeeApplyList)
                    .where((item) => !item['apply'])
                    .toList();
                _dataShowList = _list;
                showModalBottomSheet(
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  context: context,
                  builder: (context) => Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      padding: EdgeInsets.only(
                          top: Utils.resizeHeightUtil(context, 20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              Utils.resizeWidthUtil(context, 30.0)),
                          topRight: Radius.circular(
                              Utils.resizeWidthUtil(context, 30.0)),
                        ),
                      ),
                      child:
                          StatefulBuilder(builder: (context, setModalStateAdd) {
                        return _listAdd(context, setModalStateAdd,
                            setModalState, model, _list);
                      })),
                );
              },
            ),
          ),
        ],
      );

  Widget _listAdd(BuildContext context, StateSetter setModalState,
      StateSetter stateSetter, BaseViewModel model, List<dynamic> list) {
    return Column(
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
        SizedBox(
          height: Utils.resizeHeightUtil(context, 10),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: Utils.resizeWidthUtil(context, 30),
              vertical: Utils.resizeWidthUtil(context, 10)),
          child: TextFieldCustom(
            enable: true,
            expandMultiLine: false,
            controller: _searchEdtController,
            hintText: 'Tìm kiếm',
            onChange: (value) {
              setModalState(() {
                _dataShowList = list.where((item) {
                  return item["name"]
                      .toLowerCase()
                      .contains(value.toLowerCase());
                }).toList();
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              scrollDirection: Axis.vertical,
              itemCount: _dataShowList.length,
              itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _dataShowList[index]['apply'] = true;
                        _dataShowList.removeAt(index);
                      });
                      stateSetter(() {});
                      setState(() {
                        _enableUpdateButton = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: Utils.resizeHeightUtil(context, 20)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              bottom: BorderSide(
                                  color: txt_grey_color_v3.withOpacity(0.2)))),
                      child: Column(
                        children: <Widget>[
                          TKText(
                            _dataShowList[index]['name'],
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: Utils.resizeWidthUtil(context, 28),
                                color: txt_grey_color_v3),
                          ),
                          TKText(
                            _dataShowList[index]['code'],
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: Utils.resizeWidthUtil(context, 28),
                                color: txt_grey_color_v4),
                          )
                        ],
                      ),
                    ),
                  )),
        ),
      ],
    );
  }
}
