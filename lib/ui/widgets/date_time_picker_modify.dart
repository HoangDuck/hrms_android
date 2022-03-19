import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/widgets/text_field_custom.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class DateTimePickerCustomModify extends StatefulWidget {
  final TextEditingController controller;
  final Function(DateTime datePicked, TimeOfDay timePicked) callBack;
  final DateTime initialDate;
  final TimeOfDay initialTime;
  final DateTime firstDate;
  final bool isShowMonth;
  final bool isShowDateOnly;
  final bool isShowTimeOnly;
  final String subText;

  const DateTimePickerCustomModify(
      {Key key,
      this.controller,
      this.callBack,
      this.initialDate,
      this.firstDate,
      this.isShowMonth = false,
      this.isShowDateOnly = false,
      this.isShowTimeOnly = false,
      this.subText = '',
      this.initialTime})
      : super(key: key);

  @override
  _DateTimePickerCustomModifyState createState() =>
      _DateTimePickerCustomModifyState();
}

class _DateTimePickerCustomModifyState
    extends State<DateTimePickerCustomModify> {
  final dateTimeFormat = DateFormat("HH:mm dd/MM/yyyy");

  DateTime _date = DateTime.now();

  showDateTimePicker(BuildContext context) async {
    final DateTime pickedDate = await showDatePicker(
        context: context,
        initialDate: widget.initialDate,
        firstDate: widget.firstDate,
        lastDate: DateTime(2050));
    if (pickedDate != null && pickedDate != widget.initialDate) {
      setState(() {
        _date = pickedDate;
      });
    }

    final TimeOfDay pickedTime =
        await showTimePicker(context: context, initialTime: widget.initialTime);
    if (pickedTime != null) {
      setState(() {
        widget.callBack(_date, pickedTime);
      });
    }
  }

  showMonthTimePicker(BuildContext context) async {
    final DateTime pickedMonth = await showMonthPicker(
        context: context,
        firstDate: widget.firstDate,
        lastDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        initialDate: widget.initialDate);

    if (pickedMonth != null) {
      setState(() {
        widget.callBack(pickedMonth, null);
      });
    }
  }

  showDateOnlyPicker(BuildContext context) async {
    final DateTime pickedDateOnly = await showDatePicker(
        context: context,
        initialDate: widget.initialDate,
        firstDate: widget.firstDate,
        lastDate: DateTime(2050));

    if (pickedDateOnly != null) {
      setState(() {
        widget.callBack(pickedDateOnly, null);
      });
    }
  }

  showTimeOnlyPicker(BuildContext context) async {
    final TimeOfDay pickedTimeOnly =
        await showTimePicker(context: context, initialTime: widget.initialTime);

    if (pickedTimeOnly != null) {
      setState(() {
        widget.callBack(null, pickedTimeOnly);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.isShowMonth
          ? showMonthTimePicker(context)
          : widget.isShowDateOnly
              ? showDateOnlyPicker(context)
              : widget.isShowTimeOnly
                  ? showTimeOnlyPicker(context)
                  : showDateTimePicker(context),
      child: TextFieldCustom(
          subText: widget.subText,
          isTimePick: true,
          controller: widget.controller,
          imgLeadIcon: ic_calendar,
          enable: false),
    );
  }
}
