import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:url_launcher/url_launcher.dart';

const API_BASE_URL_KEY = "apiBaseUrlKey";

class ChooseCompanyView extends StatefulWidget {
  @override
  _ChooseCompanyViewState createState() => _ChooseCompanyViewState();
}

class _ChooseCompanyViewState extends State<ChooseCompanyView> {
  List<dynamic> _companies = [];
  int _companySelected = 0;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  void _getData() async {
    var _user = await SecureStorage().getCustomString(SecureStorage.USERNAME);
    if (_user != null) await SecureStorage().removeCustomString(SecureStorage.USERNAME);
    var response = await BaseViewModel()
        .callApis({}, listCompanyUrl, method_post, shouldSkipAuth: true, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      setState(() {
        _companies = response.data['data'];
      });
    } else
      showMessageDialogIOS(context, description: Utils.getString(context, txt_get_data_failed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomCenter,
                  colors: <Color>[gradient_end_color, gradient_start_color])),
        ),
        SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Image.asset(
                  logo_hrms,
                  height: Utils.resizeHeightUtil(context, 101.06),
                  width: Utils.resizeWidthUtil(context, 182),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: SelectBoxCustom(
                          valueKey: 'name_company',
                          title: _companies.length > 0
                              ? _companies[_companySelected]['name_company']['v']
                              : Utils.getString(context, txt_waiting),
                          data: _companies,
                          selectedItem: _companySelected,
                          callBack: (itemSelected) => setState(() {
                                if (itemSelected != null) {
                                  _companySelected = itemSelected;
                                }
                              })),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 100),
                      child: TKButton(
                        'Start',
                        width: 200,
                        onPress: () async {
                          await SecureStorage().saveCompanyInfo(json.encode(_companies[_companySelected]));
                          if (_companies[_companySelected]['isWebview']['v'] == 'True') {
                            await SecureStorage().saveIsWebView();
                            Navigator.pushReplacementNamed(context, Routers.webView);
                          }
                          else
                            Navigator.pushReplacementNamed(context, Routers.login);
                          await SecureStorage().saveIsFirstTime();
                        },
                        borderColor: Colors.white,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        Positioned(
            bottom: Utils.resizeHeightUtil(context, 20),
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TKText(
                  'Hotline:  ',
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(color: white_color),
                ),
                GestureDetector(
                  onTap: () async {
                    if (await canLaunch('tel:${_companies[_companySelected]['phone_company']['v']}')) {
                      await launch('tel:${_companies[_companySelected]['phone_company']['v']}');
                    } else {
                      throw 'Could not launch ${_companies[_companySelected]['phone_company']['v']}';
                    }
                  },
                  child: TKText(
                    _companies.length > 0 ? _companies[_companySelected]['phone_company']['v'].toString() : '',
                    tkFont: TKFont.SFProDisplayMedium,
                    style: TextStyle(color: white_color, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ))
      ],
    ));
  }
}
