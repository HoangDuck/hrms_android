class StatusResponse {
  int code;
  String message;

  StatusResponse({this.code, this.message});

  StatusResponse.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      code = json['code'];
      message = json['message'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['message'] = this.message;
    return data;
  }
}
