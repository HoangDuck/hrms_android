import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

const _backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradient_end_color, gradient_start_color]));

const _scaleWidthValue = 20.0;
const _animationDuration = Duration(milliseconds: 100);

class OnBoardingView extends StatefulWidget {
  @override
  _OnBoardingViewState createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView>
    with TickerProviderStateMixin {
  int currentPageValue = 0;
  bool isScrolling = false;

  PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: 0);
  }

  @override
  dispose() {
    super.dispose();
  }

  void getChangedPageAndMoveBar(int page) {
    currentPageValue = page;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is UserScrollNotification) {
                setState(() {
                  isScrolling = true;
                });
              } else if (scrollInfo is ScrollEndNotification) {
                Future.microtask(() {
                  setState(() {
                    isScrolling = false;
                  });
                });
              }
              return true;
            },
            child: Stack(
              children: <Widget>[
                PageView.builder(
                  physics: ClampingScrollPhysics(),
                  itemCount: 3,
                  onPageChanged: (int page) {
                    getChangedPageAndMoveBar(page);
                  },
                  controller: controller,
                  itemBuilder: (context, index) {
                    return _pageItem(index);
                  },
                ),
                Positioned(
                  left: Utils.resizeWidthUtil(context, 33),
                  right: Utils.resizeWidthUtil(context, 33),
                  bottom: Utils.resizeHeightUtil(context, 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          for (int i = 0; i < 3; i++)
                            if (i == currentPageValue) ...[circleBar(true)] else
                              circleBar(false),
                        ],
                      ),
                      GestureDetector(
                        child: Container(
                            height: Utils.resizeHeightUtil(context, 82),
                            padding: EdgeInsets.all(currentPageValue != 2
                                ? Utils.resizeHeightUtil(context, 20)
                                : 0),
                            width: currentPageValue != 2
                                ? Utils.resizeHeightUtil(context, 82)
                                : Utils.resizeHeightUtil(context, 200),
                            decoration: BoxDecoration(
                              color: gradient_end_color,
                              borderRadius: BorderRadius.circular(
                                  Utils.resizeHeightUtil(context, 41)),
                            ),
                            child: currentPageValue < 2
                                ? Image.asset(ic_next)
                                : Center(
                                    child: TKText(
                                        Utils.getString(
                                            context, txt_get_started),
                                        style: TextStyle(color: Colors.white),
                                        tkFont: TKFont.BOLD))),
                        onTap: () async {
                          if (currentPageValue < 2) {
                            controller.animateToPage(currentPageValue + 1,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeIn);
                          } else {
                            Navigator.pushReplacementNamed(
                                context, Routers.chooseCompany);
                          }
                        },
                      )
                    ],
                  ),
                )
              ],
            )));
  }

  Widget circleBar(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      margin: EdgeInsets.symmetric(horizontal: 8),
      height: Utils.resizeWidthUtil(context, 20),
      width: isActive
          ? Utils.resizeWidthUtil(context, 44.95)
          : Utils.resizeWidthUtil(context, 20),
      decoration: BoxDecoration(
          color: isActive ? only_color : enable_color,
          borderRadius:
              BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
    );
  }

  Widget _pageItem(int index) => Stack(
        children: <Widget>[
          Container(
            decoration: _backgroundDecoration,
          ),
          Center(
            child: AnimatedContainer(
              alignment: Alignment.center,
              duration: _animationDuration,
              width: isScrolling
                  ? MediaQuery.of(context).size.width - _scaleWidthValue
                  : MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        height: Utils.resizeHeightUtil(context, 300),
                        child: Image.asset(
                          logo_hrms,
                          height: Utils.resizeHeightUtil(context, 101.06),
                          width: Utils.resizeWidthUtil(context, 182),
                        ),
                      ),
                      AnimatedContainer(
                        alignment: Alignment.bottomCenter,
                        duration: _animationDuration,
                        width: isScrolling
                            ? MediaQuery.of(context).size.width -
                                _scaleWidthValue
                            : MediaQuery.of(context).size.width,
                        height: Utils.resizeHeightUtil(context, 474),
                        child: index == 0
                            ? Image.asset(on_boarding)
                            : index == 1
                                ? Image.asset(on_boarding_2)
                                : Image.asset(on_boarding_3),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      height: Utils.resizeHeightUtil(context, 607),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(25.0),
                          topRight: const Radius.circular(25.0),
                        ),
                      ),
                      child: Container(),
                    ),
                  )
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: Utils.resizeHeightUtil(context, 774),
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: Utils.resizeHeightUtil(context, 30),
                  horizontal: Utils.resizeHeightUtil(context, 50)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  TKText(
                    Utils.getString(context, txt_onboarding_welcome),
                    style: TextStyle(
                        color: txt_blue,
                        fontSize: Utils.resizeWidthUtil(context, 48)),
                    tkFont: TKFont.SFProDisplayBold,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TKText(
                    index == 0
                        ? Utils.getString(context, txt_onboarding_title_1)
                        : index == 1
                            ? Utils.getString(context, txt_onboarding_title_2)
                            : Utils.getString(context, txt_onboarding_title_3),
                    style: TextStyle(
                        height: 1.5,
                        color: txt_black_color,
                        fontSize: Utils.resizeWidthUtil(context, 36)),
                    textAlign: TextAlign.center,
                    tkFont: TKFont.SFProDisplayBold,
                  ),
                  SizedBox(
                    height: 10,
                  ),
//                  TKText(
//                    'Chủ động quản lý thời gian làm việc linh hoạt, '
//                    'Chủ động quản lý thời gian làm việc linh hoạt,'
//                    'Chủ động quản lý thời gian làm việc linh hoạt',
//                    textAlign: TextAlign.center,
//                    style: TextStyle(
//                      height: 1.5,
//                      color: txt_grey_color_v1,
//                      fontSize: Utils.resizeWidthUtil(context, 32),
//                    ),
//                    tkFont: TKFont.SFProDisplayRegular,
//                  ),
                  SizedBox(height: Utils.resizeHeightUtil(context, 142)),
                ],
              ),
            ),
          ),
        ],
      );
}
