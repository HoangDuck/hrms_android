import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';

class EditRoleManagerView extends StatefulWidget {
  final dynamic data;

  EditRoleManagerView(this.data);

  @override
  State<StatefulWidget> createState() {
    return _EditRoleManagerState();
  }
}

class _EditRoleManagerState extends State<EditRoleManagerView> {
  ScrollController controller;
  TextEditingController _roleIdEdtController = TextEditingController();
  TextEditingController _nameEdtController = TextEditingController();

  List<dynamic> listRole = [];
  List<dynamic> listRoleTypeId = [];
  List<dynamic> listTimeType = [];
  List<dynamic> listDepartment = [];
  dynamic genRow = {};

  bool _enableUpdateButton = false;
  bool _forceErrorRoleId = false;
  bool _forceErrorName = false;
  bool _enableDepartment = true;
  bool _isUpdated = false;

  dynamic _roleTypeSelected;
  dynamic _roleParentSelected;
  dynamic _timeTypeSelected;
  dynamic _departmentSelected;

  void initState() {
    super.initState();
    if (widget.data['type'].contains('addFromDepartment')) {
      _departmentSelected = {
        'id': widget.data['data']['ID'],
        'name': widget.data['data']['name']['v']
      };
      _enableDepartment = false;
    } else //init parent role
      for (int i = 0; i < widget.data['data'].length; i++)
        listRole.add({
          ...{'id': widget.data['data'][i]['ID']},
          ...{'name': widget.data['data'][i]['name_role']['v']}
        });

    if (widget.data['type'].contains('update')) {
      _nameEdtController.value = TextEditingValue(
          text: widget.data['dataItem']['name_role']['v'].trim() ?? '',
          selection: _nameEdtController.selection);

      _roleIdEdtController.value = TextEditingValue(
          text: widget.data['dataItem']['role_id']['v'].trim() ?? '',
          selection: _roleIdEdtController.selection);
      if (widget.data['dataItem']['role_parent']['v'] != '' &&
          widget.data['dataItem']['role_parent']['v'] != '-1')
        _roleParentSelected = listRole
            .where((item) =>
                item['id'] == widget.data['dataItem']['role_parent']['v'])
            .toList()[0];

      _nameEdtController.addListener(_onTextFieldUpdateChange);
      _roleIdEdtController.addListener(_onTextFieldUpdateChange);
    } else {
      _nameEdtController.addListener(_onTextFieldAddChange);
      _roleIdEdtController.addListener(_onTextFieldAddChange);
    }
  }

  void dispose() {
    if (!mounted) {
      _roleIdEdtController.dispose();
      _nameEdtController.dispose();
    }
    super.dispose();
  }

  _onTextFieldUpdateChange() {
    if ((_nameEdtController.text !=
                widget.data['dataItem']['name_role']['v'].trim() ||
            _roleIdEdtController.text !=
                widget.data['dataItem']['role_id']['v'].trim() ||
            _roleTypeSelected['id'] !=
                widget.data['dataItem']['role_type_id']['v'].trim() ||
            _timeTypeSelected['id'] !=
                widget.data['dataItem']['type_time']['v'].trim() ||
            _departmentSelected['id'] !=
                widget.data['dataItem']['org_id']['v'].trim() ||
        (_roleParentSelected != null && _roleParentSelected['id'] !=
            widget.data['dataItem']['role_parent']['v'].trim())) &&
        (!_forceErrorName && !_forceErrorRoleId)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  _onTextFieldAddChange() {
    if (((_nameEdtController.text.isEmpty &&
                genRow['name_role']['allowNull']) ||
            _nameEdtController.text.isNotEmpty) &&
        ((_roleIdEdtController.text.isEmpty &&
                genRow['role_id']['allowNull']) ||
            _roleIdEdtController.text.isNotEmpty) &&
        ((_roleTypeSelected == null && genRow['role_type_id']['allowNull']) ||
            _roleTypeSelected != null) &&
        ((_timeTypeSelected == null && genRow['type_time']['allowNull']) ||
            _timeTypeSelected != null) &&
        ((_departmentSelected == null && genRow['org_id']['allowNull']) ||
            _departmentSelected != null)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {'TbName': 'vw_tb_hrms_organization_role'},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        genRow =
            Utils.getListGenRow(response.data['data'], widget.data['type']);
      });
  }

  dynamic checkValidValue({bool back = false}) {
    var data = {};
    if (_nameEdtController.text !=
        widget.data['dataItem']['name_role']['v'].trim())
      data = {
        ...data,
        ...{"name_role": _nameEdtController.text}
      };
    if (_roleIdEdtController.text !=
        widget.data['dataItem']['role_id']['v'].trim())
      data = {
        ...data,
        ...{"role_id": _roleIdEdtController.text}
      };
    if (_roleTypeSelected != null)
      data = {
        ...data,
        ...{"role_type_id": _roleTypeSelected["id"]}
      };
    if (_timeTypeSelected != null)
      data = {
        ...data,
        ...{"type_time": _timeTypeSelected["id"]}
      };
    if (_departmentSelected != null)
      data = {
        ...data,
        ...{"org_id": _departmentSelected["id"]}
      };
    if (_roleParentSelected != null)
      data = {
        ...data,
        ...{"role_parent": _roleParentSelected["id"]}
      };
    return data;
  }

  void getRole(BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await BaseViewModel().callApis(
        {}, getDepartmentUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _list.add({'id': list['ID'], 'name': list['name']['v']});
      }
      setState(() {
        listRole.addAll(_list);
      });
    }
  }

