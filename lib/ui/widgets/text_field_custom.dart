import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class TextFieldCustom extends StatefulWidget {
  final TextEditingController controller;
  final String imgLeadIcon;
  final String hintText;
  final String subText;
  final bool expandMultiLine;
  final bool enable;
  final bool obscureText;
  final bool forceError;
  final int maxLine;
  final Function onSpeechPress;
  final bool isTimePick;
  final Function(String changeValue) onChange;
  final Function(String onSubmit) onSubmit;
  final TextInputType textInputType;
  final TextCapitalization textCapitalization;
  final bool clearText;
  final Function onClear;
  final bool isShowSuffix;
  final Function onSuffixChange;

  const TextFieldCustom(
      {Key key,
      this.expandMultiLine = false,
      this.imgLeadIcon,
      this.controller,
      this.enable = true,
      this.obscureText = false,
      this.hintText,
      this.maxLine = -1,
      this.forceError = false,
      this.isTimePick = false,
      this.subText = '',
      this.onSpeechPress,
      this.onChange,
      this.onSubmit,
      this.textInputType = TextInputType.text,
      this.textCapitalization = TextCapitalization.none,
      this.clearText = false,
      this.onClear,
      this.isShowSuffix = false,
      this.onSuffixChange})
      : super(key: key);

  @override
  _TextFieldCustomState createState() => _TextFieldCustomState();
}

class _TextFieldCustomState extends State<TextFieldCustom> {
  FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        if (widget.onChange != null) {
          widget.onChange(widget.controller.text);
        }
      }
    });
  }

  @override
  void didUpdateWidget(TextFieldCustom oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
            decoration: BoxDecoration(
                color: widget.enable
                    ? Colors.white
                    : widget.isTimePick
                        ? Colors.white
                        : Colors.grey.withOpacity(0.1),
                border: Border.all(
                    color: widget.forceError ? Colors.red : border_text_field),
                borderRadius:
                    BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
            padding: EdgeInsets.symmetric(
                horizontal: Utils.resizeHeightUtil(context, 20)),
            width: MediaQuery.of(context).size.width,
            height: Utils.resizeHeightUtil(
                context, widget.expandMultiLine ? 164 : 100),
            child: Row(
              crossAxisAlignment: widget.expandMultiLine
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: TextField(
                      onChanged: (changeValue) {
                        if (widget.onChange != null) {
                          widget.onChange(changeValue);
                        }
                      },
                      onEditingComplete: () {
                        Utils.closeKeyboard(context);
                      },
                      onSubmitted: (value) {
                        widget.onSubmit(value);
                      },
                      minLines: 1,
                      maxLines: widget.maxLine == -1 ? null : 1,
                      controller: widget.controller,
                      textCapitalization: widget.textCapitalization,
                      focusNode: _focus,
                      enabled: widget.enable,
                      obscureText: widget.obscureText,
                      keyboardType: widget.textInputType,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                          height: Utils.resizeHeightUtil(context, 2),
                          color: txt_grey_color_v3,
                          fontSize: Utils.resizeWidthUtil(context, 30),
                          fontFamily: "SFProDisplay-Regular"),
                      decoration: InputDecoration(
                        prefixIcon: widget.imgLeadIcon != null
                            ? Container(
                                padding: EdgeInsets.symmetric(
                                    vertical:
                                        Utils.resizeHeightUtil(context, 15)),
                                child: Image.asset(widget.imgLeadIcon,
                                    width: Utils.resizeWidthUtil(context, 40),
                                    height: Utils.resizeWidthUtil(context, 40)),
                              )
                            : null,
                        suffixIcon: widget.isShowSuffix
                            ? IconButton(
                                icon: !widget.obscureText
                                    ? Icon(
                                        Icons.visibility,
                                        color:
                                            Theme.of(context).primaryColorDark,
                                      )
                                    : Icon(
                                        Icons.visibility_off,
                                        color: txt_grey_color_v1,
                                      ),
                                onPressed: widget.onSuffixChange,
                              )
                            : null,
                        focusColor: txt_grey_color_v3,
                        hintText: widget.hintText ?? '',
                        hintStyle: normalTitleGreyTextStyle.merge(TextStyle(
                            color: txt_grey_color_v3.withOpacity(0.7))),
                        border: InputBorder.none,
                      )),
                ),
                widget.subText != ''
                    ? Container(
                        padding: EdgeInsets.only(
                            left: Utils.resizeWidthUtil(context, 15)),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey, width: 1.0),
                          ),
                        ),
                        child: TKText(
                            '${widget.subText} ${Utils.getString(context, txt_title_register_late_early_header_minute)}',
                            style: TextStyle(
                                height: Utils.resizeHeightUtil(context, 2),
                                color: txt_grey_color_v3,
                                fontSize: Utils.resizeWidthUtil(context, 30),
                                fontFamily: "SFProDisplay-Regular")),
                      )
                    : Container(),
                widget.onSpeechPress != null
                    ? Wrap(children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(
                              top: Utils.resizeWidthUtil(context, 20)),
                          child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => widget.onSpeechPress(),
                              child: Image.asset(ic_microphone,
                                  width: Utils.resizeWidthUtil(context, 40),
                                  height: Utils.resizeHeightUtil(context, 40))),
                        )
                      ])
                    : Container(),
                if (widget.clearText)
                  GestureDetector(
                      onTap: () => widget.onClear(),
                      child: Icon(
                        Icons.clear,
                        color: txt_grey_color_v1,
                      ))
              ],
            )),
        SizedBox(height: Utils.resizeHeightUtil(context, 5)),
        Visibility(
          visible: widget.forceError,
          child: TKText(
            Utils.getString(context, txt_text_field_empty),
            tkFont: TKFont.SFProDisplaySemiBold,
            style: TextStyle(color: Colors.red),
          ),
        )
      ],
    );
  }
}
