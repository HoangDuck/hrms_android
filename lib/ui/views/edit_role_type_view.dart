import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/checkbox_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:provider/provider.dart';

class EditRoleTypeView extends StatefulWidget {
  final dynamic data;

  EditRoleTypeView(this.data);

  @override
  State<StatefulWidget> createState() {
    return _EditRoleTypeState();
  }
}

class _EditRoleTypeState extends State<EditRoleTypeView> {
  BaseResponse _user;
  TextEditingController _roleIdEdtController = TextEditingController();
  TextEditingController _nameEdtController = TextEditingController();
  TextEditingController _enNameEdtController = TextEditingController();

  bool _enableUpdateButton = false;
  bool _forceErrorRoleId = false;
  bool _forceErrorName = false;
  bool _forceErrorEnName = false;
  bool _forceErrorLevel = false;
  bool _forceErrorCapBac = false;
  bool _isUpdated = false;
  bool _active = false;
  dynamic genRow = {};

  void initState() {
    super.initState();
    _user = context.read<BaseResponse>();
    if (widget.data['type'].contains('update'))
      initData();
    else {
      _nameEdtController.addListener(_onTextFieldAddChange);
      _roleIdEdtController.addListener(_onTextFieldAddChange);
      _enNameEdtController.addListener(_onTextFieldAddChange);
    }
  }

  void dispose() {
    if (!mounted) {
      _roleIdEdtController.dispose();
      _nameEdtController.dispose();
      _enNameEdtController.dispose();
    }
    super.dispose();
  }

  initData() {
    _nameEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['Name']['v'].trim() ?? '',
        selection: _nameEdtController.selection);
    _roleIdEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['code_name']['v'].trim() ?? '',
        selection: _roleIdEdtController.selection);
    _enNameEdtController.value = TextEditingValue(
        text: widget.data['dataItem']['en_name_role_type']['v'].trim() ?? '',
        selection: _enNameEdtController.selection);
    _active = widget.data['dataItem']['Active']['v'] == 'True' ? true : false;

    _nameEdtController.addListener(_onTextFieldUpdateChange);
    _roleIdEdtController.addListener(_onTextFieldUpdateChange);
    _enNameEdtController.addListener(_onTextFieldUpdateChange);
  }

  _onTextFieldUpdateChange() {
    if ((_nameEdtController.text !=
                widget.data['dataItem']['Name']['v'].trim() ||
            _roleIdEdtController.text !=
                widget.data['dataItem']['code_name']['v'].trim() ||
            _enNameEdtController.text !=
                widget.data['dataItem']['en_name_role_type']['v'].trim() ||
            ((widget.data['dataItem']['Active']['v'] == 'True' && !_active) ||
                (widget.data['dataItem']['Active']['v'] == 'False' &&
                    _active))) &&
        (!_forceErrorName &&
            !_forceErrorRoleId &&
            !_forceErrorEnName &&
            !_forceErrorLevel &&
            !_forceErrorCapBac)) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  _onTextFieldAddChange() {
    if (_nameEdtController.text.isNotEmpty) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {'TbName': 'vw_tb_hrms_organization_role_type'},
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
    if (_nameEdtController.text != widget.data['dataItem']['Name']['v'].trim())
      data = {
        ...data,
        ...{"Name": _nameEdtController.text}
      };
    if (_roleIdEdtController.text !=
        widget.data['dataItem']['code_name']['v'].trim())
      data = {
        ...data,
        ...{"code_name": _roleIdEdtController.text}
      };
    if (_enNameEdtController.text !=
        widget.data['dataItem']['en_name_role_type']['v'].trim())
      data = {
        ...data,
        ...{"en_name_role_type": _enNameEdtController.text}
      };
    if(((widget.data['dataItem']['Active']['v'] == 'True' && !_active) ||
        (widget.data['dataItem']['Active']['v'] == 'False' &&
            _active)))
      data = {
        ...data,
        ...{"Active": _active}
      };
    return data;
  }

  void updateRoleType(BaseViewModel model) async {
    var data = await checkValidValue();
    if (data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_organization_role_type");
      var updateRoleTypeResponse = await model.callApis({
        "tbname": encryptData,
        "dataid": widget.data['dataItem']['ID'],
        ...data
      }, updateDataUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      Navigator.pop(context);
      if (updateRoleTypeResponse.status.code == 200) {
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

  void deleteRoleType(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_organization_role_type");
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

  void addRoleType(BaseViewModel model) async {
    var encryptData = await Utils.encrypt("tb_hrms_organization_role_type");
    var data = {
      "tbname": encryptData,
      "code_name": _roleIdEdtController.text,
      "Name": _nameEdtController.text,
      "en_name_role_type": _enNameEdtController.text,
      "Active": _active,
      "company_id": _user.data['data'][0]['company_id']['v'],
    };
    showLoadingDialog(context);
    var submitResponse = await model.callApis(data, addDataUrl, method_post,
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

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        getGenRowDefine(model);
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
              deleteRoleType(model);
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
                    padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
                    child: Column(children: <Widget>[
                      _bodyEditRoleType(model),
                    ]),
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

  Widget _bodyEditRoleType(BaseViewModel model) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildContentText(
              keyName: 'code_name',
              controller: _roleIdEdtController,
              foreError: _forceErrorRoleId,
              allowNull: genRow['code_name']['allowNull'],
              isEnable: genRow['code_name']['allowEdit']),
          _buildContentText(
              keyName: 'Name',
              controller: _nameEdtController,
              foreError: _forceErrorName,
              allowNull: genRow['code_name']['allowNull'],
              isEnable: genRow['code_name']['allowEdit']),
          _buildContentText(
              keyName: 'en_name_role_type',
              controller: _enNameEdtController,
              foreError: _forceErrorEnName,
              allowNull: genRow['en_name_role_type']['allowNull'],
              isEnable: genRow['en_name_role_type']['allowEdit']),
          checkBoxCustom(
              context: context,
              title: genRow['Active']['name'],
              check: _active,
              onTap: () {
                _active = !_active;
                if(widget.data['type'].contains('update'))
                  _onTextFieldUpdateChange();
                else _onTextFieldAddChange();
              }
              ),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 50),
          ),
          TKButton(Utils.getString(context, txt_save),
              enable: _enableUpdateButton, width: double.infinity, onPress: () {
            FocusScope.of(context).unfocus();
            if (widget.data['type'].contains('update'))
              updateRoleType(model);
            else
              addRoleType(model);
          })
        ],
      ),
    );
  }

  Widget _buildContentText(
      {String keyName = '',
      bool isEnable = true,
      bool isExpand = false,
      bool foreError = false,
      bool allowNull = true,
      TextEditingController controller,
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
              expandMultiLine: isExpand,
              forceError: foreError,
              onChange: (changeValue) {
                setState(() {
                  if (!allowNull)
                    switch (keyName) {
                      case 'code_name':
                        _forceErrorRoleId = controller.text.trimRight().isEmpty;
                        break;
                      case 'Name':
                        _forceErrorName = controller.text.trimRight().isEmpty;
                        break;
                      case 'en_name_role_type':
                        _forceErrorEnName = controller.text.trimRight().isEmpty;
                    }
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
