import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class TKTitleEditCard extends StatefulWidget {
  final EdgeInsets margin;
  final double borderRadius;
  final TextEditingController controller;
  final String errMess;
  final String title;
  final bool isValidate;
  final bool obscureText;
  final RegExp regExp;
  final bool enable;
  final String hintText;

  TKTitleEditCard(this.controller,
      {this.margin,
      this.borderRadius = 7.0,
      this.errMess = 'error',
      this.title,
      this.isValidate = false,
      this.obscureText = false,
      this.regExp,
      this.enable = true,
      this.hintText = '',
      Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TKTitleEditCardState();
  }
}

class TKTitleEditCardState extends State<TKTitleEditCard> {
  FocusNode _focus = FocusNode();

  bool _isFocus = false;
  bool _isValidate = true;
  bool _isFirstTime = true;
  bool _isTyping = false;
  String _errMess = '';

  bool get isValidate => _isValidate;

  @override
  void initState() {
    super.initState();
    if (widget.controller.text != '') {
      checkValidate();
    }
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.clear();
    widget.controller.dispose();
    _isFocus = false;
    _isValidate = false;
    _isFirstTime = true;
    _isTyping = false;
    _errMess = '';
  }

  void _onFocusChange() {
    setState(() {
      if (_focus.hasFocus) {
        _isFocus = true;
      } else {
        _isFocus = false;
        if (widget.isValidate) {
          checkValidate();
        }
      }
    });
  }

  checkValidate() {
    if (widget.isValidate) {
      setState(() {
        if (widget.controller.text.isEmpty) {
          _isValidate = false;
          _errMess = Utils.getString(context, txt_text_field_empty);
        } else if (widget.regExp != null &&
            !widget.regExp.hasMatch(widget.controller.text.trim())) {
          _isValidate = false;
          _errMess = widget.errMess;
        } else {
          _isValidate = true;
          _errMess = 'Correct check';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Container(
              padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 10)),
              margin: widget.margin,
              decoration: BoxDecoration(
                  border: getBorderDecor(),
                  borderRadius:
                      BorderRadius.all(Radius.circular(widget.borderRadius))),
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: Utils.resizeHeightUtil(context, 20),
                    alignment: Alignment.centerLeft,
                    child: TKText(
                      Utils.getString(context, widget.title),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: Utils.resizeHeightUtil(context, 20) * 0.78,
                      ),
                    ),
                  ),
                  SizedBox(height: Utils.resizeHeightUtil(context, 5)),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: Utils.resizeHeightUtil(context, 33),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                              onTap: () {
                                setState(() {
                                  _isFocus = true;
                                  _errMess = '';
                                  _isFirstTime = false;
                                });
                              },
                              onChanged: (value) => {
                                    setState(() {
                                      _isTyping = value != '';
                                    })
                                  },
                              controller: widget.controller,
                              focusNode: _focus,
                              enabled: widget.enable,
                              obscureText: widget.obscureText,
                              style: TextStyle(
                                fontFamily: "Sarabun-SemiBold",
                                fontSize: Utils.resizeHeightUtil(context, 20),
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 10),
                              )),
                          flex: 1,
                        ),
                        getIcon()
                      ],
                    ),
                  )
                ],
              ),
            )),
        _errMess.isEmpty
            ? Container()
            : Container(
                height: Utils.resizeHeightUtil(context, 20),
                padding: EdgeInsets.only(right: 10, left: 10),
                alignment: Alignment.centerLeft,
                child: _isValidate
                    ? LayoutBuilder(
                        builder: (context, constraint) {
                          return TKText(
                            _errMess,
                            style: TextStyle(
                                color: button_login_on_boarding_start,
                                fontSize: constraint.maxHeight * 0.6),
                          );
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraint) {
                          return TKText(
                            _errMess,
                            style: TextStyle(
                                color: error_color,
                                fontSize: constraint.maxHeight * 0.6),
                          );
                        },
                      ),
              )
      ],
    );
  }

  getBorderDecor() {
    if (_isFirstTime) {
      return Border();
    } else {
      if (_isFocus) {
        return Border.all(color: button_login_on_boarding_start);
      } else {
        if (widget.isValidate) {
          if (!_isValidate) {
            return Border.all(color: Colors.red);
          }
        } else {
          return Border();
        }
      }
    }
  }

  getIcon() {
    if (_isFirstTime && widget.controller.text == '') {
      return Container();
    } else {
      if (_isFocus) {
        if (_isTyping) {
          return GestureDetector(
            onTap: () {
              widget.controller.text = '';
            },
            child: Icon(
              Icons.cancel,
              size: 20,
            ),
          );
        } else {
          return Container();
        }
      } else {
        if (widget.isValidate) {
          if (_isValidate) {
            return Icon(
              Icons.check_circle,
              size: 20,
              color: button_login_on_boarding_start,
            );
          } else {
            return Icon(
              Icons.cancel,
              size: 20,
              color: Colors.red,
            );
          }
        } else {
          return Container();
        }
      }
    }
  }
}
