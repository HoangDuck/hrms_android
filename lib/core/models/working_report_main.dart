import 'package:flutter/widgets.dart';

class WorkingReportMain extends ChangeNotifier {
  String startTimeKeeping;
  String endTimeKeeping;
  String salaryWorkDay;
  String totalWorkday;

  WorkingReportMain(
      {this.startTimeKeeping,
      this.endTimeKeeping,
      this.salaryWorkDay,
      this.totalWorkday});

  WorkingReportMain.fromJson(Map<String, dynamic> json) {
    startTimeKeeping = json['startTimeKeeping'];
    endTimeKeeping = json['endTimeKeeping'];
    salaryWorkDay = json['salaryWorkDay'];
    totalWorkday = json['totalWorkday'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['startTimeKeeping'] = this.startTimeKeeping;
    data['endTimeKeeping'] = this.endTimeKeeping;
    data['salaryWorkDay'] = this.salaryWorkDay;
    data['totalWorkday'] = this.totalWorkday;
    return data;
  }
}
