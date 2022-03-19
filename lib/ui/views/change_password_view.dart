import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class ChangePasswordView extends StatefulWidget {
  ChangePasswordView();

  @override
  _ChangePasswordViewState createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<ChangePasswordView> {
  TextEditingController _oldPasswordEdtController = TextEditingController();

  TextEditingController _newPasswordEdtController = TextEditingController();

  TextEditingController _rePasswordEdtController = TextEditingController();

  bool _forceErrorNewPassword = false;

  bool _forceErrorConfirmPassword = false;

  bool _forceErrorOldPassword = false;

  bool _enableUpdateButton = false;
  bool _hideOldPass = true;
  bool _hideNewPass = true;
  bool _hideReNewPass = true;

  @override
  void initState() {
    super.initState();
    _oldPasswordEdtController.addListener(_onTextFieldChange);
    _newPasswordEdtController.addListener(_onTextFieldChange);
    _rePasswordEdtController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    if (!mounted) {
      _oldPasswordEdtController.dispose();
      _newPasswordEdtController.dispose();
      _rePasswordEdtController.dispose();
    }
    super.dispose();
  }

  _onTextFieldChange() {
    if (_newPasswordEdtController.text.length > 0 &&
        _rePasswordEdtController.text.length > 0 &&
        _oldPasswordEdtController.text.length > 0 &&
        _newPasswordEdtController.text == _rePasswordEdtController.text) {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  dynamic checkValidate() {
    var data = {};

    if (_newPasswordEdtController.text != _rePasswordEdtController.text)
      return null;

    if (_newPasswordEdtController.text == '' ||
        _rePasswordEdtController.text == '' ||
        _oldPasswordEdtController.text == '') return null;

    if (_newPasswordEdtController.text != "" &&
        _rePasswordEdtController.text != "")
      data = {
        ...data,
        ...{"colPass": _newPasswordEdtController.text}
      };

    return data;
  }

  void submitData(BaseViewModel model) async {
    var data = checkValidate();
    if (data != null) {
      showLoadingDialog(context);
      String oldPassword = await SecureStorage().getCustomString(SecureStorage.PASSWORD);
      if(oldPassword == _oldPasswordEdtController.text) {
        var updateResponse = await model.callApis(
            data, changePasswordUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.pop(context);
        if (updateResponse.status.code == 200) {
          await SecureStorage()
              .saveCustomString(SecureStorage.IS_USING_AUTHORIZATION, 'false');
          await SecureStorage()
              .saveCustomString(SecureStorage.CHANGE_PASSWORD, 'true');
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_change_password_success),
              onPress: () =>
                  Navigator.popUntil(context, ModalRoute.withName(Routers.main)));
        } else
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_update_failed));
      } else {
        Navigator.pop(context);
        showMessageDialogIOS(context,
            description: Utils.getString(
                context, txt_current_password_incorrect));
      }
    } else {
      if (_newPasswordEdtController.text != _rePasswordEdtController.text) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_password_does_not_match));
      } else {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_text_field_empty));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {},
      builder: (context, model, child) => Scaffold(
          appBar: appBarCustom(context, () => Navigator.pop(context), () {},
              Utils.getString(context, txt_title_password_change), null),
          body: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 30)),
              child: Column(
                children: <Widget>[
                  _buildContentText(Utils.getString(context, txt_old_password),
                      controller: _oldPasswordEdtController, visibleSuffix: _hideOldPass),
                  _buildContentText(Utils.getString(context, txt_new_password),
                      controller: _newPasswordEdtController, visibleSuffix: _hideNewPass),
                  _buildContentText(
                      Utils.getString(context, txt_re_new_password),
                      controller: _rePasswordEdtController, visibleSuffix: _hideReNewPass),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 50),
                  ),
                  TKButton(Utils.getString(context, txt_update_password),
                      enable: _enableUpdateButton,
                      width: double.infinity, onPress: () {
                    Utils.closeKeyboard(context);
                    submitData(model);
                  })
                ],
              ),
            ),
          )),
    );
  }

  Widget _buildContentText(String title,
      {bool isEnable = true,
      bool isExpand = false,
      bool isObscureText = true,
      TextEditingController controller,
      bool showSuffix = true,
      bool visibleSuffix = false,
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
            _buildTitle(title),
            TextFieldCustom(
                obscureText: visibleSuffix,
                maxLine: 1,
                controller: controller,
                enable: isEnable,
                imgLeadIcon: icon,
                isShowSuffix: showSuffix,
                expandMultiLine: isExpand,
                forceError: title == Utils.getString(context, txt_new_password)
                    ? _forceErrorNewPassword
                    : title == Utils.getString(context, txt_re_new_password)
                        ? _forceErrorConfirmPassword
                        : _forceErrorOldPassword,
                onChange: (changeValue) {
                  setState(() {
                    title == Utils.getString(context, txt_new_password)
                        ? _forceErrorNewPassword =
                            controller.text.trimRight().isEmpty
                        : title == Utils.getString(context, txt_re_new_password)
                            ? _forceErrorConfirmPassword =
                                controller.text.trimRight().isEmpty
                            : _forceErrorOldPassword =
                                controller.text.trimRight().isEmpty;
                  });
                },
              onSuffixChange: () {
                  setState(() {
                    if(title == Utils.getString(context, txt_old_password))
                      _hideOldPass = !_hideOldPass;
                    else if(title == Utils.getString(context, txt_new_password))
                      _hideNewPass = !_hideNewPass;
                    else _hideReNewPass = !_hideReNewPass;
                  });
              },
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Container(
      padding:
          EdgeInsets.symmetric(vertical: Utils.resizeHeightUtil(context, 15)),
      child: TKText(
        title,
        tkFont: TKFont.SFProDisplayRegular,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 32),
            color: txt_grey_color_v3),
      ),
    );
  }
}
