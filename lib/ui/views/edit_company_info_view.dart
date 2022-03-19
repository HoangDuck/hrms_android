import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/request_data_view_detail.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class EditCompanyInfoView extends StatefulWidget {
  @override
  _EditCompanyInfoViewState createState() => _EditCompanyInfoViewState();
}

class _EditCompanyInfoViewState extends State<EditCompanyInfoView> {
  bool _enableUpdateButton = false;
  dynamic _genRow;
  dynamic data;

  dynamic _registratorSelected;
  List<dynamic> registrator = [];

  final dateTimeFormat = DateFormat("dd/MM/yyyy");
  DateFormat dateTimeDefaultFormat = DateFormat("MM/dd/yyyy HH:mm:ss aaa");

  TextEditingController _companyIdEdtController = TextEditingController();
  TextEditingController _nameCompanyEdtController = TextEditingController();
  TextEditingController _shortNameEdtController = TextEditingController();
  TextEditingController _enNameEdtController = TextEditingController();
  TextEditingController _fullNameEdtController = TextEditingController();
  TextEditingController _licenseNoEdtController = TextEditingController();
  TextEditingController _licenseDateEdtController = TextEditingController();
  TextEditingController _taxNoEdtController = TextEditingController();
  TextEditingController _licenseIssueEdtController = TextEditingController();
  TextEditingController _addressEdtController = TextEditingController();
  TextEditingController _urlCompanyController = TextEditingController();
  TextEditingController _phoneCompanyController = TextEditingController();
  TextEditingController _emailCompanyController = TextEditingController();

  bool _forceErrorComID = false;
  bool _forceErrorRegister = false;
  bool _forceErrorName = false;
  bool _forceErrorShortName = false;
  bool _forceErrorEnName = false;
  bool _forceErrorFullName = false;
  bool _forceErrorLiNo = false;
  bool _forceErrorTaxNo = false;
  bool _forceErrorLiDate = false;
  bool _forceErrorLiIssue = false;
  bool _forceErrorAddress = false;
  bool _forceErrorUrl = false;
  bool _forceErrorPhone = false;
  bool _forceErrorEmail = false;

  File _image;
  String _base64 = "";

