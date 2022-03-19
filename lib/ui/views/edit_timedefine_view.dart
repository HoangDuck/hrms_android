import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
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

class EditTimeDefineView extends StatefulWidget {
  final dynamic data;

  EditTimeDefineView(this.data);

  @override
  _EditTimeDefineViewState createState() => _EditTimeDefineViewState();
}

class _EditTimeDefineViewState extends State<EditTimeDefineView>
    with TickerProviderStateMixin {
  BaseResponse _user;
  dynamic _genRow = {};
  dynamic _genRowType = {};
  List<dynamic> _timeDefineTypeList = [];
  List<dynamic> _dayApplyList = [];
  List<dynamic> _dataList = [];
  List<dynamic> _overtimeList = [];
  List<dynamic> _timeDefineDetailList = [];
  TextEditingController _idEdtController = TextEditingController();
  TextEditingController _nameEdtController = TextEditingController();
  TextEditingController _shortNameEdtController = TextEditingController();
  TextEditingController _descEdtController = TextEditingController();
  TextEditingController _workFactorEdtController = TextEditingController();
  TextEditingController _workHourFactorEdtController = TextEditingController();
  TextEditingController _tdStyleEdtController = TextEditingController();
  TextEditingController _startTdEdtController = TextEditingController();
  TextEditingController _endTdEdtController = TextEditingController();
  TextEditingController _errorBefEdtController = TextEditingController();
  TextEditingController _errorLateEdtController = TextEditingController();
  TextEditingController _errorEarlyEdtController = TextEditingController();
  TextEditingController _errorAfEndEdtController = TextEditingController();
  TextEditingController _startCheckEdtController = TextEditingController();
  TextEditingController _endCheckEdtController = TextEditingController();
  TextEditingController _hsTLEdtController = TextEditingController();
  TextEditingController _hsCCNEdtController = TextEditingController();
  TextEditingController _hsCTCEdtController = TextEditingController();
  TextEditingController _hsCTCCNEdtController = TextEditingController();
  TextEditingController _nameTypeEdtController = TextEditingController();
  TextEditingController _workFactorTypeEdtController = TextEditingController();

  dynamic _overMultiSelected;
  dynamic _overtimeSelected;
  dynamic _timeTypeSelected;
  bool _enableUpdateButton = false;
  bool _errID = false;
  bool _errName = false;
  bool _errShortName = false;
  bool _errDescription = false;
  bool _errFactor = false;
  bool _errFactorHour = false;
  bool _errTimeStartApply = false;
  bool _errTimeEndApply = false;
  bool _errAllowLate = false;
  bool _errAllowEarly = false;
  bool _errTimeStartRecord = false;
  bool _errTimeEndRecord = false;
  bool _errHSTL = false;
  bool _errHSCN = false;
  bool _errHSTC = false;
  bool _errHSTCCN = false;
  bool _errTdType = false;
  bool _autoFlgCheck = false;
  bool _isDiCaCheck = false;
  bool _isCongChuanHCCheck = false;
  bool _isUpdated = false;

  @override
  void initState() {
    super.initState();
    _user = context.read<BaseResponse>();
    if (widget.data['type'].contains('update'))
      initData();
    else {
      _idEdtController.addListener(_onTextFieldChange);
      _nameEdtController.addListener(_onTextFieldChange);
      _shortNameEdtController.addListener(_onTextFieldChange);
      _descEdtController.addListener(_onTextFieldChange);
      _workFactorEdtController.addListener(_onTextFieldChange);
      _workHourFactorEdtController.addListener(_onTextFieldChange);
      _startTdEdtController.addListener(_onTextFieldChange);
      _endTdEdtController.addListener(_onTextFieldChange);
      _errorBefEdtController.addListener(_onTextFieldChange);
      _errorLateEdtController.addListener(_onTextFieldChange);
      _errorEarlyEdtController.addListener(_onTextFieldChange);
      _errorAfEndEdtController.addListener(_onTextFieldChange);
      _startCheckEdtController.addListener(_onTextFieldChange);
      _endCheckEdtController.addListener(_onTextFieldChange);
      _hsTLEdtController.addListener(_onTextFieldChange);
      _hsCCNEdtController.addListener(_onTextFieldChange);
      _hsCTCEdtController.addListener(_onTextFieldChange);
      _hsCTCCNEdtController.addListener(_onTextFieldChange);
      for (int i = 0; i <= 6; i++) {
        _dayApplyList.add({'value': i, 'check': false});
      }
    }
    for (var item in widget.data['data'])
      _dataList.add({'id': item['ID'], 'name': item['name_time_define']['v']});
  }

  initData() {
    _idEdtController.text =
        widget.data['dataItem']['time_define_code']['v'].trim() ?? '';
    _nameEdtController.text =
        widget.data['dataItem']['name_time_define']['v'].trim() ?? '';
    _shortNameEdtController.text =
        widget.data['dataItem']['short_name']['v'].trim() ?? '';
    _descEdtController.text =
        widget.data['dataItem']['desc_time_define']['v'].trim() ?? '';
    _workFactorEdtController.text =
        widget.data['dataItem']['working_factor']['v'].trim() ?? '';
    _workHourFactorEdtController.text =
        widget.data['dataItem']['working_hour_factor']['v'].trim() ?? '';
    _tdStyleEdtController.text =
        widget.data['dataItem']['time_define_style']['v'].trim() ?? '';
    _startTdEdtController.text =
        widget.data['dataItem']['start_time_define']['v'].trim() != ''
            ? Utils().convertDoubleToTime(double.parse(
                widget.data['dataItem']['start_time_define']['v'].trim()))
            : '';
    _endTdEdtController.text =
        widget.data['dataItem']['end_time_define']['v'].trim() != ''
            ? Utils().convertDoubleToTime(double.parse(
                widget.data['dataItem']['end_time_define']['v'].trim()))
            : '';
    _errorBefEdtController.text =
        widget.data['dataItem']['error_before']['v'].trim() ?? '';
    _errorLateEdtController.text =
        widget.data['dataItem']['error_late']['v'].trim() ?? '';
    _errorEarlyEdtController.text =
        widget.data['dataItem']['error_early']['v'].trim() ?? '';
    _errorAfEndEdtController.text =
        widget.data['dataItem']['error_after_end']['v'].trim() ?? '';
    _startCheckEdtController.text =
        widget.data['dataItem']['start_timecheck_define']['v'].trim() ?? '';
    _endCheckEdtController.text =
        widget.data['dataItem']['end_timecheck_define']['v'].trim() ?? '';
    _hsTLEdtController.text =
        widget.data['dataItem']['HeSo_TinhLuong']['v'].trim() ?? '';
    _hsCCNEdtController.text =
        widget.data['dataItem']['HeSo_CongCN']['v'].trim() ?? '';
    _hsCTCEdtController.text =
        widget.data['dataItem']['HeSo_CongTC']['v'].trim() ?? '';
    _hsCTCCNEdtController.text =
        widget.data['dataItem']['HeSo_TC_CN']['v'].trim() ?? '';

    for (int i = 0; i <= 6; i++) {
      if (widget.data['dataItem']['day']['v']
              .toString()
              .split(';')
              .where((item) => int.parse(item) == i)
              .toList()
              .length >
          0)
        _dayApplyList.add({'value': i, 'check': true});
      else
        _dayApplyList.add({'value': i, 'check': false});
    }

    if (widget.data['dataItem']['time_define_overtime_multi']['v'] != '') {
      dynamic overSelected = widget.data['data']
          .where((item) =>
              item['ID'] ==
              widget.data['dataItem']['time_define_overtime_multi']['v'].trim())
          .toList()[0];

      _overMultiSelected = {
        'id': overSelected['ID'],
        'name': overSelected['name_time_define']['v']
      };
    }
  }

  _onTextFieldChange() {
    List<dynamic> listDay = [];
    listDay = _dayApplyList.where((item) => item['check']).toList();
    if (((_idEdtController.text.isEmpty && _genRow['time_define_code']['allowNull']) || _idEdtController.text.isNotEmpty) &&
        ((_nameEdtController.text.isEmpty && _genRow['name_time_define']['allowNull']) ||
            _nameEdtController.text.isNotEmpty) &&
        ((_shortNameEdtController.text.isEmpty && _genRow['short_name']['allowNull']) ||
            _shortNameEdtController.text.isNotEmpty) &&
        ((_descEdtController.text.isEmpty && _genRow['desc_time_define']['allowNull']) ||
            _descEdtController.text.isNotEmpty) &&
        ((_workFactorEdtController.text.isEmpty && _genRow['working_factor']['allowNull']) ||
            _workFactorEdtController.text.isNotEmpty) &&
        ((_workHourFactorEdtController.text.isEmpty && _genRow['working_hour_factor']['allowNull']) ||
            _workHourFactorEdtController.text.isNotEmpty) &&
        ((listDay.length == 0 && _genRow['day']['allowNull']) ||
            listDay.length > 0) &&
        ((_timeTypeSelected == null && _genRow['time_define_style']['allowNull']) ||
            _timeTypeSelected != null) &&
        ((_startTdEdtController.text.isEmpty && _genRow['start_time_define']['allowNull']) ||
            _startTdEdtController.text.isNotEmpty) &&
        ((_endTdEdtController.text.isEmpty && _genRow['end_time_define']['allowNull']) ||
            _endTdEdtController.text.isNotEmpty) &&
        ((_errorBefEdtController.text.isEmpty && _genRow['error_before']['allowNull']) ||
            _errorBefEdtController.text.isNotEmpty) &&
        ((_errorLateEdtController.text.isEmpty && _genRow['error_late']['allowNull']) ||
            _errorLateEdtController.text.isNotEmpty) &&
        ((_errorEarlyEdtController.text.isEmpty && _genRow['error_early']['allowNull']) ||
            _errorEarlyEdtController.text.isNotEmpty) &&
        ((_errorAfEndEdtController.text.isEmpty && _genRow['error_after_end']['allowNull']) ||
            _errorAfEndEdtController.text.isNotEmpty) &&
        ((_startCheckEdtController.text.isEmpty && _genRow['start_timecheck_define']['allowNull']) ||
            _startCheckEdtController.text.isNotEmpty) &&
        ((_endCheckEdtController.text.isEmpty && _genRow['end_timecheck_define']['allowNull']) ||
            _endCheckEdtController.text.isNotEmpty) &&
        ((_hsTLEdtController.text.isEmpty && _genRow['HeSo_TinhLuong']['allowNull']) ||
            _hsTLEdtController.text.isNotEmpty) &&
        ((_hsCCNEdtController.text.isEmpty && _genRow['HeSo_CongCN']['allowNull']) ||
            _hsCCNEdtController.text.isNotEmpty) &&
        ((_hsCTCEdtController.text.isEmpty && _genRow['HeSo_CongTC']['allowNull']) ||
            _hsCTCEdtController.text.isNotEmpty) &&
        ((_hsCTCCNEdtController.text.isEmpty && _genRow['HeSo_TC_CN']['allowNull']) || _hsCTCCNEdtController.text.isNotEmpty) &&
        ((_overMultiSelected == null && _genRow['time_define_overtime_multi']['allowNull']) || _overMultiSelected != null) &&
        ((_overtimeSelected == null && _genRow['time_define_overtime_type']['allowNull']) || _overtimeSelected != null))
      _enableUpdateButton = true;
    else
      _enableUpdateButton = false;
    setState(() {});
  }

  @override
  void dispose() {
    if (!mounted) {
      _idEdtController.dispose();
      _nameEdtController.dispose();
      _shortNameEdtController.dispose();
      _descEdtController.dispose();
      _workFactorEdtController.dispose();
      _workHourFactorEdtController.dispose();
      _tdStyleEdtController.dispose();
      _startTdEdtController.dispose();
      _endTdEdtController.dispose();
      _errorBefEdtController.dispose();
      _errorLateEdtController.dispose();
      _errorEarlyEdtController.dispose();
      _errorAfEndEdtController.dispose();
      _startCheckEdtController.dispose();
      _endCheckEdtController.dispose();
      _hsTLEdtController.dispose();
      _hsCCNEdtController.dispose();
      _hsCTCEdtController.dispose();
      _hsCTCCNEdtController.dispose();
    }
    super.dispose();
  }

  void getGenRowDefine(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "tb_hrms_chamcong_time_define_V2"},
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

  void getTimeDefineType(BaseViewModel model) async {
    _timeDefineTypeList.clear();
    List<dynamic> _list = [];
    var response = await model.callApis({}, getTimeTypeUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var item in response.data['data']) {
        if (item['ID'] == _tdStyleEdtController.text)
          _timeTypeSelected = {
            'id': item['ID'],
            'name': item['name_time_define']['v']
          };
        _list.add({'id': item['ID'], 'name': item['name_time_define']['v']});
      }
    }
    setState(() {
      _timeDefineTypeList.addAll(_list);
    });
  }

  dynamic checkUpdateValue() async {
    var data = {};
    String _dayApply = '';
    if (_idEdtController.text !=
        widget.data['dataItem']['time_define_code']['v'].trim())
      data = {
        ...data,
        ...{"time_define_code": _idEdtController.text}
      };
    if (_nameEdtController.text !=
        widget.data['dataItem']['name_time_define']['v'].trim())
      data = {
        ...data,
        ...{"name_time_define": _nameEdtController.text}
      };
    if (_shortNameEdtController.text !=
        widget.data['dataItem']['short_name']['v'].trim())
      data = {
        ...data,
        ...{"short_name": _shortNameEdtController.text}
      };
    if (_descEdtController.text !=
        widget.data['dataItem']['desc_time_define']['v'].trim())
      data = {
        ...data,
        ...{"desc_time_define": _descEdtController.text}
      };
    if (_workFactorEdtController.text !=
        widget.data['dataItem']['working_factor']['v'].trim())
      data = {
        ...data,
        ...{"working_factor": _workFactorEdtController.text}
      };
    if (_workHourFactorEdtController.text !=
        widget.data['dataItem']['working_hour_factor']['v'].trim())
      data = {
        ...data,
        ...{"working_hour_factor": _workFactorEdtController.text}
      };
    _dayApplyList.forEach((item) {
      if (item['check']) _dayApply = _dayApply + '${item['value']};';
    });
    _dayApply = _dayApply.substring(0, _dayApply.length - 1);
    if (_dayApply != widget.data['dataItem']['day']['v'].trim())
      data = {
        ...data,
        ...{"day": _dayApply}
      };
    if (_timeTypeSelected != null &&
        _timeTypeSelected['id'] !=
            widget.data['dataItem']['time_define_style']['v'])
      data = {
        ...data,
        ...{"time_define_style": _timeTypeSelected['id']}
      };
    if (Utils().convertTimeToDouble(_startTdEdtController.text) !=
        widget.data['dataItem']['start_time_define']['v'])
      data = {
        ...data,
        ...{
          "start_time_define":
              Utils().convertTimeToDouble(_startTdEdtController.text)
        }
      };
    if (Utils().convertTimeToDouble(_endTdEdtController.text) !=
        widget.data['dataItem']['end_time_define']['v'])
      data = {
        ...data,
        ...{
          "end_time_define":
              Utils().convertTimeToDouble(_endTdEdtController.text)
        }
      };
    if (_errorBefEdtController.text !=
        widget.data['dataItem']['error_before']['v'].trim())
      data = {
        ...data,
        ...{"error_before": _errorBefEdtController.text}
      };
    if (_errorLateEdtController.text !=
        widget.data['dataItem']['error_late']['v'].trim())
      data = {
        ...data,
        ...{"error_late": _errorLateEdtController.text}
      };
    if (_errorEarlyEdtController.text !=
        widget.data['dataItem']['error_early']['v'].trim())
      data = {
        ...data,
        ...{"error_early": _errorEarlyEdtController.text}
      };
    if (_errorAfEndEdtController.text !=
        widget.data['dataItem']['error_after_end']['v'].trim())
      data = {
        ...data,
        ...{"error_after_end": _errorAfEndEdtController.text}
      };
    if (_startCheckEdtController.text !=
        widget.data['dataItem']['start_timecheck_define']['v'].trim())
      data = {
        ...data,
        ...{"start_timecheck_define": _startCheckEdtController.text}
      };
    if (_endCheckEdtController.text !=
        widget.data['dataItem']['end_timecheck_define']['v'].trim())
      data = {
        ...data,
        ...{"end_timecheck_define": _endCheckEdtController.text}
      };
    if (_hsTLEdtController.text !=
        widget.data['dataItem']['HeSo_TinhLuong']['v'].trim())
      data = {
        ...data,
        ...{"HeSo_TinhLuong": _hsTLEdtController.text}
      };
    if (_hsCCNEdtController.text !=
        widget.data['dataItem']['HeSo_CongCN']['v'].trim())
      data = {
        ...data,
        ...{"HeSo_CongCN": _hsCCNEdtController.text}
      };
    if (_hsCTCEdtController.text !=
        widget.data['dataItem']['HeSo_CongTC']['v'].trim())
      data = {
        ...data,
        ...{"HeSo_CongTC": _hsCTCEdtController.text}
      };
    if (_hsCTCCNEdtController.text !=
        widget.data['dataItem']['HeSo_TC_CN']['v'].trim())
      data = {
        ...data,
        ...{"HeSo_TC_CN": _hsCTCCNEdtController.text}
      };
    data = {
      ...data,
      ...{
        "time_define_overtime_multi":
            _overMultiSelected != null ? _overMultiSelected['id'] : ''
      }
    };
    data = {
      ...data,
      ...{
        "time_define_overtime_type":
            _overtimeSelected != null ? _overtimeSelected['id'] : ''
      }
    };

    return data;
  }

  dynamic checkAddValue({bool back = false}) async {
    String _dayApply = '';
    if (!back) {
      /*if (_idEdtController.text.isEmpty) _errID = true;*/
      if (_nameEdtController.text.isEmpty) _errName = true;
      if (_shortNameEdtController.text.isEmpty) _errShortName = true;
      if (_workFactorEdtController.text.isEmpty) _errFactor = true;
      if (_workHourFactorEdtController.text.isEmpty) _errFactorHour = true;
      if (_timeTypeSelected == null) _errTdType = true;
      if (_dayApplyList.where((item) => item['check']).toList().length == 0) {
        showMessageDialogIOS(context,
            description: 'Chưa chọn ' + _genRow['day']['name']);
        return null;
      }
      if (/*_errID ||*/
          _errName ||
          _errShortName ||
          _errFactor ||
          _errFactorHour ||
          _errTdType) return null;
    }
    _dayApplyList.forEach((item) {
      if (item['check']) _dayApply = _dayApply + '${item['value']};';
    });
    _dayApply = _dayApply.substring(0, _dayApply.length - 1);
    var data = {
      'time_define_code': _idEdtController.text,
      'name_time_define': _nameEdtController.text,
      'short_name': _shortNameEdtController.text,
      'working_factor': _workFactorEdtController.text,
      'working_hour_factor': _workHourFactorEdtController.text,
      'day': _dayApply,
      'time_define_style': _timeTypeSelected['id'],
      'company_id': _user.data['data'][0]['company_id']['v']
    };

    if (_descEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'desc_time_define': _descEdtController.text}
      };
    if (_startTdEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{
          'start_time_define':
              Utils().convertTimeToDouble(_startTdEdtController.text)
        }
      };
    if (_endTdEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{
          'end_time_define':
              Utils().convertTimeToDouble(_endTdEdtController.text)
        }
      };
    if (_errorBefEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'error_before': _errorBefEdtController.text}
      };
    if (_errorLateEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'error_late': _errorLateEdtController.text}
      };
    if (_errorEarlyEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'error_early': _errorEarlyEdtController.text}
      };
    if (_errorAfEndEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'error_after_end': _errorAfEndEdtController.text}
      };
    if (_startCheckEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'start_timecheck_define': _startCheckEdtController.text}
      };
    if (_endCheckEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'end_timecheck_define': _endCheckEdtController.text}
      };
    if (_hsTLEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'HeSo_TinhLuong': _hsTLEdtController.text}
      };
    if (_hsCCNEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'HeSo_CongCN': _hsCCNEdtController.text}
      };
    if (_hsCTCEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'HeSo_CongTC': _hsCTCEdtController.text}
      };
    if (_hsCTCCNEdtController.text.isNotEmpty)
      data = {
        ...data,
        ...{'HeSo_TC_CN': _hsCTCCNEdtController.text}
      };
    if (_overMultiSelected != null)
      data = {
        ...data,
        ...{'time_define_overtime_multi': _overMultiSelected['id']}
      };
    if (_overtimeSelected != null)
      data = {
        ...data,
        ...{'time_define_overtime_type': _overtimeSelected['id']}
      };

    return data;
  }

  void getCaseOvertimeApply(BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await model.callApis(
        {}, getCaseOvertimeApplyUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200) {
      for (var list in response.data['data'])
        _list.add(
            {'id': list['ID'], 'name': list['name_time_define_overtime']['v']});
      setState(() {
        _overtimeList.addAll(_list);
        if (widget.data['dataItem'] != null) if (widget.data['dataItem']
                ['time_define_overtime_type']['v'] !=
            '')
          _overtimeSelected = _overtimeList
              .where((item) =>
                  item['id'] ==
                  widget.data['dataItem']['time_define_overtime_type']['v'])
              .toList()[0];
      });
    }
  }

  void _getTimeDefineDetail(BaseViewModel model) async {
    _timeDefineDetailList.clear();
    var response = await model.callApis(
        {"time_define_id": widget.data['dataItem']['ID']},
        getTimeDefineDetailUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _timeDefineDetailList.addAll(response.data['data']);
      });
  }

  void _editData(BaseViewModel model) async {
    var data = await checkUpdateValue();
    if (data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_chamcong_time_define_V2");
      var response = await model.callApis({
        "tbname": encryptData,
        "dataid": widget.data['dataItem']['ID'],
        ...data
      }, updateDataUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      Navigator.pop(context);
      if (response.status.code == 200) {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success),
            onPress: () {
          Navigator.pop(context);
          setState(() {
            _enableUpdateButton = false;
            _isUpdated = true;
          });
        });
      }
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_not_change));
  }

  void _addData(BaseViewModel model) async {
    var data = await checkAddValue();
    if (data != null && data.length > 0) {
      showLoadingDialog(context);
      var encryptData = await Utils.encrypt("tb_hrms_chamcong_time_define_V2");
      var response = await model.callApis(
          {"tbname": encryptData, ...data}, addDataUrl, method_post,
          shouldSkipAuth: false, isNeedAuthenticated: true);
      Navigator.pop(context);
      if (response.status.code == 200)
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success),
            onPress: () {
          Navigator.pop(context);
          Navigator.pop(context, true);
        });
    }
  }

  void _deleteTDDetail(BaseViewModel model, String dataID, int index) async {
    showLoadingDialog(context);
    var encryptData =
        await Utils.encrypt("tb_hrms_chamcong_time_define_detail_V2");
    var response = await model.callApis(
        {'tbname': encryptData, 'dataid': dataID}, deleteDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200)
      setState(() {
        _timeDefineDetailList.removeAt(index);
      });
    else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
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

  _getGenRowType(BaseViewModel model) async {
    var response = await model.callApis(
        {"TbName": "vw_tb_hrms_time_define_style"},
        getGenRowDefineUrl,
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _genRowType = Utils.getListGenRow(response.data['data'], 'add');
      });
  }

  void _addTimeDefineType(BaseViewModel model) async {
    showLoadingDialog(context);
    var encryptData = await Utils.encrypt("vw_tb_hrms_time_define_style");
    var response = await model.callApis({
      'tbname': encryptData,
      'name_time_define': _nameTypeEdtController.text,
      'working_factor': _workFactorTypeEdtController.text,
      'auto_flg': _autoFlgCheck,
      'isDiCa': _isDiCaCheck,
      'isCongChuanHC': _isCongChuanHCCheck,
      'company_id': _user.data['data'][0]['company_id']['v']
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
      _workFactorTypeEdtController.text = '';
      _autoFlgCheck = false;
      _isDiCaCheck = false;
      _isCongChuanHCCheck = false;
      getTimeDefineType(model);
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
          getTimeDefineType(model);
          getCaseOvertimeApply(model);
          if (widget.data['type'].contains('update'))
            _getTimeDefineDetail(model);
        },
        model: BaseViewModel(),
        builder: (context, model, child) => Scaffold(
              appBar: appBarCustom(context, () async {
                if(_isUpdated)
                  Navigator.pop(context, true);
                else Navigator.pop(context);
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
            ));
  }

  Widget _content(BaseViewModel model) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildContentText(
              keyName: 'time_define_code',
              controller: _idEdtController,
              forceError: _errID,
              genRow: _genRow,
              allowNull: _genRow['time_define_code']['allowNull'],
              isEnable: _genRow['time_define_code']['allowEdit'],
              textCapitalization: TextCapitalization.characters),
          _buildContentText(
              keyName: 'name_time_define',
              textCapitalization: TextCapitalization.sentences,
              controller: _nameEdtController,
              genRow: _genRow,
              allowNull: _genRow['name_time_define']['allowNull'],
              forceError: _errName,
              isEnable: _genRow['name_time_define']['allowEdit']),
          _buildContentText(
              keyName: 'short_name',
              forceError: _errShortName,
              genRow: _genRow,
              allowNull: _genRow['short_name']['allowNull'],
              textCapitalization: TextCapitalization.characters,
              controller: _shortNameEdtController,
              isEnable: _genRow['short_name']['allowEdit']),
          _buildContentText(
              keyName: 'desc_time_define',
              forceError: _errDescription,
              genRow: _genRow,
              allowNull: _genRow['desc_time_define']['allowNull'],
              textCapitalization: TextCapitalization.sentences,
              controller: _descEdtController,
              isEnable: _genRow['desc_time_define']['allowEdit']),
          _buildContentText(
              keyName: 'working_factor',
              forceError: _errFactor,
              genRow: _genRow,
              allowNull: _genRow['working_factor']['allowNull'],
              controller: _workFactorEdtController,
              isEnable: _genRow['working_factor']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'working_hour_factor',
              forceError: _errFactorHour,
              genRow: _genRow,
              allowNull: _genRow['working_hour_factor']['allowNull'],
              controller: _workHourFactorEdtController,
              isEnable: _genRow['working_hour_factor']['allowEdit'],
              textInputType: TextInputType.number),
          boxTitle(context, _genRow['day']['name']),
          _buildDayApply(),
          Row(
            children: <Widget>[
              boxTitle(context, _genRow['time_define_style']['name']),
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
          _buildSelectBox(_timeTypeSelected,
              _genRow['time_define_style']['name'], _timeDefineTypeList),
          _buildContentText(
              keyName: 'start_time_define',
              controller: _startTdEdtController,
              icon: ic_calendar,
              genRow: _genRow,
              clearText: true,
              isEnable: false,
              onPress: _genRow['start_time_define']['allowEdit']
                  ? () async {
                      var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm')
                            .parse(_startTdEdtController.text == ''
                                ? '00:00'
                                : _startTdEdtController.text)),
                      );
                      if (time == null) return;
                      setState(() {
                        _startTdEdtController.text = time
                            .toString()
                            .replaceAll('TimeOfDay(', '')
                            .replaceAll(')', '');
                        _enableUpdateButton = true;
                      });
                    }
                  : () {},
              onClear: () {
                setState(() {
                  _startTdEdtController.text = '';
                });
              }),
          _buildContentText(
              keyName: 'end_time_define',
              controller: _endTdEdtController,
              icon: ic_calendar,
              genRow: _genRow,
              clearText: true,
              isEnable: false,
              onPress: _genRow['end_time_define']['allowEdit']
                  ? () async {
                      var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm')
                            .parse(_endTdEdtController.text == ''
                                ? '00:00'
                                : _endTdEdtController.text)),
                      );
                      if (time == null) return;
                      setState(() {
                        _endTdEdtController.text = time
                            .toString()
                            .replaceAll('TimeOfDay(', '')
                            .replaceAll(')', '');
                        _enableUpdateButton = true;
                      });
                    }
                  : () {},
              onClear: () {
                setState(() {
                  _endTdEdtController.text = '';
                });
              }),
          _buildContentText(
              keyName: 'error_before',
              controller: _errorBefEdtController,
              forceError: _errTimeStartApply,
              genRow: _genRow,
              allowNull: _genRow['error_before']['allowNull'],
              isEnable: _genRow['error_before']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'error_after_end',
              controller: _errorAfEndEdtController,
              genRow: _genRow,
              allowNull: _genRow['error_after_end']['allowNull'],
              forceError: _errTimeEndApply,
              isEnable: _genRow['error_after_end']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'error_late',
              controller: _errorLateEdtController,
              forceError: _errAllowLate,
              genRow: _genRow,
              allowNull: _genRow['error_late']['allowNull'],
              isEnable: _genRow['error_late']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'error_early',
              controller: _errorEarlyEdtController,
              forceError: _errAllowEarly,
              genRow: _genRow,
              allowNull: _genRow['error_early']['allowNull'],
              isEnable: _genRow['error_early']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'start_timecheck_define',
              controller: _startCheckEdtController,
              forceError: _errTimeStartRecord,
              genRow: _genRow,
              allowNull: _genRow['start_timecheck_define']['allowNull'],
              isEnable: _genRow['start_timecheck_define']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'end_timecheck_define',
              controller: _endCheckEdtController,
              forceError: _errTimeEndRecord,
              genRow: _genRow,
              allowNull: _genRow['end_timecheck_define']['allowNull'],
              isEnable: _genRow['end_timecheck_define']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'HeSo_TinhLuong',
              controller: _hsTLEdtController,
              forceError: _errHSTL,
              genRow: _genRow,
              allowNull: _genRow['HeSo_TinhLuong']['allowNull'],
              isEnable: _genRow['HeSo_TinhLuong']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'HeSo_CongCN',
              controller: _hsCCNEdtController,
              forceError: _errHSCN,
              genRow: _genRow,
              allowNull: _genRow['HeSo_CongCN']['allowNull'],
              isEnable: _genRow['HeSo_CongCN']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'HeSo_CongTC',
              controller: _hsCTCEdtController,
              forceError: _errHSTC,
              genRow: _genRow,
              allowNull: _genRow['HeSo_CongTC']['allowNull'],
              isEnable: _genRow['HeSo_CongTC']['allowEdit'],
              textInputType: TextInputType.number),
          _buildContentText(
              keyName: 'HeSo_TC_CN',
              forceError: _errHSTCCN,
              genRow: _genRow,
              allowNull: _genRow['HeSo_TC_CN']['allowNull'],
              controller: _hsCTCCNEdtController,
              isEnable: _genRow['HeSo_TC_CN']['allowEdit'],
              textInputType: TextInputType.number),
          boxTitle(context, _genRow['time_define_overtime_multi']['name']),
          _buildSelectBox(_overMultiSelected,
              _genRow['time_define_overtime_multi']['name'], _dataList),
          boxTitle(context, _genRow['time_define_overtime_type']['name']),
          _buildSelectBox(_overtimeSelected,
              _genRow['time_define_overtime_type']['name'], _overtimeList),
          if (widget.data['type'].contains('update'))
            _buildTimeDefineDetail(model),
          SizedBox(
            height: Utils.resizeHeightUtil(context, 50),
          ),
          TKButton(Utils.getString(context, txt_save),
              enable: _enableUpdateButton, width: double.infinity, onPress: () {
            FocusScope.of(context).unfocus();
            if (widget.data['type'].contains('update'))
              _editData(model);
            else
              _addData(model);
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
      dynamic genRow,
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
            boxTitle(context, genRow[keyName]['name']),
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
                    if (widget.data['type'].contains('update'))
                      _enableUpdateButton = true;
                    if (!allowNull)
                      switch (keyName) {
                        case 'name_time_define':
                          _errName = controller.text.trimRight().isEmpty;
                          break;
                        case 'short_name':
                          _errShortName = controller.text.trimRight().isEmpty;
                          break;
                        case 'desc_time_define':
                          _errDescription = controller.text.trimRight().isEmpty;
                          break;
                        case 'working_factor':
                          _errFactor = controller.text.trimRight().isEmpty;
                          break;
                        case 'working_hour_factor':
                          _errFactorHour = controller.text.trimRight().isEmpty;
                          break;
                        case 'error_before':
                          _errTimeStartApply =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'error_after_end':
                          _errTimeEndApply =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'error_late':
                          _errAllowLate = controller.text.trimRight().isEmpty;
                          break;
                        case 'error_early':
                          _errAllowEarly = controller.text.trimRight().isEmpty;
                          break;
                        case 'start_timecheck_define':
                          _errTimeStartRecord =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'end_timecheck_define':
                          _errTimeEndRecord =
                              controller.text.trimRight().isEmpty;
                          break;
                        case 'HeSo_TinhLuong':
                          _errHSTL = controller.text.trimRight().isEmpty;
                          break;
                        case 'HeSo_CongCN':
                          _errHSCN = controller.text.trimRight().isEmpty;
                          break;
                        case 'HeSo_CongTC':
                          _errHSTC = controller.text.trimRight().isEmpty;
                          break;
                        case 'HeSo_TC_CN':
                          _errHSTCCN = controller.text.trimRight().isEmpty;
                      }
                  });
                },
                clearText: clearText),
          ],
        ),
      ),
    );
  }

  Widget _buildDayApply() => Container(
        height: Utils.resizeHeightUtil(context, 100),
        margin:
            EdgeInsets.symmetric(vertical: Utils.resizeHeightUtil(context, 10)),
        width: double.infinity,
        child: Center(
          child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: _dayApplyList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    _dayApplyList[index]['check'] =
                        !_dayApplyList[index]['check'];
                    if (widget.data['type'].contains('update'))
                      setState(() {
                        _enableUpdateButton = true;
                      });
                    else
                      _onTextFieldChange();
                  },
                  child: Container(
                    padding: EdgeInsets.only(
                        left: Utils.resizeWidthUtil(context, 20),
                        right: Utils.resizeWidthUtil(context, 20)),
                    child: Column(
                      children: <Widget>[
                        _dayApplyList[index]['check']
                            ? Icon(Icons.radio_button_checked,
                                color: only_color, size: 30)
                            : Icon(Icons.radio_button_unchecked, size: 30),
                        SizedBox(height: Utils.resizeHeightUtil(context, 10)),
                        Expanded(
                          child: TKText(
                            index == 0 ? 'CN' : 'T${index + 1}',
                            tkFont: TKFont.SFProDisplayMedium,
                            style: TextStyle(
                                fontSize: Utils.resizeWidthUtil(context, 28),
                                color: _dayApplyList[index]['check']
                                    ? only_color
                                    : txt_grey_color_v1),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
        ),
      );

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
                      keyName: 'name_time_define',
                      controller: _nameTypeEdtController,
                      genRow: _genRowType,
                      isEnable: _genRowType['name_time_define']['allowEdit'],
                      textCapitalization: TextCapitalization.characters),
                  _buildContentText(
                      keyName: 'working_factor',
                      controller: _workFactorTypeEdtController,
                      genRow: _genRowType,
                      isEnable: _genRowType['working_factor']['allowEdit'],
                      textInputType: TextInputType.phone),
                  _buildCheckBox(_genRowType['auto_flg']['name'], _autoFlgCheck,
                      modalState),
                  _buildCheckBox(
                      _genRowType['isDiCa']['name'], _isDiCaCheck, modalState),
                  _buildCheckBox(_genRowType['isCongChuanHC']['name'],
                      _isCongChuanHCCheck, modalState),
                  SizedBox(
                    height: Utils.resizeHeightUtil(context, 20),
                  ),
                  TKButton(Utils.getString(context, txt_save),
                      enable: true, width: double.infinity, onPress: () {
                    FocusScope.of(context).unfocus();
                    if (_nameTypeEdtController.text.isNotEmpty &&
                        _workFactorTypeEdtController.text.isNotEmpty)
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

  Widget _buildCheckBox(String title, bool check, StateSetter modalState) =>
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          modalState(() {
            if (title == _genRowType['auto_flg']['name'])
              _autoFlgCheck = !_autoFlgCheck;
            else if (title == _genRowType['isDiCa']['name'])
              _isDiCaCheck = !_isDiCaCheck;
            else
              _isCongChuanHCCheck = !_isCongChuanHCCheck;
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

  Widget _buildSelectBox(dynamic data, String title, List<dynamic> list) =>
      SelectBoxCustomUtil(
        title: data != null ? data['name'] : '',
        data: list,
        initCallback: (state) {},
        enableSearch: false,
        clearCallback: () {
          setState(() {
            if (widget.data['type'].contains('update'))
              _enableUpdateButton = true;
            if (title.contains(_genRow['time_define_overtime_multi']['name']))
              _overMultiSelected = null;
            if (title.contains(_genRow['time_define_overtime_type']['name']))
              _overtimeSelected = null;
          });
        },
        callBack: (itemSelected) {
          setState(() {
            if (widget.data['type'].contains('update'))
              _enableUpdateButton = true;
            if (title.contains(_genRow['time_define_overtime_multi']['name']))
              _overMultiSelected = itemSelected;
            if (title.contains(_genRow['time_define_style']['name']))
              _timeTypeSelected = itemSelected;
            if (title.contains(_genRow['time_define_overtime_type']['name']))
              _overtimeSelected = itemSelected;
          });
        },
      );

  Widget _buildTimeDefineDetail(BaseViewModel model) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              boxTitle(context, 'Phân đoạn ca'),
              SizedBox(
                width: Utils.resizeWidthUtil(context, 20),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
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
                          child: StatefulBuilder(
                              builder: (context, setModalState) {
                            return EditTimeDefineDetail(
                              data: widget.data['dataItem'],
                              genRow: _genRow,
                              model: model,
                              setModalState: setModalState,
                              type: 'add',
                              callback: _getTimeDefineDetail,
                            );
                          })),
                    ),
                  );
                },
                child: Icon(
                  Icons.add_circle,
                  color: only_color,
                  size: 30,
                ),
              ),
            ],
          ),
          _timeDefineDetailItem(model)
        ],
      );

  Widget _timeDefineDetailItem(BaseViewModel model) {
    List<Widget> list = List<Widget>();
    for (int i = 0; i < _timeDefineDetailList.length; i++) {
      list.add(Container(
        padding: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 20)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: Utils.resizeWidthUtil(context, 50),
                    height: Utils.resizeWidthUtil(context, 50),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: only_color),
                    child: Center(
                      child: TKText(
                        '${i + 1}',
                        tkFont: TKFont.MEDIUM,
                        style: TextStyle(color: white_color),
                      ),
                    ),
                  ),
                  SizedBox(width: Utils.resizeWidthUtil(context, 20)),
                  TKText(
                    _timeDefineDetailList[i]['name_time_define']['v'],
                    style:
                        TextStyle(fontSize: Utils.resizeWidthUtil(context, 28)),
                  )
                ],
              ),
            ),
            SizedBox(width: Utils.resizeWidthUtil(context, 20)),
            Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      context: context,
                      builder: (context) => SingleChildScrollView(
                        child: Container(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            decoration: BoxDecoration(
                              border: Border.all(style: BorderStyle.none),
                            ),
                            child: StatefulBuilder(
                                builder: (context, setModalState) {
                              return EditTimeDefineDetail(
                                data: _timeDefineDetailList.length == 0
                                    ? {}
                                    : _timeDefineDetailList[i],
                                genRow: _genRow,
                                model: model,
                                setModalState: setModalState,
                                type: 'update',
                                callback: _getTimeDefineDetail,
                              );
                            })),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.edit,
                    color: txt_yellow,
                  ),
                ),
                TKText(
                  ' | ',
                  style: TextStyle(
                      color: txt_grey_color_v1,
                      fontSize: Utils.resizeWidthUtil(context, 28)),
                ),
                GestureDetector(
                  onTap: () {
                    showMessageDialog(context,
                        description:
                            Utils.getString(context, txt_confirm_delete),
                        onPress: () {
                      Navigator.pop(context);
                      _deleteTDDetail(model, _timeDefineDetailList[i]['ID'], i);
                    });
                  },
                  child: Icon(
                    Icons.delete,
                    color: txt_fail_color,
                  ),
                ),
              ],
            )
          ],
        ),
      ));
    }
    return SingleChildScrollView(
      child: Container(
          padding: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 10)),
          child: Column(children: list)),
    );
  }
}

