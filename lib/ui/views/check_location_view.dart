import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:math';
import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:gsot_timekeeping/core/enums/connectivity_status.dart';
import 'package:gsot_timekeeping/core/enums/timekeeping_type.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/api_constants.dart';
import 'package:gsot_timekeeping/core/services/connectivity_service.dart';
import 'package:gsot_timekeeping/core/services/timekeeping_backgroud_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/qrcode_scan_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/loading.dart';
import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _normalStyle = TextStyle(
    color: txt_black_color,
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
    fontFamily: 'SFProDisplay-Regular');

final _bigStyle = TextStyle(
    color: txt_black_color,
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 34),
    fontFamily: 'SFProDisplay-Regular');

final _blueStyle = TextStyle(
    color: txt_blue,
    fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
    fontFamily: 'SFProDisplay-Regular');

final _decoration = BoxDecoration(
  color: Colors.white,
  boxShadow: [
    BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 0,
        spreadRadius: 0,
        offset: Offset(0, 4)),
  ],
);

class CheckLocation extends StatefulWidget {
  final CameraArgument arguments;

  const CheckLocation(this.arguments);

  @override
  _CheckLocationState createState() => _CheckLocationState();
}

class _CheckLocationState extends State<CheckLocation> {
  DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  bool _isSubmitted = false;

  Position _currentLocation;

  double _distance;

  int _faceNumber = -1;

  List<dynamic> _placeList = [];

  Set<Marker> _marker = Set<Marker>();

  Set<Circle> _circle = Set<Circle>();

  int positionMinValue = 0;

  dynamic _timeDefineSelected;

  List<dynamic> _timeDefineList = [];

  File cropImages;

  bool reloadLocation = false;

