import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:network_to_file_image/network_to_file_image.dart';

class BottomAppBarItemCustom {
  BottomAppBarItemCustom({this.iconData, this.text});

  String iconData;
  String text;
}

class BottomAppBarCustom extends StatefulWidget {
  BottomAppBarCustom(
      {this.items,
      this.centerItemText,
      this.height: 90.0,
      this.iconSize: 20.0,
      this.backgroundColor,
      this.color,
      this.selectedColor,
      this.notchedShape,
      this.onTabSelected,
      this.initCallback,
      this.selectedIndex});

  final List<BottomAppBarItemCustom> items;
  final String centerItemText;
  final double height;
  final double iconSize;
  final Color backgroundColor;
  final Color color;
  final Color selectedColor;
  final NotchedShape notchedShape;
  final Function(int selectedValue) onTabSelected;
  final int selectedIndex;
  final Function(BottomAppBarCustomState state) initCallback;

  @override
  State<StatefulWidget> createState() => BottomAppBarCustomState();
}

class BottomAppBarCustomState extends State<BottomAppBarCustom> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.initCallback(this);
  }

  updateIndex(int index) {
    widget.onTabSelected(index);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = List.generate(widget.items.length, (int index) {
      return _buildTabItem(
        item: widget.items[index],
        index: index,
        onPressed: updateIndex,
      );
    });
    items.insert(items.length >> 1, _buildMiddleTabItem());

    return BottomAppBar(
      shape: widget.notchedShape,
      notchMargin: Utils.resizeHeightUtil(context, 12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items,
        ),
      ),
      color: widget.backgroundColor,
    );
  }

  Widget _buildMiddleTabItem() {
    return Expanded(
      child: SizedBox(
        height: Utils.resizeHeightUtil(context, widget.height),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: widget.iconSize),
            SizedBox(
              height: Utils.resizeHeightUtil(context, 10),
            ),
            TKText(
              widget.centerItemText,
              tkFont: TKFont.SFProDisplayMedium,
              style: TextStyle(
                  fontSize: Utils.resizeWidthUtil(context, 22),
                  color: widget.color),)
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    BottomAppBarItemCustom item,
    int index,
    ValueChanged<int> onPressed,
  }) {
    Color color = _selectedIndex == index ? widget.selectedColor : widget.color;
    return Expanded(
      child: SizedBox(
        height: Utils.resizeHeightUtil(context, widget.height),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => onPressed(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: widget.iconSize,
                  child: ImageIcon(
                      NetworkToFileImage(
                        url: item.iconData,
                        file: Utils().fileFromDocsDir(
                            'main-menu${item.iconData.split('/').last}'),
                      ),
                      color: color,
                      size: Utils.resizeWidthUtil(context, 40)),
                ),
                SizedBox(
                  height: Utils.resizeHeightUtil(context, 10),
                ),
                TKText(
                  item.text,
                  tkFont: TKFont.SFProDisplayMedium,
                  style: TextStyle(
                      fontSize: Utils.resizeWidthUtil(context, 22),
                      color: color),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
