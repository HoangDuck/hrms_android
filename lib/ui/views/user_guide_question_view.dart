import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html/style.dart';
import 'package:gsot_timekeeping/core/base/base_view.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class UserGuideView extends StatefulWidget {

  final dynamic data;

  UserGuideView(this.data);

  @override
  _UserGuideViewState createState() => _UserGuideViewState();
}

class _UserGuideViewState extends State<UserGuideView> {
  List<dynamic> _listData = [];

  void getData(BuildContext context, BaseViewModel model) async {
    List<dynamic> _list = [];
    var response = await model.callApis({}, widget.data['type'] == 'guide' ? getUserGuideUrl : getQuestionUrl, method_post,
        isNeedAuthenticated: true, shouldSkipAuth: false);
    if (response.status.code == 200) {
      for (var list in response.data['data']) {
        if(widget.data['type'] == 'guide')
          _list.add({
            'ID': list['ID'],
            'name': list['Name']['v'],
            'description': list['Description']['v'],
            'content': list['Content']['v'],
            'fileAttach': list['FileAttach']['v']
          });
        else
          _list.add({
            'ID': list['ID'],
            'name': list['AskedName']['v'],
            'description': list['AskedDescription']['v'],
            'content': list['AskedContent']['v'],
            'fileAttach': list['FileAttach']['v']
          });
      }
      setState(() {
        _listData = _list;
      });
    } else
      showMessageDialogIOS(context,
          description: Utils.getString(context, txt_get_data_failed));
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<BaseViewModel>(
      model: BaseViewModel(),
      onModelReady: (model){
        getData(context, model);
      },
      builder: (context, model, child) => Scaffold(
        appBar: appBarCustom(context, () => Navigator.pop(context), () => {},
            widget.data['title'], null),
        body: ListView.builder(
          itemCount: _listData.length,
            itemBuilder: (context, index) {
              return ShowUserGuideView(title: _listData[index]['name'], content: _listData[index]['content'], type: widget.data['type'],);
            }
        ),
      ),
    );
  }
}

class ShowUserGuideView extends StatefulWidget {
  final dynamic data;
  final String title;
  final String content;
  final List<dynamic> genRowList;
  final String type;

  ShowUserGuideView({this.data, this.genRowList, this.title, this.content, this.type});

  @override
  _ShowUserGuideViewState createState() => _ShowUserGuideViewState();
}

class _ShowUserGuideViewState extends State<ShowUserGuideView>
    with TickerProviderStateMixin {
  bool _isShowDetail = false;

  AnimationController expandController;

  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _prepareAnimations();
  }

  void _runExpand() {
    if (_isShowDetail) {
      expandController.forward();
    } else {
      expandController.reverse();
    }
  }

  void _prepareAnimations() {
    expandController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    animation = CurvedAnimation(
      parent: expandController,
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          _isShowDetail = !_isShowDetail;
        });
        _runExpand();
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
        child: Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Row(
                    children: <Widget>[
                      Image.asset(widget.type == 'guide' ? ic_tutorial : ic_fqa,
                          width: Utils.resizeWidthUtil(context, 36),
                          height: Utils.resizeWidthUtil(context, 36)),
                      SizedBox(
                        width: Utils.resizeWidthUtil(context, 20),
                      ),
                      Expanded(
                        child: TKText(
                          widget.title,
                          tkFont: TKFont.SFProDisplayMedium,
                          maxLines: 2,
                          style: TextStyle(
                              color: txt_grey_color_v3,
                              fontSize: Utils.resizeWidthUtil(context, 30)),
                        ),
                      ),
                    ],
                  ),
                ),
                Image.asset(ic_arrow_forward,
                    width: Utils.resizeWidthUtil(context, 11),
                    height: Utils.resizeHeightUtil(context, 22))
              ],
            ),
            SizeTransition(
              axisAlignment: 1.0,
              sizeFactor: animation,
              child: Container(
                child: Html(
                  data: widget.content,
                  style: {
                    'html': Style(
                      color: txt_grey_color_v1
                    ),
                    'b': Style(
                        color: txt_grey_color_v2
                    ),
                  },
              )
            ))
          ],
        ),
      ),
    );
  }
}

