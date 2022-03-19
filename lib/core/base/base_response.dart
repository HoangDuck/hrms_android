import 'package:flutter/cupertino.dart';
import 'package:gsot_timekeeping/core/models/status_response.dart';

class BaseResponse extends ChangeNotifier {
  dynamic data;
  StatusResponse status;

  BaseResponse({this.data, this.status});

  BaseResponse.fromJson(Map<String, dynamic> json) {
    data = json['data'];
    status = StatusResponse.fromJson(json['status']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['data'] = this.data;
    data['status'] = this.status;
    return data;
  }

  addData(dynamic data) {
    this.data = data;
    notifyListeners();
  }
}
