import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class SelectBoxCustomUtil extends StatefulWidget {
  final String title;
  final List<dynamic> data;
  final int selectedItem;
  final Function(dynamic itemSelected) callBack;
  final Function(SelectBoxCustomUtilState state) loadMoreCallback;
  final Function(String value, SelectBoxCustomUtilState state) searchCallback;
  final Function(SelectBoxCustomUtilState state) initCallback;
  final Function clearCallback;
  final bool enable;
  final bool enableSearch;
  final bool clearShow;

  const SelectBoxCustomUtil(
      {Key key,
      this.data,
      this.callBack,
      this.title,
      this.selectedItem,
      this.searchCallback,
      this.initCallback,
      this.clearCallback,
      this.loadMoreCallback,
      this.enable = true,
      this.enableSearch = true,
      this.clearShow = false})
      : super(key: key);

  @override
  SelectBoxCustomUtilState createState() => SelectBoxCustomUtilState();
}

class SelectBoxCustomUtilState extends State<SelectBoxCustomUtil> {
  ScrollController _controller;

  List<dynamic> dataList;

  StateSetter state;

  TextEditingController _searchController = TextEditingController();

  bool _forceErrorSearch = false;

  dynamic data;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(() => _scrollListener());
    dataList = widget.data;
  }

  _scrollListener() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent) {
      widget.loadMoreCallback(this);
    }
  }

  updateDataList(List<dynamic> data) {
    state(() {
      dataList = data;
    });
  }

  clearData() {
    if (mounted)
      setState(() {
        data = null;
      });
  }

  showSelectBox(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          state = setState;
          return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft:
                            Radius.circular(Utils.resizeWidthUtil(context, 30)),
                        topRight: Radius.circular(
                            Utils.resizeWidthUtil(context, 30)))),
                child: Column(
                  children: <Widget>[
                    if (widget.enableSearch)
                      Container(
                        padding:
                            EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
                        child: TextFieldCustom(
                            controller: _searchController,
                            forceError: _forceErrorSearch,
                            onChange: (changeValue) =>
                                widget.searchCallback(changeValue, this)),
                      ),
                    Expanded(
                      child: ListView.builder(
                          itemCount: dataList.length,
                          controller: _controller,
                          itemBuilder: (BuildContext ctx, int index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  data = dataList[index];
                                });
                                widget.callBack(data);
                                _searchController.text = '';
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical:
                                        Utils.resizeHeightUtil(context, 40)),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: txt_grey_color_v3
                                                .withOpacity(0.2)))),
                                child: TKText(dataList[index]['name'],
                                    tkFont: TKFont.SFProDisplayRegular,
                                    style: normalTextStyle,
                                    textAlign: TextAlign.center),
                              ),
                            );
                          }),
                    )
                  ],
                ),
              ));
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.initCallback(this);
        if (widget.enable) showSelectBox(context);
      },
      child: Container(
        decoration: BoxDecoration(
            color: widget.enable ? Colors.white : disabled_color,
            border: Border.all(color: border_text_field),
            borderRadius:
                BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
        padding: EdgeInsets.symmetric(
            horizontal: Utils.resizeWidthUtil(context, 10)),
        height: Utils.resizeHeightUtil(context, 90),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TKText(
                data != null ? data['name'] : widget.title,
                tkFont: TKFont.SFProDisplayRegular,
                style: normalTextStyle,
              ),
            ),
            data != null || widget.clearShow
                ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.clearCallback();
                      setState(() {
                        data = null;
                      });
                    },
                    child: Icon(Icons.clear,
                        color: Colors.grey,
                        size: Utils.resizeWidthUtil(context, 30)))
                : Container(),
            Icon(Icons.arrow_drop_down,
                size: Utils.resizeWidthUtil(context, 44))
          ],
        ),
      ),
    );
  }
}
