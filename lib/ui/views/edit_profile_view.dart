import 'dart:io';
import 'dart:typed_data';
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
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:provider/provider.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class EditProfileView extends StatefulWidget {
  final BaseResponse _user;

  EditProfileView(this._user);

  @override
  State<StatefulWidget> createState() {
    return _EditProfileState();
  }
}

class _EditProfileState extends State<EditProfileView> {
  final dateTimeFormat = DateFormat("dd/MM/yyyy");

  DateFormat dateTimeDefaultFormat = DateFormat("MM/dd/yyyy HH:mm:ss aaa");

  TextEditingController _phoneEdtController = TextEditingController();

  TextEditingController _personalEmailEdtController = TextEditingController();

  TextEditingController _companyEmailEdtController = TextEditingController();

  TextEditingController _addressEdtController = TextEditingController();

  TextEditingController _birthdayEdtController = TextEditingController();

  TextEditingController _idCardNumEdtController = TextEditingController();

  TextEditingController _nameEdtController = TextEditingController();

  int _genderSelected = 0;

  int _civilStatusSelected = 0;

  dynamic avatar;

  dynamic cover;

  File _image;

  File _imageCover;

  String base64 = "";

  String base64Cover = "";

  bool _forceErrorName = false;

  bool _forceErrorPhone = false;

  bool _forceErrorPersonalEmail = false;

  bool _forceErrorCompanyEmail = false;

  bool _forceErrorAddress = false;

  bool _forceErrorBirthday = false;

  bool _forceErrorIdCard = false;

  bool _enableUpdateButton = false;

  List<dynamic> _genderList = [];

  List<dynamic> _civilStatusList = [];

  BaseResponse _data;

  bool isAllowEdit = false;

  @override
  void initState() {
    super.initState();
    checkAllowEdit();
    _nameEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['full_name']['v'].trim() ?? '',
        selection: _nameEdtController.selection);