class EditTimeDefineDetail extends StatefulWidget {
  final dynamic data;
  final dynamic genRow;
  final BaseViewModel model;
  final StateSetter setModalState;
  final String type;
  final Function(BaseViewModel model) callback;

  EditTimeDefineDetail(
      {this.data,
      this.genRow,
      this.model,
      this.setModalState,
      this.type,
      this.callback});

  @override
  _EditTimeDefineDetailState createState() => _EditTimeDefineDetailState();
}

class _EditTimeDefineDetailState extends State<EditTimeDefineDetail> {
  TextEditingController _nameEdtController = TextEditingController();
  TextEditingController _startTdEdtController = TextEditingController();
  TextEditingController _endTdEdtController = TextEditingController();
  TextEditingController _workFactorEdtController = TextEditingController();
  TextEditingController _workHourFactorEdtController = TextEditingController();
  TextEditingController _periodEdtController = TextEditingController();
  TextEditingController _errorLateEdtController = TextEditingController();
  TextEditingController _errorEarlyEdtController = TextEditingController();
  bool _enableUpdateButton = false;

  @override
  void initState() {
    super.initState();
    if (widget.type.contains('update'))
      initData();
    else {
      _nameEdtController.addListener(_onTextFieldChange);
      _workFactorEdtController.addListener(_onTextFieldChange);
      _workHourFactorEdtController.addListener(_onTextFieldChange);
      _periodEdtController.addListener(_onTextFieldChange);
      _errorLateEdtController.addListener(_onTextFieldChange);
      _errorEarlyEdtController.addListener(_onTextFieldChange);
    }
  }

