import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditDepartmentManagerView extends StatefulWidget {
  final dynamic data;

  EditDepartmentManagerView(this.data);

  @override
  State<StatefulWidget> createState() {
    return _EditDepartmentManagerState();
  }
}

class _EditDepartmentManagerState extends State<EditDepartmentManagerView> {
  ScrollController controller;
  BaseResponse _user;
  final dateTimeFormat = DateFormat("dd/MM/yyyy");
  DateFormat dateTimeDefaultFormat = DateFormat("MM/dd/yyyy HH:mm:ss aaa");

  TextEditingController _nameEdtController = TextEditingController();
  TextEditingController _orgEdtController = TextEditingController();
  TextEditingController _createDateEdtController = TextEditingController();

  TextEditingController _nameTypeEdtController = TextEditingController();
  TextEditingController _idTypeEdtController = TextEditingController();

  TextEditingController _nameTypeGroupEdtController = TextEditingController();
  TextEditingController _tradingNameEdtController = TextEditingController();
  TextEditingController _noteEdtController = TextEditingController();

  bool _enableUpdateButton = false;
  bool _forceErrorName = false;
  bool _forceErrorId = false;
  bool _isUpdated = false;
  bool _activeCheck = false;

  String searchText;
  String chooseRole = "";

  dynamic _departmentSelected;
  dynamic _departmentTypeSelected;
  dynamic _departmentTypeGroupSelected;

  List<dynamic> departmentList = [];
  List<dynamic> departmentType = [];
  List<dynamic> departmentTypeGroup = [];
  List<dynamic> listRole = [];
  dynamic genRow = {};
  dynamic _genRowType = {};
  dynamic _genRowTypeGroup = {};

  void initState() {
    super.initState();
    _user = context.read<BaseResponse>();
    controller = ScrollController();
    for (int i = 0; i < widget.data['data'].length; i++)
      departmentList.add({
        ...{'id': widget.data['data'][i]['ID']},
        ...{'name': widget.data['data'][i]['name']['v']}
      });

    if (widget.data['type'].contains('update'))
      initData();
    else {
      _nameEdtController.addListener(_onTextFieldAddChange);
      _orgEdtController.addListener(_onTextFieldAddChange);
    }
  }

  void dispose() {
    if (!mounted) {
      _nameEdtController.dispose();
      _orgEdtController.dispose();
      _createDateEdtController.dispose();
    }
    super.dispose();
  }

  initData() {
    _nameEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['name']['v'].trim() ?? '',
        selection: _nameEdtController.selection);

