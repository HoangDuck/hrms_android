import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_value.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';

class DateTimePickerCustom extends StatefulWidget {
  final TextEditingController controller;
  final bool isStart;
  final Function(DateTime itemSelected) callBack;
  final DateTime minTime;

  const DateTimePickerCustom(
      {Key key,
      this.controller,
      this.isStart = false,
      this.callBack,
      this.minTime})
      : super(key: key);

  @override
  _DateTimePickerCustomState createState() => _DateTimePickerCustomState();
}

class _DateTimePickerCustomState extends State<DateTimePickerCustom> {
  DateTime _dateTimePicker;

  showDateTimePicker(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Container(
            height: 200,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft:
                        Radius.circular(Utils.resizeWidthUtil(context, 10)),
                    topRight:
                        Radius.circular(Utils.resizeWidthUtil(context, 10)))),
            child: CupertinoDatePicker(
                initialDateTime:
                    widget.minTime != null && widget.minTime.isAfter(now)
                        ? widget.minTime
                        : now,
                minimumDate: widget.minTime ?? now,
                maximumDate: DateTime(2050),
                backgroundColor: Colors.transparent,
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (dateTime) {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _dateTimePicker = dateTime;
                  });
                }));
      },
    ).then((onValue) {
      if (widget.callBack != null) {
        widget.callBack(_dateTimePicker);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDateTimePicker(context),
      child: TextFieldCustom(
          controller: widget.controller,
          imgLeadIcon: ic_calendar,
          enable: false),
    );
  }
}