  String _filter = '';
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (!mounted) {
      _companyIdEdtController.dispose();
      _nameCompanyEdtController.dispose();
      _shortNameEdtController.dispose();
      _enNameEdtController.dispose();
      _fullNameEdtController.dispose();
      _licenseNoEdtController.dispose();
      _licenseDateEdtController.dispose();
      _taxNoEdtController.dispose();
      _licenseIssueEdtController.dispose();
      _addressEdtController.dispose();
      _urlCompanyController.dispose();
      _phoneCompanyController.dispose();
      _emailCompanyController.dispose();
    }
    super.dispose();
  }

  _onTextFieldChange() {
    if (_nameCompanyEdtController.text != data['name_company']['v'].trim() ||
        _shortNameEdtController.text != data['short_name']['v'].trim() ||
        _enNameEdtController.text != data['en_name']['v'].trim() ||
        _fullNameEdtController.text != data['full_name']['v'].trim() ||
        _addressEdtController.text != data['address']['v'].trim() ||
        _urlCompanyController.text != data['url_company']['v'].trim() ||
        _phoneCompanyController.text != data['phone_company']['v'].trim() ||
        _emailCompanyController.text != data['email_company']['v'].trim() ||
        _companyIdEdtController.text != data['company_id']['v'].trim() ||
        _registratorSelected.toString() != data['registrator']['r'].trim() ||
        _licenseNoEdtController.text != data['license_no']['v'].trim() ||
        _licenseDateEdtController.text !=
            (data['license_date']['v'].trim() != '' ? DateFormat('dd/MM/yyyy').format(
                defaultFormat.parse(data['license_date']['v'].trim())) : '') ||
        _taxNoEdtController.text != data['tax_no']['v'].trim() ||
        _licenseIssueEdtController.text != data['license_issue']['v'].trim()) {
      if (!_forceErrorComID &&
          !_forceErrorRegister &&
          !_forceErrorName &&
          !_forceErrorShortName &&
          !_forceErrorEnName &&
          !_forceErrorFullName &&
          !_forceErrorLiNo &&
          !_forceErrorTaxNo &&
          !_forceErrorLiDate &&
          !_forceErrorLiIssue &&
          !_forceErrorAddress &&
          !_forceErrorUrl &&
          !_forceErrorPhone &&
          !_forceErrorEmail)
        _enableUpdateButton = true;
      else
        _enableUpdateButton = false;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  void getEmployee(BaseViewModel model, int currentIndex,
      {bool isLoadMore = false, String searchText = '', SelectBoxCustomUtilState state}) async {
    List<dynamic> _registrator = [];
    var response = await model.callApis({
      "current_index": currentIndex,
      "not_include": -1,
      "search_text": searchText,
      "filter": _filter
    }, employeeOwnerUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        _registrator.add({
          'id': list['ID'],
          'name': list['full_name']['v']
        });
      }
      setState(() {
       registrator.addAll(_registrator);
       _registratorSelected = registrator
           .where((item) =>
       item['id'] == data['registrator']['v'].trim())
           .toList()[0];
      });
      if(state != null) {
        state.updateDataList(registrator);
      }
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_organization_company"},
        getGenRowDefineUrl,
        method_post,
        isNeedAuthenticated: true,
        shouldSkipAuth: false);
    if (response.status.code == 200) {
      //genRow type update
      _genRow = Utils.getListGenRow(response.data['data'], 'update');
      setState(() {});
    } else {
      showMessageDialog(context,
          description: Utils.getString(context, txt_get_data_failed));
    }
  }

  initData(dynamic data) {
    _companyIdEdtController.text = data['company_id']['v'].trim() ?? '';
    _nameCompanyEdtController.text = data['name_company']['r'].trim() ?? '';
    _shortNameEdtController.text = data['short_name']['v'].trim() ?? '';
    _enNameEdtController.text = data['en_name']['v'].trim() ?? '';
    _fullNameEdtController.text = data['full_name']['v'].trim() ?? '';
    _licenseNoEdtController.text = data['license_no']['v'].trim() ?? '';
    _licenseDateEdtController.text = data['license_date']['r'].trim() ?? '';
    _taxNoEdtController.text = data['tax_no']['v'].trim() ?? '';
    _licenseIssueEdtController.text = data['license_issue']['v'].trim() ?? '';
    _addressEdtController.text = data['address']['v'].trim() ?? '';
    _urlCompanyController.text = data['url_company']['v'].trim() ?? '';
    _phoneCompanyController.text = data['phone_company']['v'].trim() ?? '';
    _emailCompanyController.text = data['email_company']['v'].trim() ?? '';
    _nameCompanyEdtController.addListener(_onTextFieldChange);
    _shortNameEdtController.addListener(_onTextFieldChange);
    _enNameEdtController.addListener(_onTextFieldChange);
    _fullNameEdtController.addListener(_onTextFieldChange);
    _addressEdtController.addListener(_onTextFieldChange);
    _urlCompanyController.addListener(_onTextFieldChange);
    _phoneCompanyController.addListener(_onTextFieldChange);
    _emailCompanyController.addListener(_onTextFieldChange);
    _companyIdEdtController.addListener(_onTextFieldChange);
    _licenseNoEdtController.addListener(_onTextFieldChange);
    _licenseDateEdtController.addListener(_onTextFieldChange);
    _taxNoEdtController.addListener(_onTextFieldChange);
    _licenseIssueEdtController.addListener(_onTextFieldChange);
  }

  void getInfo(BaseViewModel model) async {
    var response = await model.callApis({}, companyInfoUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      setState(() {
        data = response.data['data'][0];
        initData(data);
        getEmployee(model, currentIndex);
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  dynamic checkValidValue({bool back = false}) {
    if (_nameCompanyEdtController.text.isEmpty ||
        _shortNameEdtController.text.isEmpty ||
        _enNameEdtController.text.isEmpty ||
        _fullNameEdtController.text.isEmpty ||
        _addressEdtController.text.isEmpty ||
        _urlCompanyController.text.isEmpty ||
        _phoneCompanyController.text.isEmpty ||
        _emailCompanyController.text.isEmpty  ||
        _licenseNoEdtController.text.isEmpty ||
        _taxNoEdtController.text.isEmpty ||
        _licenseIssueEdtController.text.isEmpty) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_info_incorrect),
          onPress: () => Navigator.pop(context));
      return;
    }
    var dataChange = {};

    if (_base64 != "")
      dataChange = {
        ...dataChange,
        ...{"logo": "data:image/jpeg;base64,$_base64"}
      };

    if (_nameCompanyEdtController.text != data['name_company']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"name_company": _nameCompanyEdtController.text}
      };
    if (_shortNameEdtController.text != data['short_name']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"short_name": _shortNameEdtController.text}
      };
    if (_enNameEdtController.text != data['en_name']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"en_name": _enNameEdtController.text}
      };
    if (_fullNameEdtController.text != data['full_name']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"full_name": _fullNameEdtController.text}
      };
    if (_addressEdtController.text != data['address']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"address": _addressEdtController.text}
      };
    if (_urlCompanyController.text != data['url_company']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"url_company": _urlCompanyController.text}
      };
    if (_phoneCompanyController.text != data['phone_company']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"phone_company": _phoneCompanyController.text}
      };
    if (_emailCompanyController.text != data['email_company']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"email_company": _emailCompanyController.text}
      };
    if (_registratorSelected != null)
      dataChange = {
        ...dataChange,
        ...{"registrator": _registratorSelected["id"]}
      };
    if (_licenseNoEdtController.text != data['license_no']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"license_no": _licenseNoEdtController.text}
      };
    if (_taxNoEdtController.text != data['tax_no']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"tax_no": _taxNoEdtController.text}
      };
    if (_licenseIssueEdtController.text != data['license_issue']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"license_issue": _licenseIssueEdtController.text}
      };
    if (_licenseDateEdtController.text != data['license_date']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"license_date": _licenseDateEdtController.text}
      };
    return dataChange;
  }

  void updateInfo(BaseViewModel model) async {
    var dataChange = checkValidValue();
    if (dataChange.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_organization_company");
      var response = await model.callApis(
          {"tbname": encryptData, "dataid": data['ID'], ...dataChange},
          updateDataUrl,
          method_post,
          isNeedAuthenticated: true,
          shouldSkipAuth: false);
      Navigator.pop(context);
      if (response.status.code == 200) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success));
      } else
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success));
    }
  }

  Future getImage() async {
    var imagePicker = await ImagePicker()
        .getImage(source: ImageSource.gallery, imageQuality: 50);
    File image = File(imagePicker.path);
    Uint8List bytes = image.readAsBytesSync();
    setState(() {
      _image = image;
      _base64 = Utils.convertBase64(bytes);
      _enableUpdateButton = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        Future.delayed(Duration(milliseconds: 300), () {
          getInfo(model);
        });
        getGenRowDefine(model);
      },
      model: BaseViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () {
          Navigator.pop(context);
        }, () {
          Utils.closeKeyboard(context);
        }, Utils.getString(context, txt_title_profile), null),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              Utils.closeKeyboard(context);
            },
            child: data != null && _genRow != null
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
        boxTitle(context, _genRow.length > 0 ? '' : _genRow['logo']['name']),
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  _image != null
                      ? Image.file(_image)
                      : FadeInImage(
                          imageErrorBuilder: (BuildContext context,
                              Object exception, StackTrace stackTrace) {
                            return Image.network(
                                '$avatarUrlAPIs${data['logo']['v']}');
                          },
                          placeholder: AssetImage(avatar_default),
                          image: NetworkImage('$avatarUrl${data['logo']['v']}'),
                          fit: BoxFit.cover,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: getImage,
                      child: Container(
                        padding:
                            EdgeInsets.all(Utils.resizeWidthUtil(context, 8)),
                        width: Utils.resizeWidthUtil(context, 50),
                        height: Utils.resizeHeightUtil(context, 50),
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: Utils.resizeWidthUtil(context, 2),
                                color: Colors.white),
                            shape: BoxShape.circle,
                            color: bg_camera_icon),
                        child: Image.asset(ic_camera,
                            width: Utils.resizeWidthUtil(context, 15),
                            height: Utils.resizeHeightUtil(context, 15)),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        _buildContentText(
            keyName: 'company_id',
            controller: _companyIdEdtController,
            forceError: _forceErrorComID,
            isEnable: _genRow['company_id']['allowEdit']),
        _buildContentSelectBoxRegistrator(model),
        SizedBox(height: Utils.resizeHeightUtil(context, 10)),
        _buildContentText(
            keyName: 'name_company',
            controller: _nameCompanyEdtController,
            forceError: _forceErrorName,
            allowNull: _genRow['name_company']['allowNull'],
            isEnable: _genRow['name_company']['allowEdit']),
        _buildContentText(
            keyName: 'short_name',
            controller: _shortNameEdtController,
            forceError: _forceErrorShortName,
            allowNull: _genRow['short_name']['allowNull'],
            isEnable: _genRow['short_name']['allowEdit']),
        _buildContentText(
            keyName: 'en_name',
            controller: _enNameEdtController,
            forceError: _forceErrorEnName,
            isEnable: _genRow['en_name']['allowEdit']),
        _buildContentText(
            keyName: 'full_name',
            controller: _fullNameEdtController,
            forceError: _forceErrorFullName,
            isExpand: true,
            isEnable: _genRow['full_name']['allowEdit']),
        _buildContentText(
            keyName: 'license_no',
            controller: _licenseNoEdtController,
            forceError: _forceErrorLiNo,
            isEnable: _genRow['license_no']['allowEdit']),
        _buildContentText(
            keyName: 'license_date',
            controller: _licenseDateEdtController,
            icon: ic_calendar,
            isEnable: false,
            onPress: _genRow['license_date']['allowEdit']
                ? () {
                showDatePicker(
                    context: context,
                    initialDate: DateFormat('yyyy-MM-dd').parse(
                        _licenseDateEdtController.text != ''
                            ? DateFormat('dd/MM/yyyy')
                            .parse(
                            _licenseDateEdtController.text)
                            .toString()
                            : DateTime.now().toString()),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100))
                    .then((value) {
                  if (value == null) return;
                  setState(() {
                    _licenseDateEdtController.text =
                        dateTimeFormat.format(value);
                    _onTextFieldChange();
                  });
                });
            }
                : () {}),
        _buildContentText(
            keyName: 'tax_no',
            controller: _taxNoEdtController,
            forceError: _forceErrorTaxNo,
            isEnable: _genRow['tax_no']['allowEdit']),
        _buildContentText(
            keyName: 'license_issue',
            controller: _licenseIssueEdtController,
            forceError: _forceErrorLiIssue,
            isEnable: _genRow['license_issue']['allowEdit']),
        _buildContentText(
            keyName: 'address',
            controller: _addressEdtController,
            forceError: _forceErrorAddress,
            isExpand: true,
            isEnable: _genRow['address']['allowEdit']),
        _buildContentText(
            keyName: 'url_company',
            controller: _urlCompanyController,
            forceError: _forceErrorUrl,
            isEnable: _genRow['url_company']['allowEdit']),
        _buildContentText(
            keyName: 'phone_company',
            controller: _phoneCompanyController,
            forceError: _forceErrorPhone,
            isEnable: _genRow['phone_company']['allowEdit'],
            textInputType: TextInputType.number),
        _buildContentText(
            keyName: 'email_company',
            controller: _emailCompanyController,
            forceError: _forceErrorEmail,
            isEnable: _genRow['email_company']['allowEdit']),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 50),
        ),
        TKButton(Utils.getString(context, txt_save),
            enable: _enableUpdateButton, width: double.infinity, onPress: () {
          FocusScope.of(context).unfocus();
          updateInfo(model);
        }),
        SizedBox(
          height: Utils.resizeHeightUtil(context, 30),
        ),
      ]);

  Widget _buildContentText(
      {String keyName = '',
      bool isEnable = true,
      bool isExpand = false,
      TextEditingController controller,
      Function onPress,
      bool forceError = false,
      bool allowNull = true,
      TextInputType textInputType = TextInputType.text,
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
            boxTitle(context, _genRow[keyName]['name']),
            TextFieldCustom(
                controller: controller,
                enable: isEnable,
                imgLeadIcon: icon,
                textInputType: textInputType,
                expandMultiLine: isExpand,
                forceError: forceError,
                onChange: (changeValue) {
                  setState(() {
                    if (!allowNull)
                      switch (keyName) {
                        case 'company_id':
                          _forceErrorComID =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'name_company':
                          _forceErrorName = controller.text.trimRight().isEmpty;
                          break;
                        case 'short_name':
                          _forceErrorShortName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'email_company':
                          _forceErrorEmail =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'url_company':
                          _forceErrorUrl = controller.text.trimRight().isEmpty;
                          break;
                        case 'en_name':
                          _forceErrorEnName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'full_name':
                          _forceErrorFullName =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'registrator':
                          _forceErrorRegister =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'phone_company':
                          _forceErrorPhone =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'address':
                          _forceErrorAddress =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'license_no':
                          _forceErrorLiNo = controller.text.trimRight().isEmpty;
                          break;
                        case 'tax_no':
                          _forceErrorTaxNo =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'license_issue':
                          _forceErrorLiIssue =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'license_date':
                          _forceErrorLiDate =
                              controller.text.trimRight().isEmpty;
                      }
                  });
                }),
          ],
        ),
      ),
    );
  }
  Widget _buildContentSelectBoxRegistrator(BaseViewModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, _genRow['registrator']['name']),
        SelectBoxCustomUtil(
            enableSearch: false,
            title: _registratorSelected == null
                ? ''
                : _registratorSelected['name'],
            data: registrator,
            selectedItem: 0,
            enable: _genRow['registrator']['allowEdit'],
            clearCallback: () {},
            initCallback: (state) {},
            loadMoreCallback: (state) {
              currentIndex += 10;
              getEmployee(model, currentIndex, state: state);
            },
            searchCallback: (value, state) {},
            callBack: (itemSelected) {
              setState(() {
                if (itemSelected != null)
                  _registratorSelected = itemSelected;
                _onTextFieldChange();
              });
            }),
      ],
    );
  }
}
