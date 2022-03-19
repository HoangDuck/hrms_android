import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/box_title.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class ManageEmployeeView extends StatefulWidget {
  final data;
  ManageEmployeeView(this.data);

  @override
  _ManageEmployeeViewState createState() => _ManageEmployeeViewState();
}

class _ManageEmployeeViewState extends State<ManageEmployeeView> {
  List<dynamic> _listEmployee = [];
  List<dynamic> _genderList = [];
  List<dynamic> _orgList = [];
  List<dynamic> _roleList = [];
  int currentIndex = 0;
  ScrollController controller;
  bool _showLoadMore = false;
  int _genderSelected = -1;
  dynamic _roleSelected;
  dynamic _orgSelected;
  String _filter = '';
  bool _loading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
  }

  _scrollListener(BaseViewModel model) {
    if (controller.position.pixels == controller.position.maxScrollExtent) {
      if (_listEmployee.length <
          int.parse(_listEmployee[0]['total_row']['v'])) {
        currentIndex += 10;
        getEmployee(model, currentIndex, isLoadMore: true);
      }
    }
  }

  Future<String> refreshList(BaseViewModel model) async {
    currentIndex = 0;
    _listEmployee.clear();
    getEmployee(model, currentIndex);
    return 'success';
  }

  void getEmployee(BaseViewModel model, int currentIndex,
      {bool isLoadMore = false, String searchText = ''}) async {
    if (isLoadMore) setState(() {_showLoadMore = true;});
    var response = await model.callApis({
      "current_index": currentIndex,
      "not_include": -1,
      "search_text": searchText,
      "filter": _filter
    }, employeeOwnerUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        if(!isLoadMore) _listEmployee.clear();
        _listEmployee.addAll(response.data['data']);
        _showLoadMore = false;
        _loading = false;
      });
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
      setState(() {
        _genderList = genderList;
      });
    } else {
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed),
          onPress: () => Navigator.pop(context));
    }
  }

  void getOrganize(BaseViewModel model,
      {String searchText = '',
      SelectBoxCustomUtilState state,
      StateSetter setModalState}) async {
    List<dynamic> _list = [];
    var response = await model.callApis({
      //'search_text': searchText,
    }, getDepartmentUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      for (var list in response.data['data'])
        _list.add({
          'id': list['ID'],
          'code': list['ma_org']['v'],
          'name': list['name']['v']
        });
    _orgList.addAll(_list);
    if (state != null) {
      state.updateDataList(_orgList);
    }
    setModalState(() {});
  }

  void getRole(BaseViewModel model, String orgID,
      {String searchText = '',
      SelectBoxCustomUtilState state,
      StateSetter setModalState}) async {
    List<dynamic> _list = [];
    var response = await model.callApis({
      'org_id': orgID,
      'search_text': searchText,
    }, orgRoleUrl, method_post,
        shouldSkipAuth: false, isNeedAuthenticated: true);
    if (response.status.code == 200)
      for (var list in response.data['data'])
        _list.add({
          'id': list['ID'],
          'code': list['role_id']['v'],
          'name': list['name_role']['v']
        });
    _roleList.addAll(_list);
    if (state != null) {
      state.updateDataList(_roleList);
    }
    setModalState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model) {
        controller.addListener(() => _scrollListener(model));
        getEmployee(model, currentIndex);
        getGender(model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(
            context,
            () => Navigator.pop(context),
            () => {
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
                            return _modalBottomSheet(setModalState, model);
                          })),
                    ),
                  )
                },
            widget.data['title'],
            Icons.sort),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 30),
                  vertical: Utils.resizeWidthUtil(context, 10)),
              child: TextFieldCustom(
                enable: true,
                expandMultiLine: false,
                hintText: 'Tìm kiếm',
                onChange: (value) {
                  if (value == '') {
                    currentIndex = 0;
                    _listEmployee.clear();
                    getEmployee(model, currentIndex, searchText: '');
                  }
                },
                onSubmit: (value) {
                  if (value != '') {
                    currentIndex = 0;
                    _listEmployee.clear();
                    _filter = '';
                    setState(() {
                      _loading = true;
                    });
                    getEmployee(model, currentIndex, searchText: value);
                  }
                },
              ),
            ),
            Expanded(
              child: _listEmployee.length == 0
                  ? Container(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                          child: _loading
                              ? CircularProgressIndicator()
                              : TKText(
                                  Utils.getString(
                                      context, txt_non_request_data),
                                  tkFont: TKFont.SFProDisplayRegular,
                                  style: TextStyle(
                                      color: txt_grey_color_v1,
                                      fontSize:
                                          Utils.resizeWidthUtil(context, 34)),
                                )))
                  : RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: () => refreshList(model),
                    child: DraggableScrollbar.semicircle(
                        labelTextBuilder: (offset) {
                          final int currentItem = controller.hasClients
                              ? (controller.offset /
                                      controller.position.maxScrollExtent *
                                      _listEmployee.length)
                                  .floor()
                              : 0;
                          return Text(
                            "${currentItem + 1}",
                            style: TextStyle(color: Colors.white),
                          );
                        },
                        controller: controller,
                        heightScrollThumb: Utils.resizeHeightUtil(context, 80),
                        backgroundColor: only_color,
                        child: ListView.builder(
                            itemCount: _listEmployee.length,
                            controller: controller,
                            itemBuilder: (context, index) {
                              return item(index, model);
                            }),
                      ),
                  ),
            ),
            if (_showLoadMore)
              Container(
                width: double.infinity,
                height: Utils.resizeHeightUtil(context, 100),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, Routers.editEmployeeOwner, arguments: {
              "type": 'add',
              'appbarTitle': widget.data['titleAdd']
            }).then((value) {
              if(value != null && value)
                getEmployee(model, 0);
            });
          },
          backgroundColor: only_color,
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  Widget item(int index, BaseViewModel model) => Card(
        margin: EdgeInsets.symmetric(
            horizontal: Utils.resizeWidthUtil(context, 30),
            vertical: Utils.resizeWidthUtil(context, 10)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.pushNamed(context, Routers.editEmployeeOwner, arguments: {
              "type": 'update',
              'data': _listEmployee,
              'appbarTitle': widget.data['titleUpdate'],
              'dataItem': _listEmployee[index]
            }).then((value) {
              if(value != null && value)
                getEmployee(model, 0);
            });
          },
          child: Container(
            padding: EdgeInsets.only(
                bottom: Utils.resizeHeightUtil(context, 20),
                left: Utils.resizeWidthUtil(context, 30),
                right: Utils.resizeWidthUtil(context, 30)),
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
              color: txt_grey_color_v3.withOpacity(0.2),
              width: Utils.resizeHeightUtil(context, 1),
            ))),
            margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: Utils.resizeWidthUtil(context, 100),
                        height: Utils.resizeWidthUtil(context, 100),
                        child: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: _listEmployee[index]['avatar']
                                        ['v'] !=
                                    ''
                                ? NetworkImage(
                                    '$avatarUrl${_listEmployee[index]['avatar']['v']}')
                                : AssetImage(avatar_default)),
                      ),
                      SizedBox(
                        width: Utils.resizeWidthUtil(context, 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TKText(
                              '${_listEmployee[index]['full_name']['v']} (${_listEmployee[index]['emp_id']['v']})',
                              tkFont: TKFont.SFProDisplayRegular,
                              maxLines: 3,
                              style: TextStyle(
                                  color: txt_grey_color_v3,
                                  fontSize: Utils.resizeWidthUtil(context, 30)),
                            ),
                            SizedBox(
                                height: Utils.resizeHeightUtil(context, 5)),
                            TKText(
                              '${_listEmployee[index]['name_role']['v']}',
                              tkFont: TKFont.SFProDisplayRegular,
                              style: TextStyle(
                                  color: txt_grey_color_v1,
                                  fontSize: Utils.resizeWidthUtil(context, 26)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: Utils.resizeWidthUtil(context, 10),
                      ),
                    ],
                  ),
                ),
                Image.asset(ic_arrow_forward,
                    width: Utils.resizeWidthUtil(context, 11),
                    height: Utils.resizeHeightUtil(context, 22))
              ],
            ),
          ),
        ),
      );

  Widget _modalBottomSheet(StateSetter setModalState, BaseViewModel model) {
    return Container(
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildContentSelectBoxGender(setModalState),
              boxTitle(context, 'Phòng ban'),
              _buildSelectOrganize(model, setModalState),
              boxTitle(context, 'Chức vụ'),
              _buildEmpPosition(model, setModalState),
              SizedBox(height: Utils.resizeHeightUtil(context, 30)),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TKButton(
                      Utils.getString(context, txt_find),
                      width: MediaQuery.of(context).size.width,
                      onPress: () async {
                        Navigator.of(context).pop();
                        currentIndex = 0;
                        if (_listEmployee.length > 0)
                          controller.animateTo(0.0,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        String genderFilter = _genderSelected == -1
                            ? ''
                            : 'AND sex = ${_genderList[_genderSelected]['id']}';
                        String orgFilter = _orgSelected == null
                            ? ''
                            : ' AND org_id = ${_orgSelected['id']}';
                        String roleFilter = _roleSelected == null
                            ? ''
                            : ' AND role_id = ${_roleSelected['id']}';
                        _filter = genderFilter + orgFilter + roleFilter;
                        setState(() {
                          _listEmployee.clear();
                          _loading = true;
                        });
                        getEmployee(model, currentIndex);
                      },
                    ),
                  ),
                  SizedBox(
                    width: Utils.resizeHeightUtil(context, 30),
                  ),
                  Expanded(
                    child: TKButton(
                      Utils.getString(context, txt_clear_find),
                      width: MediaQuery.of(context).size.width,
                      onPress: () {
                        setModalState(() {
                          _filter = '';
                          _roleSelected = null;
                          _orgSelected = null;
                          _genderSelected = -1;
                        });
                      },
                    ),
                  )
                ],
              ),
              SizedBox(
                height: Utils.resizeHeightUtil(context, 20),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildContentSelectBoxGender(StateSetter setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        boxTitle(context, Utils.getString(context, txt_gender)),
        SelectBoxCustom(
            valueKey: 'name',
            title: _genderList.length > 0
                ? _genderSelected == -1
                    ? 'Chọn'
                    : _genderList[_genderSelected]['name']
                : 'Chọn',
            data: _genderList,
            selectedItem: _genderSelected == -1 ? 0 : _genderSelected,
            clearCallback: () {
              setModalState(() {
                _genderSelected = -1;
              });
            },
            callBack: (itemSelected) => setModalState(() {
                  if (itemSelected != null) {
                    _genderSelected = itemSelected;
                  }
                })),
      ],
    );
  }

  Widget _buildSelectOrganize(BaseViewModel model, StateSetter setModalState) =>
      SelectBoxCustomUtil(
          title: _orgSelected == null ? 'Chọn phòng ban' : _orgSelected['name'],
          data: _orgList,
          selectedItem: 0,
          enableSearch: false,
          clearCallback: () {
            setModalState(() {
              _orgSelected = null;
            });
          },
          initCallback: (state) {
            _orgList.clear();
            getOrganize(model, state: state, setModalState: setModalState);
          },
          loadMoreCallback: (state) {},
          searchCallback: (value, state) {
//            if (value != '') {
//              Future.delayed(Duration(seconds: 2), () {
//                _orgList.clear();
//                getOrganize(model, searchText: value, state: state);
//              });
//            }
          },
          callBack: (itemSelected) {
            setModalState(() {
              _orgSelected = itemSelected;
            });
          });

  Widget _buildEmpPosition(BaseViewModel model, StateSetter setModalState) =>
      SelectBoxCustomUtil(
          title: _roleSelected == null ? 'Chọn chức vụ' : _roleSelected['name'],
          data: _roleList,
          selectedItem: 0,
          initCallback: (state) {
            getRole(model, '1 = 1', state: state, setModalState: setModalState);
          },
          loadMoreCallback: (state) {
            setModalState((){
              _roleSelected = null;
            });
          },
          clearCallback: () {
            setModalState(() {
              _roleSelected = null;
            });
          },
          searchCallback: (value, state) {
            if (value != '') {
              Future.delayed(Duration(seconds: 2), () {
                _roleList.clear();
                getRole(model, '1 = 1',
                    searchText: value,
                    state: state,
                    setModalState: setModalState);
              });
            }
          },
          callBack: (itemSelected) {
            setModalState(() {
              _roleSelected = itemSelected;
            });
          });
}