  void _getDepartment(BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await BaseViewModel().callApis(
        {}, getDepartmentUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _list.add({'id': list['ID'], 'name': list['name']['v']});
      }
      setState(() {
        listDepartment.clear();
        listDepartment.addAll(_list);
        if (widget.data['type'].contains('update')) if (widget.data['dataItem']
                ['org_id']['v'] !=
            '')
          _departmentSelected = listDepartment
              .where((item) =>
                  item['id'] == widget.data['dataItem']['org_id']['v'])
              .toList()[0];
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void _getRoleType(BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await BaseViewModel().callApis(
        {}, getRoleTypeId, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _list.add({
          'id': list['ID'],
          'name': list['Name']['v'],
          'code_name': list['code_name']['v']
        });
      }
      setState(() {
        listRoleTypeId.clear();
        listRoleTypeId.addAll(_list);
        if (widget.data['type'].contains('update')) if (widget.data['dataItem']
                ['role_type_id'] !=
            '')
          _roleTypeSelected = listRoleTypeId
              .where((item) =>
                  item['id'] == widget.data['dataItem']['role_type_id']['v'])
              .toList()[0];
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void _getTimeType(BaseViewModel model) async {
    List<dynamic> _departmentType = [];
    var response = await BaseViewModel().callApis(
        {}, getTimeTypeUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _departmentType.add({
          'id': list['ID'],
          'name': list['name_time_define']['v'],
          'company_id': list['company_id']['v']
        });
      }
      setState(() {
        listTimeType.clear();
        listTimeType.addAll(_departmentType);
        if (widget.data['type'].contains('update')) if (widget.data['dataItem']
                ['type_time']['v'] !=
            '')
          _timeTypeSelected = listTimeType
              .where((item) =>
                  item['id'] == widget.data['dataItem']['type_time']['v'])
              .toList()[0];
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void updateRole(BaseViewModel model) async {
    var data = await checkValidValue();
    if (data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_organization_role");
      var response = await model.callApis({
        "tbname": encryptData,
        "dataid": widget.data['dataItem']['ID'],
        ...data
      }, updateDataUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      Navigator.pop(context);
      if (response.status.code == 200) {
        _isUpdated = true;
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success));
      } else {
        Navigator.of(context).pop();
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_failed));
      }
    }
  }

  void addData(BaseViewModel model) async {
    showLoadingDialog(context);
    var encryptData = await Utils.encrypt("tb_hrms_organization_role");
    var response = await model.callApis({
      "tbname": encryptData,
      'role_id': _roleIdEdtController.text,
      "name_role": _nameEdtController.text,
      "role_type_id": _roleTypeSelected["id"],
      "type_time": _timeTypeSelected["id"],
      "org_id": _departmentSelected["id"],
      'role_parent':
          _roleParentSelected != null ? _roleParentSelected['id'] : -1
    }, addDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      });
    } else {
      Navigator.of(context).pop();
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_re_get_data_failed));
    }
  }

  void deleteRole(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_organization_role");
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

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        getGenRowDefine(model);
        _getRoleType(model);
        if (!widget.data['type'].toString().contains('addFromDepartment'))
          _getDepartment(model);
        else
          getRole(model);
        Future.delayed(Duration(milliseconds: 0), () {
          _getTimeType(model);
        });
      },
      model: BaseViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () {
          if (_isUpdated)
            Navigator.pop(context, true);
          else
            Navigator.pop(context);
        }, () {
          Utils.closeKeyboard(context);
          if (widget.data['type'].contains('update'))
            showMessageDialog(context,
                description: Utils.getString(context, txt_confirm_delete),
                onPress: () {
              Navigator.pop(context);
              deleteRole(model);
            });
        }, widget.data['appbarTitle'],
            widget.data['type'].contains('update') ? Icons.delete : null),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              Utils.closeKeyboard(context);
            },
            child: genRow.length != 0
                ? Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: Utils.resizeWidthUtil(context, 30)),
                    child:
                        Column(children: <Widget>[_bodyEditDepartment(model)]),
                  )
                : Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Center(child: CircularProgressIndicator())),
          ),
        ),
      ),
    );
  }

  Widget _bodyEditDepartment(BaseViewModel model) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildContentText(
            keyName: 'role_id',
            controller: _roleIdEdtController,
            forceError: _forceErrorRoleId,
            allowNull: genRow['role_id']['allowNull'],
            textCapitalization: TextCapitalization.characters,
            isEnable: genRow['role_id']['allowEdit'],
          ),
          _buildContentText(
              keyName: 'name_role',
              forceError: _forceErrorName,
              allowNull: genRow['name_role']['allowNull'],
              textCapitalization: TextCapitalization.sentences,
              controller: _nameEdtController,
              isEnable: genRow['name_role']['allowEdit']),
          _buildContentSelectBoxRoleTypeId(),
          _buildContentSelectBoxTimeType(),
          _buildContentSelectBoxDepartmentManager(),
          _buildContentSelectBoxRole(),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 50),
          ),
          TKButton(Utils.getString(context, txt_save),
              enable: _enableUpdateButton, width: double.infinity, onPress: () {
            FocusScope.of(context).unfocus();
            if (widget.data['type'].contains('update'))
              updateRole(model);
            else
              addData(model);
          })
        ],
      ),
    );
  }

  Widget _buildContentText(
      {String keyName = '',
      bool isEnable = true,
      bool isExpand = false,
      bool forceError = false,
      bool allowNull = true,
      TextEditingController controller,
      TextCapitalization textCapitalization = TextCapitalization.none,
      Function onPress,
      String icon}) {
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
            boxTitle(context, genRow[keyName]['name']),
            TextFieldCustom(
              controller: controller,
              enable: isEnable,
              imgLeadIcon: icon,
              textCapitalization: textCapitalization,
              expandMultiLine: isExpand,
              forceError: forceError,
              onChange: (changeValue) {
                setState(() {
                  if (!allowNull)
                    switch (keyName) {
                      case 'role_id':
                        _forceErrorRoleId = controller.text.trimRight().isEmpty;
                        break;
                      case 'name_role':
                        _forceErrorName = controller.text.trimRight().isEmpty;
                        break;
                    }
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContentSelectBoxRoleTypeId() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, genRow['role_type_id']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title: _roleTypeSelected == null ? '' : _roleTypeSelected['name'],
            data: listRoleTypeId,
            selectedItem: 0,
            enable: genRow['role_type_id']['allowEdit'],
            clearCallback: () {},
            initCallback: (state) {},
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null) _roleTypeSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _onTextFieldUpdateChange();
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _buildContentSelectBoxTimeType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, genRow['type_time']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title: _timeTypeSelected == null ? '' : _timeTypeSelected['name'],
            data: listTimeType,
            selectedItem: 0,
            clearCallback: () {},
            initCallback: (state) {},
            enable: genRow['type_time']['allowEdit'],
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null) _timeTypeSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _onTextFieldUpdateChange();
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _buildContentSelectBoxDepartmentManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, genRow['org_id']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title:
                _departmentSelected == null ? '' : _departmentSelected['name'],
            data: listDepartment,
            selectedItem: 0,
            enable: _enableDepartment,
            clearCallback: () {},
            initCallback: (state) {},
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null) _departmentSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _onTextFieldUpdateChange();
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _buildContentSelectBoxRole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, genRow['role_parent']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title:
                _roleParentSelected == null ? '' : _roleParentSelected['name'],
            data: listRole,
            selectedItem: 0,
            clearShow: true,
            clearCallback: () {
              setState(() {
                if (widget.data['type']
                    .contains('update')) if (_roleParentSelected != null)
                  _enableUpdateButton = true;
                _roleParentSelected = null;
              });
            },
            initCallback: (state) {},
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null) _roleParentSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _onTextFieldUpdateChange();
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }
}