  _onTextFieldChange() {
    if (_nameEdtController.text.isNotEmpty &&
        _workFactorEdtController.text.isNotEmpty &&
        _workHourFactorEdtController.text.isNotEmpty &&
        _periodEdtController.text.isNotEmpty &&
        _errorLateEdtController.text.isNotEmpty &&
        _errorEarlyEdtController.text.isNotEmpty)
      _enableUpdateButton = true;
    else
      _enableUpdateButton = false;
    setState(() {});
  }

  void initData() {
    _nameEdtController.text = widget.data['name_time_define']['v'].trim() ?? '';
    _startTdEdtController.text =
        widget.data['start_time_define']['v'].trim() != ''
            ? Utils().convertDoubleToTime(
                double.parse(widget.data['start_time_define']['v'].trim()))
            : '';
    _endTdEdtController.text = widget.data['end_time_define']['v'].trim() != ''
        ? Utils().convertDoubleToTime(
            double.parse(widget.data['end_time_define']['v'].trim()))
        : '';
    _workFactorEdtController.text =
        widget.data['working_factor']['v'].trim() ?? '';
    _workHourFactorEdtController.text =
        widget.data['working_hour_factor']['v'].trim() ?? '';
    _periodEdtController.text = widget.data['rest_period']['v'].trim() ?? '';
    _errorLateEdtController.text = widget.data['error_late']['v'].trim() ?? '';
    _errorEarlyEdtController.text =
        widget.data['error_early']['v'].trim() ?? '';
  }

