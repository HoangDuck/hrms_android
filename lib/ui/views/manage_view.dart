import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';

class ManageView extends StatefulWidget {
  final data;

  ManageView(this.data);

  @override
  _ManageViewState createState() => _ManageViewState();
}

class _ManageViewState extends State<ManageView> {
  List<dynamic> _listData = [];
  List<dynamic> _listDataShow = [];
  bool _loading = false;
  TextEditingController _searchEdtController = TextEditingController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<String> refreshList() async {
    getData();
    return 'success';
  }

  void getData() async {
    _listData.clear();
    setState(() {
      _loading = true;
    });
    var response = await BaseViewModel().callApis(
        widget.data['dataRequest'] == '' ? {} : widget.data['dataRequest'],
        widget.data['url'],
        method_post,
        shouldSkipAuth: false,
        isNeedAuthenticated: true);
    if (response.status.code == 200)
      setState(() {
        _listData.addAll(response.data['data']);
        _listDataShow = _listData;
        _loading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarCustom(context, () => Navigator.pop(context), () {},
          widget.data['title'], null),
      body: RefreshIndicator(
        onRefresh: () => refreshList(),
        key: _refreshIndicatorKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Utils.resizeWidthUtil(context, 30),
                  vertical: Utils.resizeWidthUtil(context, 10)),
              child: TextFieldCustom(
                enable: true,
                expandMultiLine: false,
                controller: _searchEdtController,
                hintText: 'Tìm kiếm',
                onChange: (value) {
                  setState(() {
                    _listDataShow = _listData.where((item) {
                      return item["title"]['v']
                          .toLowerCase()
                          .contains(value.toLowerCase());
                    }).toList();
                  });
                },
              ),
            ),
            Expanded(
              child: _listDataShow.length == 0
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
                  : ListView.builder(
                      itemCount: _listDataShow.length,
                      itemBuilder: (context, index) {
                        return item(index);
                      }),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Navigator.pushNamed(context, widget.data['routerAdd'], arguments: {
            'type': 'add',
            'appbarTitle': widget.data['titleAdd'],
            'data': _listData,
          }).then((value) {
            if (value != null && value) getData();
          });
        },
        backgroundColor: only_color,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget item(int index) => Card(
        margin: EdgeInsets.symmetric(
            horizontal: Utils.resizeWidthUtil(context, 30),
            vertical: Utils.resizeWidthUtil(context, 10)),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            Navigator.pushNamed(context, widget.data['routerUpdate'],
                arguments: {
                  "type": 'update',
                  'data': _listData,
                  'appbarTitle': widget.data['titleUpdate'],
                  'dataItem': _listDataShow[index]
                }).then((value) {
              if (value != null && value) getData();
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
                      Image.network(avatarUrl + widget.data['icon'],
                          width: Utils.resizeWidthUtil(context, 50),
                          height: Utils.resizeWidthUtil(context, 50)),
                      SizedBox(
                        width: Utils.resizeWidthUtil(context, 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TKText(
                              '${_listDataShow[index]['title']['v']} ' +
                                  (_listDataShow[index]['subtitle']['v'] != ''
                                      ? '(${_listDataShow[index]['subtitle']['v']})'
                                      : ''),
                              tkFont: TKFont.SFProDisplayRegular,
                              maxLines: 3,
                              style: TextStyle(
                                  color: txt_grey_color_v3,
                                  fontSize: Utils.resizeWidthUtil(context, 30)),
                            ),
                            if (_listDataShow[index]['description']['v'] != '')
                              TKText(
                                '${_listDataShow[index]['description']['v']}',
                                tkFont: TKFont.SFProDisplayRegular,
                                style: TextStyle(
                                    color: txt_grey_color_v1,
                                    fontSize:
                                        Utils.resizeWidthUtil(context, 26)),
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
}
