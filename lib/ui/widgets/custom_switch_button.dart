library custom_switch;

import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class CustomSwitchButton extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final String textActive;
  final String textInActive;
  final Color colorActive;
  final Color colorInactive;
  final double sizeActive;
  final double sizeInActive;
  final double width;
  final double height;
  final bool enable;

  const CustomSwitchButton(
      {Key key,
      this.value,
      this.onChanged,
      this.activeColor,
      this.width,
      this.height,
      this.colorActive = Colors.white,
      this.colorInactive = Colors.white,
      this.sizeActive = 15,
      this.sizeInActive = 15,
      this.textActive = 'ON',
      this.textInActive = 'OFF',
      this.enable = true})
      : super(key: key);

  @override
  _CustomSwitchButtonState createState() => _CustomSwitchButtonState();
}

class _CustomSwitchButtonState extends State<CustomSwitchButton>
    with SingleTickerProviderStateMixin {
  Animation _circleAnimation;
  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 60));
    _circleAnimation = AlignmentTween(
            begin: widget.value ? Alignment.centerRight : Alignment.centerLeft,
            end: widget.value ? Alignment.centerLeft : Alignment.centerRight)
        .animate(CurvedAnimation(
            parent: _animationController, curve: Curves.linear));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            if(widget.enable) {
              if (_animationController.isCompleted) {
                _animationController.reverse();
              } else {
                _animationController.forward();
              }
              _circleAnimation.value == Alignment.centerLeft
                  ? widget.onChanged(true)
                  : widget.onChanged(false);
            }
          },
          child: Container(
            width: widget.width != null
                ? widget.width
                : Utils.resizeWidthUtil(context, 70),
            height: widget.height != null
                ? widget.height
                : Utils.resizeHeightUtil(context, 50),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: _circleAnimation.value == Alignment.centerLeft
                    ? Colors.grey
                    : widget.activeColor),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 4.0, bottom: 4.0, right: 4.0, left: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _circleAnimation.value == Alignment.centerRight
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                          child: TKText(
                            widget.textActive,
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                color: widget.colorActive,
                                fontSize: widget.sizeActive),
                          ),
                        )
                      : Container(),
                  Align(
                    alignment: _circleAnimation.value,
                    child: Container(
                      width: 25.0,
                      height: 25.0,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: Colors.white),
                    ),
                  ),
                  _circleAnimation.value == Alignment.centerLeft
                      ? Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 5.0),
                          child: TKText(
                            widget.textInActive,
                            tkFont: TKFont.SFProDisplayRegular,
                            style: TextStyle(
                                color: widget.colorInactive,
                                fontSize: widget.sizeInActive),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
