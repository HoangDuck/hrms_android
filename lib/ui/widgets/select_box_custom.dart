import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/constants/text_styles.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';

class SelectBoxCustom extends StatefulWidget {
  final String title;
  final List<dynamic> data;
  final int selectedItem;
  final Function(int itemSelected) callBack;
  final Function clearCallback;
  final String valueKey;
  final bool forceError;

  const SelectBoxCustom(
      {Key key,
      this.data,
      this.callBack,
      this.title,
      this.selectedItem,
      @required this.valueKey,
      this.clearCallback,
      this.forceError = false})
      : super(key: key);

  @override
  _SelectBoxCustomState createState() => _SelectBoxCustomState();
}

class _SelectBoxCustomState extends State<SelectBoxCustom> {
  int _itemSelected = 0;
  FixedExtentScrollController scrollController;

  showSelectBox(BuildContext context, List<dynamic> data,
      FixedExtentScrollController scrollController) {
    _itemSelected = widget.selectedItem;
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Utils.resizeWidthUtil(context, 30)),
                  topRight:
                      Radius.circular(Utils.resizeWidthUtil(context, 30)))),
          child: CupertinoPicker(
            scrollController: scrollController,
            backgroundColor: Colors.transparent,
            itemExtent: Utils.resizeHeightUtil(context, 100),
            onSelectedItemChanged: (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _itemSelected = value;
              });
            },
            children: [
              ...data
                  .map((value) => Container(
                        alignment: Alignment.center,
                        child: TKText(
                            widget.valueKey == null
                                ? value.toString()
                                : (value[widget.valueKey]) is String
                                    ? value[widget.valueKey]
                                    : value[widget.valueKey]['v'],
                            tkFont: TKFont.SFProDisplayRegular,
                            style: normalTextStyle,
                            textAlign: TextAlign.center),
                      ))
                  .toList()
            ],
          ),
        );
      },
    ).then((onValue) {
      if (widget.callBack != null) {
        widget.callBack(_itemSelected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.length > 0) {
      scrollController =
          FixedExtentScrollController(initialItem: widget.selectedItem);
    }
    return GestureDetector(
      onTap: () => showSelectBox(context, widget.data, scrollController),
      child: Column(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: widget.forceError ? Colors.red : border_text_field),
                borderRadius:
                BorderRadius.circular(Utils.resizeWidthUtil(context, 10))),
            padding: EdgeInsets.symmetric(
                horizontal: Utils.resizeWidthUtil(context, 10)),
            height: Utils.resizeHeightUtil(context, 90),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TKText(
                    widget.title ?? '',
                    tkFont: TKFont.SFProDisplayRegular,
                    style: normalTextStyle,
                  ),
                ),
                widget.selectedItem != -1 && widget.clearCallback != null
                    ? GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      widget.clearCallback();
                    },
                    child: Icon(Icons.clear,
                        color: Colors.grey,
                        size: Utils.resizeWidthUtil(context, 30)))
                    : Container(),
                Icon(
                  Icons.arrow_drop_down,
                  size: Utils.resizeWidthUtil(context, 44),
                )
              ],
            ),
          ),
          Visibility(
            visible: widget.forceError,
            child: TKText(
              Utils.getString(context, txt_text_field_empty),
              tkFont: TKFont.SFProDisplaySemiBold,
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }
}