    _phoneEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['phone']['v'].trim() ?? '',
        selection: _phoneEdtController.selection);

    _personalEmailEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['email']['v'].trim() ?? '',
        selection: _personalEmailEdtController.selection);

    _companyEmailEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['email_company']['v'].trim() ?? '',
        selection: _companyEmailEdtController.selection);

    _idCardNumEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['id_no']['v'].trim() ?? '',
        selection: _idCardNumEdtController.selection);

    _addressEdtController.value = TextEditingValue(
        text:
            widget._user.data['data'][0]['permanent_address']['v'].trim() ?? '',
        selection: _addressEdtController.selection);

    _birthdayEdtController.value = TextEditingValue(
        text: widget._user.data['data'][0]['dob']['v'] != ''
            ? dateTimeFormat.format(dateTimeDefaultFormat
                .parse(widget._user.data['data'][0]['dob']['v']))
            : dateTimeFormat.format(DateTime.now()),
        selection: _birthdayEdtController.selection);

    _data = widget._user;
    _phoneEdtController.addListener(_onTextFieldChange);
    _personalEmailEdtController.addListener(_onTextFieldChange);
    _companyEmailEdtController.addListener(_onTextFieldChange);
    _idCardNumEdtController.addListener(_onTextFieldChange);
    _addressEdtController.addListener(_onTextFieldChange);
    _birthdayEdtController.addListener(_onTextFieldChange);

    _data.data['data'][0]['avatar']['v'].toString() != ''
        ? avatar =
            '$avatarUrl${_data.data['data'][0]['avatar']['v'].toString()}'
        : avatar = null;
  }

  @override
  void dispose() {
    if (!mounted) {
      _phoneEdtController.dispose();
      _personalEmailEdtController.dispose();
      _companyEmailEdtController.dispose();
      _addressEdtController.dispose();
      _birthdayEdtController.dispose();
      _idCardNumEdtController.dispose();
    }
    super.dispose();
  }

  checkAllowEdit() async {
    var _user = await SecureStorage().userProfile;
    setState(() {
      isAllowEdit = _user.data['data'][0]['UserAccount_IsChangeInfo']['v'] == 'True' ? true : false;
    });
  }

  _onTextFieldChange() {
    if (_phoneEdtController.text !=
            _data.data['data'][0]['phone']['r'].trim() ||
        _addressEdtController.text !=
            _data.data['data'][0]['permanent_address']['v'].trim() ||
        _companyEmailEdtController.text !=
            _data.data['data'][0]['email_company']['r'].trim() ||
        _personalEmailEdtController.text !=
            _data.data['data'][0]['email']['r'].trim() ||
        _birthdayEdtController.text !=
            (_data.data['data'][0]['dob']['r'].trim() != ''
                ? dateTimeFormat.format(dateTimeDefaultFormat
                    .parse(_data.data['data'][0]['dob']['r'].trim()))
                : '') ||
        _idCardNumEdtController.text !=
            _data.data['data'][0]['id_no']['r'].trim() ||
        _genderSelected != num.parse(_data.data['data'][0]['sex']['v']) ||
        base64 != "" ||
        base64Cover != "") {
      _enableUpdateButton = true;
    } else
      _enableUpdateButton = false;
    setState(() {});
  }

  dynamic checkValidValue({bool back = false}) {
    if (!back) if (_phoneEdtController.text.isEmpty ||
        _phoneEdtController.text.length < 10 ||
        _idCardNumEdtController.text.isEmpty ||
        _companyEmailEdtController.text.isEmpty ||
        _personalEmailEdtController.text.isEmpty ||
        _addressEdtController.text.isEmpty) {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_info_incorrect),
          onPress: () => Navigator.pop(context));
      return null;
    }

    var data = {};

    if (base64 != "")
      data = {
        ...data,
        ...{"avatar": "data:image/jpeg;base64,$base64"}
      };

    if (base64Cover != "")
      data = {
        ...data,
        ...{"cover": "data:image/jpeg;base64,$base64Cover"}
      };

    if (_phoneEdtController.text != _data.data['data'][0]['phone']['r'].trim())
      data = {
        ...data,
        ...{"phone": _phoneEdtController.text}
      };

    if (_addressEdtController.text !=
        _data.data['data'][0]['permanent_address']['v'].trim())
      data = {
        ...data,
        ...{"permanent_address": _addressEdtController.text}
      };

    if (_companyEmailEdtController.text !=
        _data.data['data'][0]['email_company']['r'].trim())
      data = {
        ...data,
        ...{"email_company": _companyEmailEdtController.text}
      };

    if (_personalEmailEdtController.text !=
        _data.data['data'][0]['email']['r'].trim())
      data = {
        ...data,
        ...{"email": _personalEmailEdtController.text}
      };

    if (_birthdayEdtController.text !=
        (_data.data['data'][0]['dob']['r'].trim() != ''
            ? dateTimeFormat.format(dateTimeDefaultFormat
                .parse(_data.data['data'][0]['dob']['r'].trim()))
            : ''))
      data = {
        ...data,
        ...{"dob": _birthdayEdtController.text}
      };

    if (_idCardNumEdtController.text !=
        _data.data['data'][0]['id_no']['r'].trim())
      data = {
        ...data,
        ...{"id_no": _idCardNumEdtController.text}
      };

    if (_genderSelected != num.parse(_data.data['data'][0]['sex']['v']))
      data = {
        ...data,
        ...{"sex": _genderList[_genderSelected]['id']}
      };

    var checkCivilStatus = _data.data['data'][0]['civil_status']['v'] != ""
        ? num.parse(_data.data['data'][0]['civil_status']['v'])
        : num.parse(_civilStatusList[_civilStatusSelected]['id']);

    if (num.parse(_civilStatusList[_civilStatusSelected]['id']) !=
        checkCivilStatus)
      data = {
        ...data,
        ...{"civil_status": _civilStatusList[_civilStatusSelected]['id']}
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
      var genderSelected = _data.data['data'][0]['sex']['v'];
      setState(() {
        _genderList = genderList;
        List<dynamic> genderFilter =
            genderList.where((value) => value['id'] == genderSelected).toList();
        _genderSelected = _genderList.indexOf(genderFilter[0]);
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getCivilStatus(BaseViewModel model) async {
    List<dynamic> civilStatusList = [];
    var response = await model.callApis({}, getCivilStatusUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var status in response.data['data']) {
        civilStatusList.add({
          'id': status['ID'],
          'name': status['TinhTrangHonNhan']['v'],
        });
      }
      var civilStatusSelected = _data.data['data'][0]['civil_status']['v'] != ""
          ? _data.data['data'][0]['civil_status']['v']
          : -1;

      setState(() {
        _civilStatusList = civilStatusList;
        if (civilStatusSelected != -1) {
          List<dynamic> civilStatusFilter = _civilStatusList
              .where((value) => value['id'] == civilStatusSelected)
              .toList();
          _civilStatusSelected = _civilStatusList.indexOf(civilStatusFilter[0]);
        }
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void updateProfile(BaseViewModel model) async {
    var data = checkValidValue();
    if (data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_nhanvien_employee");
      var updateProfileResponse = await model.callApis({
        "tbname": encryptData,
        "dataid": _data.data['data'][0]['ID'],
        ...data
      }, updateDataUrl, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (updateProfileResponse.status.code == 200) {
        var profileResponse = await model.callApis(
            {}, userProfileUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.of(context).pop();
        if (profileResponse.status.code == 200) {
          await SecureStorage().saveProfileCustomer(profileResponse);
          context.read<BaseResponse>().addData(profileResponse.data);
          _data = profileResponse;
          base64 = "";
          base64Cover = "";
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_update_success),
              onPress: () => Navigator.pop(context));
        } else {
          Navigator.of(context).pop();
          showMessageDialogIOS(context,
              description: Utils.getString(context, txt_re_get_data_failed));
        }
      } else {
        Navigator.of(context).pop();
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_failed));
      }
    }
  }

  Future getImage(bool isAvatar, ImageSource imageSource) async {
    var imagePicker =
        await ImagePicker().getImage(source: imageSource, imageQuality: 50);
    File image = File(imagePicker.path);
    Uint8List bytes = image.readAsBytesSync();
    setState(() {
      if (isAvatar) {
        _image = image;
        base64 = Utils.convertBase64(bytes);
        _enableUpdateButton = true;
      } else {
        _imageCover = image;
        base64Cover = Utils.convertBase64(bytes);
        _enableUpdateButton = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      onModelReady: (model) {
        Future.delayed(new Duration(milliseconds: 0), () {
          getGender(model);
          getCivilStatus(model);
        });
      },
      model: BaseViewModel(),
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () {
          dynamic check = checkValidValue(back: true);
          if (check.length > 0) {
            showMessageDialog(context,
                description:
                    Utils.getString(context, txt_warning_update_profile),
                onPress: () => Navigator.popUntil(
                    context, ModalRoute.withName(Routers.profile)));
          } else {
            Navigator.pop(context);
          }
        }, () {
          Utils.closeKeyboard(context);
        }, Utils.getString(context, txt_title_profile), null),
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              Utils.closeKeyboard(context);
            },
            child: Container(
              padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
              child: Column(children: <Widget>[
                _avatarCover(),
                _bodyEditProfile(),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 50),
                ),
                TKButton(Utils.getString(context, txt_save),
                    enable: isAllowEdit && _enableUpdateButton,
                    width: double.infinity, onPress: () {
                  FocusScope.of(context).unfocus();
                  updateProfile(model);
                })
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarCover() {
    var avatarFileName = _data.data['data'][0]['avatar']['v'].toString() != ''
        ? '${_data.data['data'][0]['avatar']['v'].toString()}'
        : avatarDefaultUrl.split('/').last;
    return Container(
      child: Stack(
        children: <Widget>[
          Container(
              width: Utils.resizeWidthUtil(context, 750),
              height: Utils.resizeHeightUtil(context, 375),
              child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(Utils.resizeWidthUtil(context, 10)),
                  child: _imageCover != null
                      ? Image.file(_imageCover, fit: BoxFit.cover)
                      : Image.network('$avatarUrl${context.read<BaseResponse>().data['data'][0]['cover']['v'].toString()}', fit: BoxFit.cover,)
//                  FadeInImage.assetNetwork(
//                          fit: BoxFit.cover,
//                          placeholder: ic_cover_image,
//                          image:
//                              '$avatarUrl${context.read<BaseResponse>().data['data'][0]['cover']['v'].toString()}')
              )),
          Container(
              margin:
                  EdgeInsets.only(top: Utils.resizeHeightUtil(context, 250)),
              child: Center(
                child: Stack(
                  children: <Widget>[
                    Container(
                      padding:
                          EdgeInsets.all(Utils.resizeWidthUtil(context, 10)),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.white,
                              width: Utils.resizeWidthUtil(context, 1)),
                          shape: BoxShape.circle,
                          color: Colors.white),
                      width: Utils.resizeHeightUtil(context, 250),
                      height: Utils.resizeHeightUtil(context, 250),
                      child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: _image != null
                              ? FileImage(_image)
                              : NetworkToFileImage(
                                  url: avatar,
                                  file: Utils().fileFromDocsDir(avatarFileName),
                                )),
                    ),
                    _cameraIcon(right: 20, bottom: 20)
                  ],
                ),
              )),
          _cameraIcon(right: 20, bottom: 140, isAvatar: false)
        ],
      ),
    );
  }

  Widget _cameraIcon({double bottom, double right, bool isAvatar = true}) {
    return Positioned(
      right: Utils.resizeWidthUtil(context, right),
      bottom: Utils.resizeHeightUtil(context, bottom),
      child: GestureDetector(
        onTap: () {
          showCupertinoModalPopup(
              context: context,
              builder: (context) => _cupertinoActionSheet(isAvatar));
        },
        child: Container(
          padding: EdgeInsets.all(Utils.resizeWidthUtil(context, 8)),
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
    );
  }

  Widget _bodyEditProfile() {
    return Container(
      child: Column(
        children: <Widget>[
          _buildContentText(Utils.getString(context, txt_full_name),
              controller: _nameEdtController, isEnable: false),
          _buildContentText(Utils.getString(context, txt_birthday),
              controller: _birthdayEdtController,
              icon: ic_calendar,
              isEnable: false, onPress: () {
            showDatePicker(
                    context: context,
                    initialDate: DateFormat('yyyy-MM-dd').parse(
                        DateFormat('dd/MM/yyyy')
                            .parse(_birthdayEdtController.text)
                            .toString()),
                    firstDate: DateTime(1950),
                    lastDate: DateTime(2100))
                .then((value) {
              if (value == null) return;
              setState(() {
                _birthdayEdtController.text = dateTimeFormat.format(value);
                _enableUpdateButton = true;
              });
            });
          }),
          _buildContentSelectBoxGender(),
          _buildContentSelectBoxCivilStatus(),
          _buildContentText(Utils.getString(context, txt_id_card),
              isEnable: isAllowEdit,
              controller: _idCardNumEdtController,
              textInputType: TextInputType.number),
          _buildContentText(Utils.getString(context, txt_phone),
              isEnable: isAllowEdit,
              controller: _phoneEdtController,
              textInputType: TextInputType.phone),
          _buildContentText(Utils.getString(context, txt_personal_email),
              isEnable: isAllowEdit,
              controller: _personalEmailEdtController,
              textInputType: TextInputType.emailAddress),
          _buildContentText(Utils.getString(context, txt_company_email),
              isEnable: isAllowEdit,
              controller: _companyEmailEdtController,
              textInputType: TextInputType.emailAddress),
          _buildContentText(Utils.getString(context, txt_address),
              isEnable: isAllowEdit,
              isExpand: true, controller: _addressEdtController),
        ],
      ),
    );
  }

  Widget _buildContentText(String title,
      {bool isEnable = true,
      bool isExpand = false,
      TextEditingController controller,
      Function onPress,
      String icon,
      TextInputType textInputType = TextInputType.text,
      String hintText = ''}) {
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
            boxTitle(context, title),
            TextFieldCustom(
                controller: controller,
                enable: isEnable,
                imgLeadIcon: icon,
                expandMultiLine: isExpand,
                forceError: title == Utils.getString(context, txt_full_name)
                    ? _forceErrorName
                    : title == Utils.getString(context, txt_birthday)
                        ? _forceErrorBirthday
                        : title == Utils.getString(context, txt_phone)
                            ? _forceErrorPhone
                            : title ==
                                    Utils.getString(context, txt_personal_email)
                                ? _forceErrorPersonalEmail
                                : title ==
                                        Utils.getString(
                                            context, txt_company_email)
                                    ? _forceErrorCompanyEmail
                                    : title ==
                                            Utils.getString(
                                                context, txt_id_card)
                                        ? _forceErrorIdCard
                                        : _forceErrorAddress,
                onChange: (changeValue) {
                  setState(() {
                    title == Utils.getString(context, txt_full_name)
                        ? _forceErrorName = controller.text.trimRight().isEmpty
                        : title == Utils.getString(context, txt_birthday)
                            ? _forceErrorBirthday = controller.text
                                .trimRight()
                                .isEmpty
                            : title == Utils.getString(context, txt_phone)
                                ? _forceErrorPhone = controller.text
                                    .trimRight()
                                    .isEmpty
                                : title ==
                                        Utils.getString(
                                            context, txt_personal_email)
                                    ? _forceErrorPersonalEmail = controller.text
                                        .trimRight()
                                        .isEmpty
                                    : title ==
                                            Utils.getString(context,
                                                txt_company_email)
                                        ? _forceErrorCompanyEmail =
                                            controller.text.trimRight().isEmpty
                                        : title ==
                                                Utils.getString(context,
                                                    txt_id_card)
                                            ? _forceErrorIdCard = controller
                                                .text
                                                .trimRight()
                                                .isEmpty
                                            : _forceErrorAddress = controller
                                                .text
                                                .trimRight()
                                                .isEmpty;
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
        boxTitle(context, Utils.getString(context, txt_gender)),
        SelectBoxCustom(
            valueKey: 'name',
            title: _genderList.length > 0
                ? _genderList[_genderSelected]['name']
                : '',
            data: _genderList,
            selectedItem: _genderSelected,
            callBack: (itemSelected) => setState(() {
                  if (itemSelected != null) {
                    _genderSelected = itemSelected;
                    if (_genderSelected !=
                        num.parse(_data.data['data'][0]['sex']['v']))
                      _enableUpdateButton = true;
                  }
                })),
      ],
    );
  }

  Widget _buildContentSelectBoxCivilStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, Utils.getString(context, txt_marriage_status)),
        SelectBoxCustom(
            valueKey: 'name',
            title: _civilStatusList.length > 0 && _civilStatusSelected >= 0
                ? _civilStatusList[_civilStatusSelected]['name']
                : '',
            data: _civilStatusList,
            selectedItem: _civilStatusSelected,
            callBack: (itemSelected) => setState(() {
                  if (itemSelected != null) {
                    _civilStatusSelected = itemSelected;
                    if (num.parse(
                            _civilStatusList[_civilStatusSelected]['id']) !=
                        (_data.data['data'][0]['civil_status']['v'] != ""
                            ? num.parse(
                                _data.data['data'][0]['civil_status']['v'])
                            : -1)) _enableUpdateButton = true;
                  }
                })),
      ],
    );
  }

  Widget _cupertinoActionSheet(bool isAvatar) {
    return CupertinoActionSheet(
      title: TKText(
        Utils.getString(context, txt_choose_image),
        textAlign: TextAlign.center,
        tkFont: TKFont.SFProDisplaySemiBold,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 32), color: blue_light),
      ),
      message: TKText(
        Utils.getString(context, txt_choose_any_action),
        textAlign: TextAlign.center,
        tkFont: TKFont.SFProDisplayMedium,
        style: TextStyle(
            fontSize: Utils.resizeWidthUtil(context, 24), color: blue_light),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: TKText(Utils.getString(context, txt_choose_image_camera),
              tkFont: TKFont.SFProDisplayRegular,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  color: blue_light)),
          isDefaultAction: true,
          onPressed: () {
            Utils.closeKeyboard(context);
            Navigator.pop(context);
            getImage(isAvatar, ImageSource.camera);
          },
        ),
        CupertinoActionSheetAction(
          child: TKText(Utils.getString(context, txt_choose_image_gallery),
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 30),
                  color: txt_fail_color)),
          isDestructiveAction: true,
          onPressed: () {
            Utils.closeKeyboard(context);
            Navigator.pop(context);
            getImage(isAvatar, ImageSource.gallery);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: TKText(Utils.getString(context, txt_cancel),
            tkFont: TKFont.SFProDisplayRegular,
            style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 30),
                color: blue_light)),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