    _orgEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['ma_org']['v'].trim() ?? '',
        selection: _orgEdtController.selection);

    _createDateEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['create_date']['v'] != ''
            ? dateTimeFormat.format(dateTimeDefaultFormat
                .parse(widget.data['dataItem']['create_date']['v']))
            : dateTimeFormat.format(DateTime.now()),
        selection: _createDateEdtController.selection);

    _nameEdtController.addListener(_onTextFieldUpdateChange);
    _orgEdtController.addListener(_onTextFieldUpdateChange);
    //_createDateEdtController.addListener(_onTextFieldChange);

    if (widget.data['dataItem']['parent_id']['v'] != '' &&
        widget.data['dataItem']['parent_id']['v'] != '-1') {
      _departmentSelected = departmentList
          .where(
              (item) => item['id'] == widget.data['dataItem']['parent_id']['v'])
          .toList()[0];
    }
  }

  _onTextFieldUpdateChange() {
    if ((_nameEdtController.text !=
        widget.data['dataItem']['name']['v'].trim() ||
        _orgEdtController.text !=
            widget.data['dataItem']['ma_org']['v'].trim()) &&
        (((_departmentTypeGroupSelected == null &&
            genRow['type']['allowNull']) ||
            _departmentTypeGroupSelected != null) ||
            ((_departmentTypeSelected == null &&
                genRow['department_id']['allowNull']) ||
                _departmentTypeSelected != null)) && (!_forceErrorName && !_forceErrorId)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  _onTextFieldAddChange() {
    if (((_nameEdtController.text.isEmpty && genRow['name']['allowNull']) ||
            _nameEdtController.text.isNotEmpty) &&
        ((_orgEdtController.text.isEmpty && genRow['ma_org']['allowNull']) ||
            _orgEdtController.text.isNotEmpty) &&
        ((_departmentTypeGroupSelected == null &&
                genRow['type']['allowNull']) ||
            _departmentTypeGroupSelected != null) &&
        ((_departmentTypeSelected == null &&
                genRow['department_id']['allowNull']) ||
            _departmentTypeSelected != null) &&
        ((_createDateEdtController.text.isEmpty &&
                genRow['create_date']['allowNull']) ||
            _createDateEdtController.text.isNotEmpty)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {'TbName': 'vw_tb_hrms_organization_depertment'},
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

  dynamic checkValidValue() {
    var data = {};
    if (_nameEdtController.text != widget.data['dataItem']['name']['v'].trim())
      data = {
        ...data,
        ...{"name": _nameEdtController.text}
      };
    if (_orgEdtController.text != widget.data['dataItem']['ma_org']['v'].trim())
      data = {
        ...data,
        ...{"ma_org": _orgEdtController.text}
      };
    data = {
      ...data,
      ...{
        "parent_id":
            _departmentSelected == null ? -1 : _departmentSelected["id"]
      }
    };

    if (_departmentTypeSelected != null)
      data = {
        ...data,
        ...{"department_id": _departmentTypeSelected["id"]}
      };
    if (_departmentTypeGroupSelected != null)
      data = {
        ...data,
        ...{"type": _departmentTypeGroupSelected["id"]}
      };
    return data;
  }

  void _getDataDepartmentType(BaseViewModel model) async {
    List<dynamic> _departmentType = [];
    var response = await BaseViewModel().callApis(
        {}, departmentTypeUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _departmentType.add({
          'id': list['ID'],
          'name': list['name_department']['v'],
          'company_id': list['company_id']['v']
        });
      }
      setState(() {
        departmentType.clear();
        departmentType.addAll(_departmentType);
        if (widget.data['type'].contains('update')) if (widget.data['dataItem']
                ['department_id']['v'] !=
            '')
          _departmentTypeSelected = departmentType
              .where((item) =>
                  item['id'] == widget.data['dataItem']['department_id']['v'])
              .toList()[0];
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void _getDataDepartmentTypeGroup(BaseViewModel model) async {
    List<dynamic> _departmentTypeGroup = [];
    departmentTypeGroup.clear();
    var response = await BaseViewModel().callApis(
        {}, departmentTypeGroupUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _departmentTypeGroup.add({
          'id': list['ID'],
          'name': list['name']['v'],
          'company_id': list['company_id']['v']
        });
      }
      setState(() {
        departmentTypeGroup.addAll(_departmentTypeGroup);
        if (widget.data['type']
            .contains('update')) if (widget.data['dataItem']['type']['v'] != '')
          _departmentTypeGroupSelected = departmentTypeGroup
              .where(
                  (item) => item['id'] == widget.data['dataItem']['type']['v'])
              .toList()[0];
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void _getListDataRole(BaseViewModel model) async {
    List<dynamic> _listRole = [];
    listRole.clear();
    var response = await BaseViewModel().callApis({
      'org_id': 'org_id = ${widget.data['dataItem']['ID']}',
      'search_text': ''
    }, orgRoleUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _listRole.add({
          'id': list['ID'],
          'name': list['name_role']['v'],
          'org_id': list['org_id']['v'],
          'role_id': list['role_id']['v']
        });
      }
      setState(() {
        listRole.addAll(_listRole);
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void updateDepartment(BaseViewModel model) async {
    var data = await checkValidValue();
    if (data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_organization_depertment");
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
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_failed));
      }
    }
  }

  void deleteDepartment(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_organization_depertment");
    showLoadingDialog(context);
    var deleteDepartmentResponse = await model.callApis(
        {"tbname": encryptData, "dataid": widget.data['dataItem']['ID']},
        deleteDataUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    Navigator.pop(context);
    if (deleteDepartmentResponse.status.code == 200) {
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

  void deleteRole(BaseViewModel model, StateSetter setModalState) async {
    var encryptData = await Utils.encrypt("vw_tb_hrms_organization_role");
    showLoadingDialog(context);
    var deleteRoleResponse = await model.callApis(
        {"tbname": encryptData, "dataid": chooseRole},
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
        Navigator.pop(context);
        Navigator.pop(context);
        _getListDataRole(model);
        setModalState(() {});
      });
    } else {
      Navigator.of(context).pop();
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
    }
  }

  void addDepartment(BaseViewModel model) async {
    showLoadingDialog(context);
    var companyInfo = await SecureStorage().companyInfo;
    var encryptData = await Utils.encrypt("tb_hrms_organization_depertment");
    var submitResponse = await model.callApis({
      "tbname": encryptData,
      "company_id": json.decode(companyInfo)['ID'],
      "parent_id": _departmentSelected == null ? -1 : _departmentSelected['id'],
      "name": _nameEdtController.text,
      "ma_org": _orgEdtController.text,
      "department_id": _departmentTypeSelected['id'],
      "type": _departmentTypeGroupSelected['id'],
      "create_date": _createDateEdtController.text
    }, addDataUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    Navigator.pop(context);
    if (submitResponse.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context, true);
      });
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_update_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  _getGenRowType(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_organization_depertment_type"},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _genRowType = Utils.getListGenRow(response.data['data'], 'add');
      });
  }

  _getGenRowTypeGroup(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_organization_depertment_type_group"},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _genRowTypeGroup = Utils.getListGenRow(response.data['data'], 'add');
      });
  }

  void _callAddTdType(BaseViewModel model) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              border: Border.all(style: BorderStyle.none),
            ),
            child: StatefulBuilder(builder: (context, setModalState) {
              return _buildAddTdType(model, setModalState);
            })),
      ),
    );
  }

  void _callAddTdTypeGroup(BaseViewModel model) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) => SingleChildScrollView(
        child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              border: Border.all(style: BorderStyle.none),
            ),
            child: StatefulBuilder(builder: (context, setModalState) {
              return _buildAddTdTypeGroup(model, setModalState);
            })),
      ),
    );
  }

  void _addTimeDefineType(BaseViewModel model) async {
    showLoadingDialog(context);
    var encryptData = await Utils.encrypt("vw_tb_hrms_organization_depertment_type");
    var response = await model.callApis({
      'tbname': encryptData,
      'name_department': _nameTypeEdtController.text,
      'company_id': _user.data['data'][0]['company_id']['v'],
      '_id_department': _idTypeEdtController.text
    }, addDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
            Navigator.pop(context);
            Navigator.pop(context);
          });
      _nameTypeEdtController.text = '';
      _idTypeEdtController.text = '';
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
  }

  void _addTimeDefineTypeGroup(BaseViewModel model) async {
    showLoadingDialog(context);
    var encryptData = await Utils.encrypt("vw_tb_hrms_organization_depertment_type_group");
    var response = await model.callApis({
      'tbname': encryptData,
      'name': _nameTypeGroupEdtController.text,
      'company_id': _user.data['data'][0]['company_id']['v'],
      'tengiaodich': _tradingNameEdtController.text,
      'ghichu': _noteEdtController.text,
      'Active': _activeCheck
    }, addDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
            Navigator.pop(context);
            Navigator.pop(context);
          });
      _nameTypeGroupEdtController.text = '';
      _tradingNameEdtController.text = '';
      _noteEdtController.text = '';
      _activeCheck = false;
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        getGenRowDefine(model);
        _getGenRowType(model);
        _getGenRowTypeGroup(model);
        _getDataDepartmentType(model);
        _getDataDepartmentTypeGroup(model);
        if (widget.data['type'].contains('update'))
          Future.delayed(Duration(milliseconds: 0), () {
            _getListDataRole(model);
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
              deleteDepartment(model);
            });
        },
            widget.data['appbarTitle'],
            widget.data['type'].toString().contains('update')
                ? Icons.delete
                : null),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              Utils.closeKeyboard(context);
            },
            child: genRow.length > 0
                ? Container(
                    padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
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
              keyName: 'ma_org',
              controller: _orgEdtController,
              foreError: _forceErrorId,
              textCapitalization: TextCapitalization.characters,
              isEnable: genRow['ma_org']['allowEdit'],
              genRowType: genRow),
          _buildContentText(
              keyName: 'name',
              controller: _nameEdtController,
              foreError: _forceErrorName,
              isEnable: genRow['name']['allowEdit'],
              genRowType: genRow),
          _buildContentSelectBoxDepartmentType(model),
          SizedBox(height: Utils.resizeHeightUtil(context, 10)),
          _buildContentSelectBoxDepartmentTypeGroup(model),
          SizedBox(height: Utils.resizeHeightUtil(context, 10)),
          _buildContentSelectBoxDepartmentManager(),
          SizedBox(height: Utils.resizeHeightUtil(context, 10)),
          _buildContentText(
              keyName: 'create_date',
              controller: _createDateEdtController,
              icon: ic_calendar,
              isEnable: false,
              genRowType: genRow,
              onPress: genRow['create_date']['allowEdit']
                  ? () {
                      if (widget.data['type'].contains('add'))
                        showDatePicker(
                                context: context,
                                initialDate: DateFormat('yyyy-MM-dd').parse(
                                    _createDateEdtController.text != ''
                                        ? DateFormat('dd/MM/yyyy')
                                            .parse(
                                                _createDateEdtController.text)
                                            .toString()
                                        : DateTime.now().toString()),
                                firstDate: DateTime(1900),
                                lastDate: DateTime(2100))
                            .then((value) {
                          if (value == null) return;
                          setState(() {
                            _createDateEdtController.text =
                                dateTimeFormat.format(value);
                            if (widget.data['type'].contains('update'))
                              _onTextFieldUpdateChange();
                            else
                              _onTextFieldAddChange();
                          });
                        });
                    }
                  : () {}),
          SizedBox(height: Utils.resizeHeightUtil(context, 10)),
          if (widget.data['type'].contains('update')) _role(model),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 30),
          ),
          TKButton(Utils.getString(context, txt_save),
              enable: _enableUpdateButton, width: double.infinity, onPress: () {
            FocusScope.of(context).unfocus();
            if (widget.data['type'].contains('update'))
              updateDepartment(model);
            else
              addDepartment(model);
          })
        ],
      ),
    );
  }

  Widget _buildContentText(
      {String keyName,
      bool isEnable = true,
      bool isExpand = false,
      bool foreError = false,
      bool allowNull = false,
      TextEditingController controller,
      TextCapitalization textCapitalization = TextCapitalization.none,
      Function onPress,
      String icon,
        dynamic genRowType,
        TextInputType textInputType = TextInputType.text,}) {
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
            boxTitle(context, genRowType[keyName]['name']),
            TextFieldCustom(
              controller: controller,
              enable: isEnable,
              imgLeadIcon: icon,
              textCapitalization: textCapitalization,
              expandMultiLine: isExpand,
              forceError: foreError,
              onChange: (changeValue) {
                setState(() {
                  if (!allowNull) {
                    switch (keyName) {
                      case 'ma_org':
                        _forceErrorId = controller.text.trimRight().isEmpty;
                        break;
                      case 'name':
                        _forceErrorName = controller.text.trimRight().isEmpty;
                    }
                  }
                });
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContentSelectBoxDepartmentManager() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, genRow['parent_id']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title:
                _departmentSelected == null ? '' : _departmentSelected['name'],
            data: departmentList,
            selectedItem: 0,
            clearShow: true,
            clearCallback: () {
              setState(() {
                if (widget.data['type']
                    .contains('update')) if (_departmentSelected != null)
                  _enableUpdateButton = true;
                _departmentSelected = null;
              });
            },
            enable: genRow['parent_id']['allowEdit'],
            initCallback: (state) {},
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null) _departmentSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _enableUpdateButton = true;
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _buildContentSelectBoxDepartmentType(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            boxTitle(context, genRow['department_id']['name']),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 20),
            ),
            GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  _callAddTdType(model);
                },
                child: Icon(
                  Icons.add_circle,
                  color: only_color,
                  size: 30,
                ))
          ],
        ),
        SelectBoxCustomUtil(
            enableSearch: false,
            title: _departmentTypeSelected == null
                ? ''
                : _departmentTypeSelected['name'],
            data: departmentType,
            selectedItem: 0,
            enable: genRow['department_id']['allowEdit'],
            clearCallback: () {},
            initCallback: (state) {},
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null)
                  _departmentTypeSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _enableUpdateButton = true;
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _buildContentSelectBoxDepartmentTypeGroup(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            boxTitle(context, genRow['type']['name']),
            SizedBox(
              width: Utils.resizeWidthUtil(context, 20),
            ),
            GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  _callAddTdTypeGroup(model);
                },
                child: Icon(
                  Icons.add_circle,
                  color: only_color,
                  size: 30,
                ))
          ],
        ),
        SelectBoxCustomUtil(
            enableSearch: false,
            title: _departmentTypeGroupSelected == null
                ? ''
                : _departmentTypeGroupSelected['name'],
            data: departmentTypeGroup,
            selectedItem: 0,
            clearCallback: () {},
            initCallback: (state) {},
            enable: genRow['type']['allowEdit'],
            loadMoreCallback: (state) {},
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null)
                  _departmentTypeGroupSelected = itemSelected;
                if (widget.data['type'].contains('update'))
                  _enableUpdateButton = true;
                else
                  _onTextFieldAddChange();
              });
            }),
      ],
    );
  }

  Widget _role(BaseViewModel model) {
    return Container(
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            context: context,
            builder: (context) => Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding:
                    EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft:
                        Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
                    topRight:
                        Radius.circular(Utils.resizeWidthUtil(context, 30.0)),
                  ),
                ),
                child: StatefulBuilder(builder: (context, setModalState) {
                  return _listRole(context, setModalState, model: model);
                })),
          );
        },
        child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: border_text_field),
                borderRadius:
                    BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
            padding: EdgeInsets.symmetric(
                horizontal: Utils.resizeWidthUtil(context, 10)),
            height: Utils.resizeHeightUtil(context, 90),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                TKText(
                  "Danh sách chức vụ",
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
  }

  Widget _listRole(BuildContext context, StateSetter setModalState,
      {BaseViewModel model, int index}) {
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
        Expanded(
          child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              controller: controller,
              scrollDirection: Axis.vertical,
              itemCount: listRole.length,
              itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      setModalState(() {
                        if (chooseRole == '' ||
                            chooseRole != listRole[index]['id'].toString())
                          chooseRole = listRole[index]['id'].toString();
                        else
                          chooseRole = '';
                        print(chooseRole);
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          vertical: Utils.resizeHeightUtil(context, 20)),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: chooseRole == listRole[index]['id'].toString()
                              ? txt_grey_color_v1.withOpacity(0.3)
                              : Colors.white,
                          border: Border(
                              bottom: BorderSide(
                                  color: txt_grey_color_v3.withOpacity(0.2)))),
                      child: Column(
                        children: <Widget>[
                          TKText(
                            listRole[index]['name'],
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                                decoration: TextDecoration.none,
                                fontSize: Utils.resizeWidthUtil(context, 28),
                                color: txt_grey_color_v3),
                          ),
                          TKText(
                            listRole[index]['role_id'],
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
        Padding(
          padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 20)),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TKButton(
                  Utils.getString(context, txt_add),
                  width: MediaQuery.of(context).size.width,
                  onPress: () {
                    Navigator.pushNamed(context, Routers.editRoleManager,
                        arguments: {
                          'type': 'addFromDepartment',
                          'appbarTitle': 'Thêm chức vụ',
                          'data': widget.data['dataItem']
                        }).then((value) {
                      if (value != null && value) {
                        _getListDataRole(model);
                        setModalState(() {});
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: Utils.resizeHeightUtil(context, 30),
              ),
              Expanded(
                child: TKButton(
                  Utils.getString(context, txt_delete),
                  width: MediaQuery.of(context).size.width,
                  backgroundColor: txt_fail_color,
                  enable: chooseRole == '' ? false : true,
                  onPress: () {
                    Utils.closeKeyboard(context);
                    showMessageDialog(context,
                        description:
                            Utils.getString(context, txt_confirm_delete),
                        onPress: () {
                      deleteRole(model, setModalState);
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildAddTdType(BaseViewModel model, StateSetter modalState) =>
      Container(
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
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildContentText(
                      keyName: '_id_department',
                      controller: _idTypeEdtController,
                      genRowType: _genRowType,
                      isEnable: _genRowType['_id_department']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  _buildContentText(
                      keyName: 'name_department',
                      controller: _nameTypeEdtController,
                      genRowType: _genRowType,
                      isEnable: _genRowType['name_department']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 20),
                  ),
                  TKButton(Utils.getString(context, txt_save),
                      enable: true, width: double.infinity, onPress: () {
                        FocusScope.of(context).unfocus();
                        if (_nameTypeEdtController.text.isNotEmpty &&
                            _idTypeEdtController.text.isNotEmpty)
                          _addTimeDefineType(model);
                        else
                          showMessageDialogIOS(context,
                              description:
                              Utils.getString(context, txt_text_field_empty));
                      }),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  )
                ],
              ),
            ),
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
          ],
        ),
      );

  Widget _buildAddTdTypeGroup(BaseViewModel model, StateSetter modalState) =>
      Container(
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
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildContentText(
                      keyName: 'name',
                      controller: _nameTypeGroupEdtController,
                      genRowType: _genRowTypeGroup,
                      isEnable: _genRowTypeGroup['name']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  _buildContentText(
                      keyName: 'tengiaodich',
                      controller: _tradingNameEdtController,
                      genRowType: _genRowTypeGroup,
                      isEnable: _genRowTypeGroup['tengiaodich']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  _buildContentText(
                      keyName: 'ghichu',
                      controller: _noteEdtController,
                      genRowType: _genRowTypeGroup,
                      isEnable: _genRowTypeGroup['ghichu']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  _buildCheckBox(_genRowTypeGroup['Active']['name'], _activeCheck,
                      modalState),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 20),
                  ),
                  TKButton(Utils.getString(context, txt_save),
                      enable: true, width: double.infinity, onPress: () {
                        FocusScope.of(context).unfocus();
                        if (_nameTypeGroupEdtController.text.isNotEmpty)
                          _addTimeDefineTypeGroup(model);
                        else
                          showMessageDialogIOS(context,
                              description:
                              Utils.getString(context, txt_text_field_empty));
                      }),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 30),
                  )
                ],
              ),
            ),
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
          ],
        ),
      );

  Widget _buildCheckBox(String title, bool check, StateSetter modalState) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          modalState(() {
            if (title == _genRowTypeGroup['Active']['name'])
              _activeCheck = !_activeCheck;
          });
        },
        child: Row(
          children: <Widget>[
            Expanded(
              child: boxTitle(context, title),
            ),
            check
                ? Icon(Icons.radio_button_checked, size: 30, color: only_color)
                : Icon(Icons.radio_button_unchecked,
                size: 30, color: txt_grey_color_v1)
          ],
        ),
      );
}