  FaceDetector faceDetector =
  GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
  ));

  @override
  void initState() {
    super.initState();
    if (widget.arguments.distance != null) {
      _distance = widget.arguments.distance;
    }
    if (widget.arguments.timekeepingType == TimekeepingType.Face) _checkFace();
    Future.delayed(Duration(milliseconds: 0), () {
      if (widget.arguments.currentLocation != null)
        _currentLocation = widget.arguments.currentLocation;
      getLocationTimekeeping();
      getTimeDefine();
    });
  }

  _checkFace() async {
    /*bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    double ratio = widget.arguments.deviceBrand.contains('samsung') ? mediumFaceRatio : highFaceRatio;
    _cropImage(isAndroid, ratio);*/
    await faceDetector.processImage(InputImage.fromFilePath(widget.arguments.path.path)).then((faces) {
      setState(() {
        _faceNumber = faces.length;
      });
    });
  }

  _cropImage(bool isAndroid, double ratio,
      {bool rotation = false}) async {
    File image = new File(widget.arguments.path.path);
    var decodedImage = await decodeImageFromList(image.readAsBytesSync());
    int height = decodedImage.height > decodedImage.width
        ? decodedImage.height
        : decodedImage.width;
    int width = decodedImage.width > decodedImage.height
        ? decodedImage.height
        : decodedImage.width;
    var left = isAndroid
        ? (height - (width * ratio)) ~/ 2
        : (width * (1 - ratio)) ~/ 2;
    var top = isAndroid
        ? (width * (1 - ratio)) ~/ 2
        : (height - (width * ratio)) ~/ 2;
    var size = (width * ratio).toInt();
    if (mounted) {
      await FlutterNativeImage.cropImage(
          widget.arguments.path.path, rotation ? top : left, rotation ? left : top, size, size)
          .then((cropFile) async {
        if (cropFile != null && widget.arguments.path.path != null && File(widget.arguments.path.path).existsSync()) {
          cropImages = cropFile;
          await File(widget.arguments.path.path).delete();
        }
      }).catchError((onError) {
        debugPrint('Crop image error: $onError');
      });
    }
  }

  void getTimeDefine({SelectBoxCustomUtilState state}) async {
    var connectStatus = context.read<ConnectivityService>().status;
    if (connectStatus != ConnectivityStatus.Offline) {
      List<dynamic> _list = [];
      var response = await BaseViewModel().callApis(
          {'date': DateFormat('yyyy/MM/dd').format(DateTime.now())},
          timeDefineByEmployeeUrl,
          method_post,
          shouldSkipAuth: false,
          isNeedAuthenticated: true);
      if (response.status.code == 200) {
        for (var list in jsonDecode(response.data['data'][0]['Column1']['v']))
          _list.add({
            'id': list['status_working_id'],
            'name': list['time_name'],
            'time_id': list['time_id']
          });
        _timeDefineList = _list;
        _timeDefineSelected = _timeDefineList[0];
        if (state != null) {
          state.updateDataList(_timeDefineList);
        }
        setState(() {});
      }
    }
  }

  void getLocationTimekeeping() async {
    var connectStatus = context.read<ConnectivityService>().status;
    if (connectStatus != ConnectivityStatus.Offline) {
      var response = await BaseViewModel().callApis(
          {}, getJsonPlaceLocationByEmployee, method_post,
          isNeedAuthenticated: true, shouldSkipAuth: false);
      if (response.status.code == 200) {
        final Uint8List markerIcon = await Utils.getBytesFromAsset(
            ic_marker_working, Utils.resizeWidthUtil(context, 250).toInt());
        String jsonResponse = response.data['data'][0]['Column1']['v'];
        _placeList = jsonDecode(jsonResponse);
        await _checkNearestPosition(_placeList);
        for (int i = 0; i < _placeList.length; i++) {
          final MarkerId markerId = MarkerId('$i');
          final CircleId circleId = CircleId('$i');
          var object = _placeList[i];
          LatLng latLng =
              LatLng(double.parse(object['lat']), double.parse(object['lng']));
          double radius = double.parse(object['radius']);

          Circle circle = Circle(
              circleId: circleId,
              center: latLng,
              radius: radius.toDouble(),
              strokeColor: Colors.transparent,
              strokeWidth: 1,
              fillColor: only_color.withOpacity(0.2));

          Marker marker = Marker(
              markerId: markerId,
              icon: BitmapDescriptor.fromBytes(markerIcon),
              position: latLng,
              infoWindow:
                  InfoWindow(title: object['name'], snippet: '($radius m)'));
          _marker.add(marker);
          _circle.add(circle);
        }
      } else {
        showMessageDialogIOS(context,
            description: Utils.getString(context, txt_get_data_failed),
            onPress: () => Navigator.pop(context),
            onPressX: () {
              Navigator.pop(context);
              setState(() {
                _isSubmitted = false;
              });
            });
      }
    }
  }

  Future<double> getDistance(
      double lat1, double lat2, double lng1, double lng2) async {
    lat1 = lat1 * pi / 180;
    lat2 = lat2 * pi / 180;
    lng1 = lng1 * pi / 180;
    lng2 = lng2 * pi / 180;

    double deltaLat = lat2 - lat1;
    double deltaLon = lng2 - lng1;

    double a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    double c = 2 * math.asin(math.sqrt(a));
    return c * 6371 * 1000;
  }

  _checkNearestPosition(List<dynamic> placeList) async {
    LocationData location = await Location().getLocation();
    _currentLocation = Position(latitude: location.latitude, longitude: location.longitude);
    double distanceMinimum = 0;
    for (int i = 0; i < placeList.length; i++) {
      var place = placeList[i];
      double distance = Utils.getDistance(_currentLocation.latitude, _currentLocation.longitude,
          double.parse(place['lat']), double.parse(place['lng']));
      if (distanceMinimum == 0) {
        distanceMinimum = distance;
        positionMinValue = i;
      } else {
        if (distance < distanceMinimum) {
          distanceMinimum = distance;
          positionMinValue = i;
        }
      }
    }
    Future.delayed(Duration(seconds: 1), () {
      if(mounted)
        setState(() {
          reloadLocation = false;
          _distance = distanceMinimum.roundToDouble();
        });
    });
  }

  _submitTimekeeping(BuildContext context) async {

    setState(() {
      _isSubmitted = true;
    });
    if (_faceNumber == 0 ||
        _faceNumber > 1 &&
            widget.arguments.timekeepingType == TimekeepingType.Face) {
      Navigator.pushReplacementNamed(context, Routers.timeKeeping,
          arguments: CameraArgument(deviceBrand: widget.arguments.deviceBrand));
    } else {
      var data = {
        "IsMobileApp": true,
        "x": _currentLocation.latitude,
        "y": _currentLocation.longitude,
        "time": DateTime.now().toString(),
        "status_working_id":
            _timeDefineSelected != null ? _timeDefineSelected['id'] : -1
      };
      switch (widget.arguments.timekeepingType) {
        case TimekeepingType.Face:
          Uint8List imageByte = await _readFileByte(widget.arguments.path.path);
          final imageBase64 = Utils.convertBase64(imageByte);
          final dir = Directory(widget.arguments.path.path);
          dir.deleteSync(recursive: true);
          data = {
            ...data,
            ...{"url": "data:image/jpeg;base64,$imageBase64"}
          };
          break;
        case TimekeepingType.QRCode:
          Uint8List imageByte = await _readFileByte(widget.arguments.path.path);
          final imageBase64 = Utils.convertBase64(imageByte);
          data = {
            ...data,
            ...{"qrcode": widget.arguments.deviceBrand},
            ...{"url": "data:image/jpeg;base64,$imageBase64"}
          };
          break;
        case TimekeepingType.NFC:
          data = {
            ...data,
            ...{"nfc": widget.arguments.deviceBrand}
          };
      }
      var connectStatus = context.read<ConnectivityService>().status;
      if (connectStatus == ConnectivityStatus.Offline) {
        // save local
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String oldOfflineData = prefs.getString(TIMEKEEPING_DATA_KEY);
        List<dynamic> newOfflineData = [];
        if(oldOfflineData != null) {
          newOfflineData.addAll(jsonDecode(oldOfflineData));
          newOfflineData.add(data);
          prefs.setString(TIMEKEEPING_DATA_KEY, jsonEncode(newOfflineData).toString());
        } else {
          newOfflineData.add(data);
          prefs.setString(TIMEKEEPING_DATA_KEY, jsonEncode(newOfflineData).toString());
        }
        showMessageDialogIOS(context,
            description:
                Utils.getString(context, txt_title_timekeeping_offline_warning),
            onPress: () {
          addTimeKeepingBackgroundFetch(init: true);
          Navigator.popUntil(context, ModalRoute.withName(Routers.main));
        }, onPressX: () {
          Navigator.pop(context);
          setState(() {
            _isSubmitted = false;
          });
        });
      } else {
        showLoadingDialog(context);
        var submitResponse = await BaseViewModel().callApis({
          ...{"isOffline": false},
          ...{"error": false},
          ...data
        }, timeKeepingUrl, method_post,
            isNeedAuthenticated: true, shouldSkipAuth: false);
        Navigator.pop(context);
        if (submitResponse.status.code == 200) {
          if (submitResponse.data['data'][0]['isSuccees'] == 0) {
            showMessageDialog(context,
                description: submitResponse.data['data'][0]['msg'],
                onPress: () {
              if (widget.arguments.timekeepingType == TimekeepingType.Face)
                Navigator.pushReplacementNamed(context, Routers.timeKeeping,
                    arguments: CameraArgument(
                        deviceBrand: widget.arguments.deviceBrand));
              else {
                Navigator.popUntil(context, ModalRoute.withName(Routers.main));
              }
            }, onPressX: () {
              Navigator.pop(context);
              setState(() {
                _isSubmitted = false;
              });
            });
            //_checkingRemindTimekeeping();
          } else {
            /*if(widget.arguments.mqtt != null) {
              mQTT.publish("GSSW10/Power${widget.arguments.mqtt}", "ON");
              submitResponse.data['data'][0] = {
                ...submitResponse.data['data'][0],
                ...{'mqtt': widget.arguments.mqtt}
              };
            }*/
            Navigator.pushReplacementNamed(context, Routers.timeKeepingSuccess,
                arguments: submitResponse.data['data'][0]);
          }
        } else {
          setState(() {
            _isSubmitted = false;
          });
          showMessageDialog(context,
              description: Utils.getString(context, txt_timekeeping_failed),
              onPress: () {
            if (widget.arguments.timekeepingType == TimekeepingType.Face)
              Navigator.pushReplacementNamed(context, Routers.timeKeeping,
                  arguments: CameraArgument(
                      deviceBrand: widget.arguments.deviceBrand));
            else
              Navigator.pop(context);
          }, onPressX: () {
            Navigator.pop(context);
            setState(() {
              _isSubmitted = false;
            });
          });
        }
      }
    }
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    Directory tempDir = await getTemporaryDirectory();
    var tempPath = tempDir.path;
    Uri myUri = Uri.parse(filePath);
    File file = new File.fromUri(myUri);
    file = await FlutterExifRotation.rotateImage(path: file.path);
    Uint8List bytes = file.readAsBytesSync();
    img.Image imageTemp = img.decodeImage(bytes);
    var splitPath = filePath.split("/");
    File myCompressedFile =
        new File(tempPath + 'resize-${splitPath[splitPath.length - 1]}')
          ..writeAsBytesSync(img.encodeJpg(imageTemp, quality: 70));
    var bytesResponse = myCompressedFile.readAsBytesSync();
    final dir =
        Directory(tempPath + 'resize-${splitPath[splitPath.length - 1]}');
    dir.deleteSync(recursive: true);
    return bytesResponse;
  }

  _navigateShowMapView(BuildContext context) async {
    var result = await Navigator.pushNamed(context, Routers.showMap,
        arguments: CameraArgument(
            place: _placeList[positionMinValue],
            currentLocation: _currentLocation,
            distance: _distance,
            marker: _marker,
            circle: _circle));
    if (result != null) {
      CameraArgument argument = result;
      setState(() {
        _distance = argument.distance;
        _currentLocation = argument.currentLocation;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //_user = context.watch<BaseResponse>();
    return WillPopScope(
      onWillPop: () async {
        widget.arguments.timekeepingType == TimekeepingType.Face
            ? Navigator.pushReplacementNamed(context, Routers.timeKeeping,
                arguments:
                    CameraArgument(deviceBrand: widget.arguments.deviceBrand))
            : Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: bg_view_color,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            brightness: Brightness.light,
            leading: InkWell(
              onTap: () => widget.arguments.timekeepingType ==
                      TimekeepingType.Face
                  ? Navigator.pushReplacementNamed(context, Routers.timeKeeping,
                      arguments: CameraArgument(
                          deviceBrand: widget.arguments.deviceBrand))
                  : Navigator.pop(context),
              child: Icon(
                Icons.arrow_back_ios,
                color: txt_grey_color_v3,
                size: Utils.resizeWidthUtil(context, app_bar_icon_size),
              ),
            )),
        body: Stack(
          children: <Widget>[
            _buildBody(),
            if (_isSubmitted) LoadingWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SizedBox.expand(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildReviewImage(),
            SizedBox(height: Utils.resizeHeightUtil(context, 26)),
            widget.arguments.timekeepingType == TimekeepingType.QRCode
                ? Text(widget.arguments.deviceBrand, style: _bigStyle)
                : widget.arguments.timekeepingType == TimekeepingType.Face
                    ? Text(
                        _faceNumber == 0 || _faceNumber > 1
                            ? Utils.getString(
                                context, txt_time_keeping_not_success)
                            : Utils.getString(
                                context, txt_time_keeping_success),
                        style: _bigStyle)
                    : Text(widget.arguments.deviceBrand, style: _bigStyle),
            SizedBox(height: Utils.resizeHeightUtil(context, 81)),
            _buildLocationView(),
            _buildTimeDefineAllowed(),
            _buildLocationAllowed(),
            _buildTimeKeepingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewImage() {
    return Container(
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 182)),
      width: Utils.resizeHeightUtil(context, 415),
      height: Utils.resizeHeightUtil(context, 415),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            right: 0,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.arguments.timekeepingType ==
                        TimekeepingType.QRCode
                    ? Image.file(widget.arguments.path)
                    : widget.arguments.timekeepingType == TimekeepingType.Face
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(pi),
                            child: /*cropImages != null ? */Image.file(widget.arguments.path,
                                width: Utils.resizeHeightUtil(context, 380),
                                height: Utils.resizeHeightUtil(context, 380),
                                fit: BoxFit.cover)/* : Center(child: CircularProgressIndicator(),)*/,
                          )
                        : Image.asset(ic_nfc_success)),
          ),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _faceNumber == 0 || _faceNumber > 1
                  ? Center(
                      child: Container(
                        alignment: Alignment.center,
                        width: Utils.resizeWidthUtil(context, 76),
                        height: Utils.resizeWidthUtil(context, 76),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                Utils.resizeWidthUtil(context, 38)),
                            color: Colors.white),
                        child: Container(
                          width: Utils.resizeWidthUtil(context, 68),
                          height: Utils.resizeWidthUtil(context, 68),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  Utils.resizeWidthUtil(context, 34)),
                              color: txt_fail_color),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: Utils.resizeWidthUtil(context, 50),
                          ),
                        ),
                      ),
                    )
                  : Image.asset(ic_success,
                      width: Utils.resizeHeightUtil(context, 70),
                      height: Utils.resizeHeightUtil(context, 70)))
        ],
      ),
    );
  }

  Widget _buildLocationView() {
    return Container(
      decoration: _decoration,
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: [
                      Text(Utils.getString(context, txt_your_position), style: _bigStyle),
                      SizedBox(
                        width: 10,
                      ),
                      Text('(', style: _bigStyle),
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: !reloadLocation ? () async {
                          setState(() {
                            reloadLocation = true;
                          });
                          await _checkNearestPosition(_placeList);
                        } : () => {},
                        child: Text('Tải lại', style: TextStyle(fontSize: 20, color: reloadLocation ? Colors.grey : txt_blue)),
                      ),
                      Text(')', style: _bigStyle),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _navigateShowMapView(context),
                  child: Text(Utils.getString(context, txt_title_view_map),
                      style: _blueStyle),
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(
                horizontal: Utils.resizeHeightUtil(context, 30)),
            padding:
                EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 30)),
            child: DottedBorder(
              borderType: BorderType.RRect,
              color: _placeList.length > 0 && _distance != null
                  ? _distance <
                          double.parse(_placeList[positionMinValue]['radius'])
                      ? txt_success_color
                      : txt_fail_color
                  : txt_success_color,
              strokeWidth: Utils.resizeWidthUtil(context, 2),
              radius: Radius.circular(Utils.resizeWidthUtil(context, 8)),
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: Utils.resizeHeightUtil(context, 16),
                    horizontal: Utils.resizeHeightUtil(context, 20)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            child: Image.asset(ic_location,
                                width: Utils.resizeWidthUtil(context, 36),
                                height: Utils.resizeWidthUtil(context, 36)),
                          ),
                          SizedBox(width: Utils.resizeWidthUtil(context, 12)),
                          Expanded(child: Container(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(Utils.getString(context, txt_coordinate), style: _normalStyle),
                                SizedBox(height: 8),
                                if (reloadLocation)
                                  CupertinoActivityIndicator()
                                else
                                  _currentLocation != null
                                      ? Text(
                                    '${_currentLocation.latitude.toStringAsFixed(6)}, '
                                        '${_currentLocation.longitude.toStringAsFixed(6)}',
                                    style: _normalStyle,
                                  )
                                      : CupertinoActivityIndicator()
                              ],
                            ),
                          ))
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(top: 4),
                            child: Image.asset(ic_distance,
                                width: Utils.resizeWidthUtil(context, 36),
                                height: Utils.resizeWidthUtil(context, 36)),
                          ),
                          SizedBox(width: Utils.resizeWidthUtil(context, 12)),
                          Expanded(
                            child: Container(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  TKText(Utils.getString(context, txt_distance),
                                      style: _normalStyle),
                                  SizedBox(height: 5),
                                  if (reloadLocation)
                                    CupertinoActivityIndicator()
                                  else
                                    TKText('${_distance ?? ' 10.0'}m',
                                        style: _placeList.length > 0 && _distance != null
                                            ? _distance < double.parse(_placeList[positionMinValue]['radius'])
                                            ? _normalStyle
                                            : _normalStyle.merge(TextStyle(color: txt_fail_color))
                                            : _normalStyle)
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimeDefineAllowed() {
    return Container(
      decoration: _decoration,
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
      padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
      child: Row(
        children: <Widget>[
          TKText(Utils.getString(context, txt_time_define),
              style: _normalStyle),
          SizedBox(width: Utils.resizeWidthUtil(context, 20)),
          Expanded(
            child: SelectBoxCustomUtil(
              title: _timeDefineSelected != null
                  ? _timeDefineSelected['name']
                  : '',
              data: _timeDefineList,
              selectedItem: 0,
              enableSearch: false,
              enable: _timeDefineList.length > 1,
              initCallback: (state) {
                getTimeDefine(state: state);
              },
              clearCallback: () {},
              callBack: (selected) {
                setState(() {
                  _timeDefineSelected = selected;
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLocationAllowed() {
    return Container(
      decoration: _decoration,
      margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
      padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TKText(Utils.getString(context, txt_location_allowed),
                style: _normalStyle),
          ),
          _placeList.length > 0
              ? Expanded(
                  child: TKText(
                    _placeList.length > 1
                        ? '${Utils.getString(context, txt_allow_multiple_location)} \n (${_placeList[positionMinValue]['name']})'
                        : _placeList[positionMinValue]['name'],
                    style: _normalStyle,
                    textAlign: TextAlign.right,
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  Widget _buildTimeKeepingButton() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
      child: TKButton(
          Utils.getString(
              context,
              _faceNumber == 0 || _faceNumber > 1
                  ? txt_go_camera
                  : txt_title_time_keeping),
          width: double.infinity, onPress: () async {
        try {
          if (!await Utils.platform.invokeMethod('checkAutoDateTime'))
            showMessageDialogIOS(context,
                buttonText: txt_go_settings,
                description:
                'Vui lòng bật chế độ ngày/giờ tự động trên thiết bị của bạn',
                onPress: () async {
                  Navigator.pop(context);
                  await Utils.platform.invokeMethod('startAutoDateTimeSettings');
                });
          else
            _submitTimekeeping(context);
        } catch (e) {
          print(e.toString());
          _submitTimekeeping(context);
        }
      }, enable: _currentLocation != null && !reloadLocation),
    );
  }
}

class CameraArgument {
  Position currentLocation;
  File path;
  double distance;
  String deviceBrand;
  dynamic place;
  Set<Marker> marker;
  Set<Circle> circle;
  String qrCode;
  TimekeepingType timekeepingType;
  String mqtt;

  CameraArgument(
      {this.currentLocation,
      this.path,
      this.distance,
      this.deviceBrand,
      this.marker,
      this.circle,
      this.place,
      this.qrCode,
      this.timekeepingType /*,
      this.mqtt*/
      });
}
