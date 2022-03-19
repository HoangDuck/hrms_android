class WifiInfo {
  String identifierForVendor;
  String nameForVendor;
  String androidId;
  String androidName;
  String wan;
  String lan;
  String wifiSSID;
  String wifiBSSID;

  WifiInfo(
      {this.identifierForVendor,
      this.nameForVendor,
      this.androidId,
      this.androidName,
      this.wan,
      this.lan,
      this.wifiSSID,
      this.wifiBSSID});

  WifiInfo.fromJson(Map<String, dynamic> json) {
    if (json != null) {
      identifierForVendor = json['identifierForVendor'] != null
          ? json['identifierForVendor']
          : "";
      nameForVendor = json['nameForVendor'] != null
          ? json['nameForVendor']
          : "";
      androidId = json['androidId'] != null ? json['androidId'] : "";
      androidName = json['androidName'] != null ? json['androidName'] : "";
      wan = json['wan'] != null ? json['wan'] : "";
      lan = json['lan'] != null ? json['lan'] : "";
      wifiSSID = json['wifiSSID'] != null ? json['wifiSSID'] : "";
      wifiBSSID = json['wifiBSSID'] != null ? json['wifiBSSID'] : "";
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['identifierForVendor'] = this.identifierForVendor;
    data['nameForVendor'] = this.nameForVendor;
    data['androidId'] = this.androidId;
    data['androidName'] = this.androidName;
    data['wan'] = this.wan;
    data['lan'] = this.lan;
    data['wifiSSID'] = this.wifiSSID;
    data['wifiBSSID'] = this.wifiBSSID;
    return data;
  }
}
