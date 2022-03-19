import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/custom_switch_button.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:provider/provider.dart';

class SettingAuthorizationView extends StatefulWidget {
  final String title;

  SettingAuthorizationView(this.title);

  @override
  _SettingAuthorizationViewState createState() => _SettingAuthorizationViewState();
}

class _SettingAuthorizationViewState extends State<SettingAuthorizationView> {
  dynamic _genRow = {};
  List<dynamic> _data = [];
  bool loading = true;
  String _dataID;
  List<dynamic> _languageList = [];
  dynamic _languageSelected;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void getGenRow(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "tbAccountInfo_Extend"}, getGenRowDefineUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      _genRow = Utils.getListGenRow(response.data['data'], 'update');
      getListLanguage(model);
      setState(() {
        loading = false;
      });
    }
  }

  void getListLanguage(BaseViewModel model) async {
    var response = await model
        .callApis({}, languageUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      _languageList = response.data['data'];
      getDataSetting(model);
    }
  }

  void getDataSetting(BaseViewModel model) async {
    var _user = await SecureStorage().userProfile;
    List<dynamic> _list = [];
    var response = await model
        .callApis({}, userSetting, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      _dataID = response.data['data'][0]['ID'];
      _languageSelected = _languageList
          .where((item) =>
              item['ID'].toString().contains(response.data['data'][0]['Language_ID']['v']))
          .toList()[0];
      response.data['data'][0].forEach((k, v) {
        if (k != 'ID' &&
            k != 'ID_Slug' &&
            k != 'UserAccount_ID' &&
            k != 'colAccountID' &&
            k != 'colAccountID_Modified' &&
            k != 'colDateAdd' &&
            k != 'colDateModified' &&
            k != 'colStatus' &&
            k != 'colLog')
          _list.add({
            'name': _genRow[k]['name'],
            'value': k == 'Timekeeping_IsFaceAuto' ? _user.data['data'][0]['Timekeeping_IsFaceAuto']['v'] : v['v'],
            'enable': _genRow[k]['allowEdit'],
            'keyName': k,
            'dataType': _genRow[k]['dataType'],
            'show': _genRow[k]['show'].toString().contains('hide') ||
                    _genRow[k]['show'].toString().contains('hidden')
                ? false
                : true,
          });
      });
      setState(() {
        _data = _list;
      });
    }
  }

  void updateChange(BaseViewModel model, String keyName, dynamic value) async {
    showLoadingDialog(context);
    var encryptData = await Utils.encrypt("tbAccountInfo_Extend");
    var response = await BaseViewModel().callApis({
      "tbname": encryptData,
      "dataid": _dataID,
      ...{keyName: value}
    }, updateDataUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      var profileResponse = await model.callApis({}, userProfileUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (profileResponse.status.code == 200) {
        await SecureStorage().saveProfileCustomer(profileResponse);
        context.read<BaseResponse>().addData(profileResponse.data);
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
      showMessageDialogIOS(context, description: Utils.getString(context, txt_update_failed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        getGenRow(model);
      },
      builder: (context, model, child) => Scaffold(
          appBar: appBarCustom(context, () => Navigator.pop(context, true), () {},
              Utils.getString(context, txt_user_setting), null),
          body: !loading
              ? ListView.builder(
                  itemCount: _data.length,
                  itemBuilder: (context, index) {
                    if (_data[index]['show'])
                      return itemOption(model,
                          title: _data[index]['name'],
                          enable: _data[index]['enable'],
                          value: _data[index]['value'] == 'False' ? false : true,
                          keyName: _data[index]['keyName'],
                          type: _data[index]['dataType']);
                    else
                      return Container();
                  })
              : Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )),
    );
  }

  Widget itemOption(BaseViewModel model,
          {String title = '',
          bool value = false,
          bool enable = true,
          String keyName,
          String type}) =>
      Container(
        padding: EdgeInsets.symmetric(
            vertical: Utils.resizeHeightUtil(context, 20),
            horizontal: Utils.resizeHeightUtil(context, 30)),
        decoration: BoxDecoration(
            color: enable ? white_color : txt_grey_color_v1.withOpacity(0.1),
            border: Border(
                bottom: BorderSide(
              color: txt_grey_color_v3.withOpacity(0.2),
              width: Utils.resizeHeightUtil(context, 1),
            ))),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: TKText(
                title,
                tkFont: TKFont.SFProDisplayRegular,
                style: TextStyle(
                    fontSize: Utils.resizeWidthUtil(context, 30), color: txt_grey_color_v6),
              ),
            ),
            if (type == '2')
              Container(
                width: Utils.resizeWidthUtil(context, 120),
                height: Utils.resizeHeightUtil(context, 60),
                child: CustomSwitchButton(
                  sizeInActive: Utils.resizeWidthUtil(context, 16),
                  sizeActive: Utils.resizeWidthUtil(context, 16),
                  activeColor: button_color,
                  enable: enable,
                  value: value,
                  textActive: Utils.getString(context, txt_turn_on_authorization),
                  textInActive: Utils.getString(context, txt_turn_off_authorization),
                  onChanged: (_value) async {
                    if (enable) {
                      if (keyName.contains('Login_IsFingerprint'))
                        await SecureStorage().saveCustomString(
                            SecureStorage.IS_USING_AUTHORIZATION, _value.toString());
                      if (keyName.contains('Login_IsSocialNetwork'))
                        await SecureStorage()
                            .saveCustomString(SecureStorage.SOCIAL_LOGIN, _value.toString());
                      updateChange(model, keyName, _value);
                    }
                  },
                ),
              ),
            if (type == '8' && type != '-1' && type != '')
              GestureDetector(
                onTap: () {
                  if (enable)
                    showModalBottomSheet(
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        context: context,
                        builder: (context) => Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              padding: EdgeInsets.symmetric(
                                  vertical: Utils.resizeWidthUtil(context, 30)),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(Utils.resizeWidthUtil(context, 30)),
                                      topRight:
                                          Radius.circular(Utils.resizeWidthUtil(context, 30)))),
                              child: StatefulBuilder(builder: (context, setModalState) {
                                return ListView.builder(
                                    itemCount: _languageList.length,
                                    itemBuilder: (context, index) {
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _languageSelected = _languageList[index];
                                          });
                                          Navigator.pop(context);
                                          updateChange(model, keyName, _languageSelected['ID']);
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: Utils.resizeWidthUtil(context, 30),
                                              vertical: Utils.resizeWidthUtil(context, 20)),
                                          decoration: BoxDecoration(
                                              border: Border(
                                                  bottom: BorderSide(
                                            color: txt_grey_color_v3.withOpacity(0.2),
                                            width: Utils.resizeHeightUtil(context, 1),
                                          ))),
                                          child: TKText(
                                            '${_languageList[index]['Name']['v']} (${_languageList[index]['Symbol']['v']})',
                                            tkFont: TKFont.SFProDisplayMedium,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: Utils.resizeWidthUtil(context, 28),
                                                color: txt_grey_color_v1),
                                          ),
                                        ),
                                      );
                                    });
                              }),
                            ));
                },
                child: Container(
                  height: Utils.resizeHeightUtil(context, 60),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      TKText(
                        _languageSelected['Name']['v'],
                        tkFont: TKFont.SFProDisplayRegular,
                        style: TextStyle(
                            fontSize: Utils.resizeWidthUtil(context, 28), color: txt_grey_color_v3),
                      ),
                      SizedBox(width: Utils.resizeWidthUtil(context, 10)),
                      Icon(Icons.arrow_drop_down, color: txt_grey_color_v3)
                    ],
                  ),
                ),
              )
          ],
        ),
      );
}