  dynamic checkDataChangeUpdate() {
    var dataChange = {};
    if (_nameEdtController.text != widget.data['name_time_define']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"name_time_define": _nameEdtController.text}
      };
    if (Utils().convertTimeToDouble(_startTdEdtController.text) !=
        widget.data['start_time_define']['v'])
      dataChange = {
        ...dataChange,
        ...{
          "start_time_define":
              Utils().convertTimeToDouble(_startTdEdtController.text)
        }
      };
    if (Utils().convertTimeToDouble(_endTdEdtController.text) !=
        widget.data['end_time_define']['v'])
      dataChange = {
        ...dataChange,
        ...{
          "end_time_define":
              Utils().convertTimeToDouble(_endTdEdtController.text)
        }
      };
    if (_workFactorEdtController.text !=
        widget.data['working_factor']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"working_factor": _workFactorEdtController.text}
      };
    if (_workHourFactorEdtController.text !=
        widget.data['working_hour_factor']['v'].trim())
      dataChange = {
        ...dataChange,
        ...{"working_hour_factor": _workHourFactorEdtController.text}
      };
    return dataChange;
  }

  void _update() async {
    showLoadingDialog(context);
    var dataChange = await checkDataChangeUpdate();
    if (dataChange.length > 0) {
      var encryptData =
          await Utils.encrypt("tb_hrms_chamcong_time_define_detail_V2");
      var response = await widget.model.callApis(
          {"tbname": encryptData, "dataid": widget.data['ID'], ...dataChange},
          updateDataUrl,
          method_post,
          shouldSkipAuth: false,
          isNeedAuthenticated: true);
      Navigator.pop(context);
      if (response.status.code == 200)
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_success),
            onPress: () {
          Navigator.pop(context);
          Navigator.pop(context);
          widget.callback(widget.model);
        });
      else
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_update_failed));
    }
  }

  void _addData() async {
    showLoadingDialog(context);
    var encryptData =
        await Utils.encrypt("tb_hrms_chamcong_time_define_detail_V2");
    var response = await widget.model.callApis({
      "tbname": encryptData,
      "name_time_define": _nameEdtController.text,
      "time_define_id": widget.data['ID'],
      "start_time_define":
          Utils().convertTimeToDouble(_startTdEdtController.text),
      "end_time_define": Utils().convertTimeToDouble(_endTdEdtController.text),
      "working_factor": _workFactorEdtController.text,
      "working_hour_factor": _workHourFactorEdtController.text,
      "rest_period": _periodEdtController.text,
      "error_late": _errorLateEdtController.text,
      "error_early": _errorEarlyEdtController.text
    }, addDataUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    Navigator.pop(context);
    if (response.status.code == 200)
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_success),
          onPress: () {
        Navigator.pop(context);
        Navigator.pop(context);
        widget.callback(widget.model);
      });
    else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_update_failed));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                    keyName: 'name_time_define',
                    controller: _nameEdtController,
                    isEnable: true,
                    textCapitalization: TextCapitalization.words),
                _buildContentText(
                    keyName: 'start_time_define',
                    controller: _startTdEdtController,
                    icon: ic_calendar,
                    clearText: true,
                    isEnable: false,
                    onPress: () async {
                      var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm')
                            .parse(_startTdEdtController.text == ''
                                ? '00:00'
                                : _startTdEdtController.text)),
                      );
                      if (time == null) return;
                      setState(() {
                        _startTdEdtController.text = time
                            .toString()
                            .replaceAll('TimeOfDay(', '')
                            .replaceAll(')', '');
                        _enableUpdateButton = true;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _startTdEdtController.text = '';
                      });
                    }),
                _buildContentText(
                    keyName: 'end_time_define',
                    controller: _endTdEdtController,
                    icon: ic_calendar,
                    clearText: true,
                    isEnable: false,
                    onPress: () async {
                      var time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(DateFormat('HH:mm')
                            .parse(_endTdEdtController.text == ''
                                ? '00:00'
                                : _endTdEdtController.text)),
                      );
                      if (time == null) return;
                      setState(() {
                        _endTdEdtController.text = time
                            .toString()
                            .replaceAll('TimeOfDay(', '')
                            .replaceAll(')', '');
                        _enableUpdateButton = true;
                      });
                    },
                    onClear: () {
                      setState(() {
                        _endTdEdtController.text = '';
                      });
                    }),
                _buildContentText(
                    keyName: 'working_factor',
                    controller: _workFactorEdtController,
                    isEnable: true,
                    textInputType: TextInputType.number),
                _buildContentText(
                    keyName: 'working_hour_factor',
                    controller: _workHourFactorEdtController,
                    isEnable: true,
                    textInputType: TextInputType.number),
                _buildContentText(
                    keyName: 'rest_period',
                    controller: _periodEdtController,
                    isEnable: true,
                    textInputType: TextInputType.number),
                _buildContentText(
                    keyName: 'error_late',
                    controller: _errorLateEdtController,
                    isEnable: true,
                    textInputType: TextInputType.number),
                _buildContentText(
                    keyName: 'error_early',
                    controller: _errorEarlyEdtController,
                    isEnable: true,
                    textInputType: TextInputType.number),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 20),
                ),
                TKButton(Utils.getString(context, txt_save),
                    enable: _enableUpdateButton,
                    width: double.infinity, onPress: () {
                  FocusScope.of(context).unfocus();
                  if (widget.type.contains('update'))
                    _update();
                  else
                    _addData();
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
  }

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
            boxTitle(context, widget.genRow[keyName]['name']),
            TextFieldCustom(
                controller: controller,
                enable: isEnable,
                imgLeadIcon: icon,
                expandMultiLine: isExpand,
                hintText: hintText,
                textCapitalization: textCapitalization,
                textInputType: textInputType,
                onClear: onClear,
                onChange: (value) {
                  if (widget.type.contains('update'))
                    setState(() {
                      _enableUpdateButton = true;
                    });
                },
                clearText: clearText),
          ],
        ),
      ),
    );
  }
}
