// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
// import 'dart:typed_data';
//
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:gsot_timekeeping/core/enums/connectivity_status.dart';
// import 'package:gsot_timekeeping/core/enums/timekeeping_type.dart';
// import 'package:gsot_timekeeping/core/router/router.dart';
// import 'package:gsot_timekeeping/core/services/api_constants.dart';
// import 'package:gsot_timekeeping/core/services/connectivity_service.dart';
// import 'package:gsot_timekeeping/core/services/facenet.service.dart';
// import 'package:gsot_timekeeping/core/services/location_service.dart';
// import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
// import 'package:gsot_timekeeping/core/services/timekeeping_backgroud_service.dart';
// import 'package:gsot_timekeeping/core/util/utils.dart';
// import 'package:gsot_timekeeping/core/viewmodels/base_view_model.dart';
// import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
// import 'package:gsot_timekeeping/ui/constants/app_images.dart';
// import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
// import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
// import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
// import 'package:gsot_timekeeping/ui/widgets/dialog_custom.dart';
// import 'package:gsot_timekeeping/ui/widgets/loading.dart';
// import 'package:gsot_timekeeping/ui/widgets/select_box_custom_util.dart';
// import 'package:gsot_timekeeping/ui/widgets/tk_button.dart';
// import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
// import 'package:image/image.dart' as img;
// import 'package:intl/intl.dart';
// import 'package:location/location.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// final _normalStyle = TextStyle(
//     color: txt_black_color,
//     fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30),
//     fontFamily: 'SFProDisplay-Regular');
//
// final _bigStyle = TextStyle(
//     color: txt_black_color,
//     fontSize: Utils.resizeWidthUtil(Utils().getContext(), 34),
//     fontFamily: 'SFProDisplay-Regular');
//
// final _blueStyle = TextStyle(
//     color: txt_blue, fontSize: Utils.resizeWidthUtil(Utils().getContext(), 30), fontFamily: 'SFProDisplay-Regular');
//
// final _decoration = BoxDecoration(
//   color: Colors.white,
//   boxShadow: [
//     BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 0, spreadRadius: 0, offset: Offset(0, 4)),
//   ],
// );
//
// class CheckLocationV2 extends StatefulWidget {
//   final CameraArgument arguments;
//
//   const CheckLocationV2(this.arguments);
//
//   @override
//   _CheckLocationState createState() => _CheckLocationState();
// }
//
// class _CheckLocationState extends State<CheckLocationV2> {
//   DateFormat dateFormat = DateFormat('dd/MM/yyyy');
//
//   bool _isSubmitted = false;
//
//   Position _currentLocation;
//
//   double _distance;
//
//   List<dynamic> _placeList = [];
//
//   Set<Marker> _marker = Set<Marker>();
//
//   Set<Circle> _circle = Set<Circle>();
//
//   int positionMinValue = 0;
//
//   dynamic _timeDefineSelected;
//
//   List<dynamic> _timeDefineList = [];
//   bool reloadLocation = false;
//   FaceNetService _faceNetService = FaceNetService();
//   Uint8List uInt8list;
//   List predictedData;
//   bool isFaceDataExist = false;
//   String _resultMessage = '';
//   bool detecting = true;
//   var connectStatus;
//   bool isDetectSuccess = false;
//   double percent = 0;
//   var user;
//
//   @override
//   void initState() {
//     super.initState();
//     context.bloc<LocationBloc>().add(LocationEvent.getCurrentPosition);
//     if (widget.arguments.timekeepingType == TimekeepingType.Face) {
//       openCamera();
//       loadModel();
//       loadFaceDetect();
//       initialize();
//     } else
//       initialize();
//   }
//
//   initialize() async {
//     user = await SecureStorage().userProfile;
//     if (widget.arguments.distance != null) {
//       _distance = widget.arguments.distance;
//     }
//     Future.delayed(Duration(milliseconds: 0), () async {
//       if (widget.arguments.currentLocation != null) _currentLocation = widget.arguments.currentLocation;
//       getLocationTimekeeping();
//       getTimeDefine();
//     });
//   }
//
//   loadModel() async {
//     await _faceNetService.loadModel();
//   }
//
//   openCamera() {
//     Future(() {
//       Navigator.pushNamed(context, Routers.timekeepingV2, arguments: widget.arguments.deviceBrand)
//           .then((dynamic value) async {
//         if (value != null) {
//           try {
//             uInt8list = await _faceNetService.setCurrentPrediction(value['image'], value['face']);
//             if (predictedData != null) {
//               if (_predictUser()) {
//                 isDetectSuccess = true;
//                 _resultMessage =
//                 '${user.data['data'][0]['full_name']['v']} - ${user.data['data'][0]['emp_id']['v']} ($percent%)';
//               } else {
//                 isDetectSuccess = false;
//                 _resultMessage =
//                 'Nhận diện không chính xác bạn là \n${user.data['data'][0]['full_name']['v']} - ${user.data['data'][0]['emp_id']['v']} ($percent%)';
//               }
//             }
//           } catch (e) {
//             debugPrint(e.toString());
//             isDetectSuccess = false;
//             _resultMessage = 'Nhận diện không thành công';
//           }
//           imageCache.clear();
//           setState(() {
//             detecting = false;
//           });
//         }
//       });
//     });
//   }
//
//   loadFaceDetect() async {
//     connectStatus = context.read<ConnectivityService>().status;
//     if (connectStatus == ConnectivityStatus.Offline) {
//       _resultMessage = 'Không có kết nối mạng';
//     } else {
//       var response = await BaseViewModel()
//           .callApis({}, getFaceTrainUrl, method_post, shouldSkipAuth: false, isNeedAuthenticated: true);
//       if (response.status.code == 200) {
//         if (response.data['data'][0]['TF_FaceID']['v'] != '') {
//           isFaceDataExist = true;
//           predictedData = json.decode(response.data['data'][0]['TF_FaceID']['v']);
//         } else
//           _resultMessage = 'Chấm công lần đầu';
//       } else
//         _resultMessage = 'Có lỗi xảy ra. Vui lòng thử lại!';
//     }
//     setState(() {});
//   }
//
//   bool _predictUser() {
//     dynamic data = _faceNetService.predict(predictedData);
//     if (data['result'])
//       percent = Utils.round(data['value'] * 100, 2);
//     else
//       percent = 0;
//     bool result = data['result'];
//     return result;
//   }
//
//   Future<bool> updateFace() async {
//     showLoadingDialog(context);
//     var response = await BaseViewModel().callApis(
//         {'face': _faceNetService.predictedData.toString()}, updateFaceTrain, method_post,
//         shouldSkipAuth: false, isNeedAuthenticated: true);
//     Navigator.pop(context);
//     if (response.status.code == 200)
//       return true;
//     else {
//       showMessageDialog(context, description: Utils.getString(context, txt_update_failed));
//       return false;
//     }
//   }
//
//   checkUpdate(BuildContext context) {
//     if (connectStatus == ConnectivityStatus.Offline || isFaceDataExist)
//       _submitTimekeeping(context);
//     else
//       showMessageDialog(context,
//           description: 'Đây là lần đầu chấm công, bạn có muốn sử dụng ảnh này làm ảnh nhận diện?', onPress: () async {
//             Navigator.pop(context);
//             if (!await updateFace())
//               return;
//             else
//               _submitTimekeeping(context);
//           });
//   }
//
//   void getTimeDefine({SelectBoxCustomUtilState state}) async {
//     var connectStatus = context.read<ConnectivityService>().status;
//     if (connectStatus != ConnectivityStatus.Offline) {
//       List<dynamic> _list = [];
//       var response = await BaseViewModel().callApis(
//           {'date': DateFormat('yyyy/MM/dd').format(DateTime.now())}, timeDefineByEmployeeUrl, method_post,
//           shouldSkipAuth: false, isNeedAuthenticated: true);
//       if (response.status.code == 200) {
//         for (var list in jsonDecode(response.data['data'][0]['Column1']['v']))
//           _list.add({'id': list['status_working_id'], 'name': list['time_name'], 'time_id': list['time_id']});
//         _timeDefineList = _list;
//         _timeDefineSelected = _timeDefineList[0];
//         if (state != null) {
//           state.updateDataList(_timeDefineList);
//         }
//         setState(() {});
//       }
//     }
//   }
//
//   void getLocationTimekeeping() async {
//     var connectStatus = context.read<ConnectivityService>().status;
//     if (connectStatus != ConnectivityStatus.Offline) {
//       var response = await BaseViewModel()
//           .callApis({}, getJsonPlaceLocationByEmployee, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
//       if (response.status.code == 200) {
//         final Uint8List markerIcon =
//         await Utils.getBytesFromAsset(ic_marker_working, Utils.resizeWidthUtil(context, 250).toInt());
//         String jsonResponse = response.data['data'][0]['Column1']['v'];
//         _placeList = jsonDecode(jsonResponse);
//         await _checkNearestPosition(_placeList);
//         for (int i = 0; i < _placeList.length; i++) {
//           final MarkerId markerId = MarkerId('$i');
//           final CircleId circleId = CircleId('$i');
//           var object = _placeList[i];
//           LatLng latLng = LatLng(double.parse(object['lat']), double.parse(object['lng']));
//           double radius = double.parse(object['radius']);
//
//           Circle circle = Circle(
//               circleId: circleId,
//               center: latLng,
//               radius: radius.toDouble(),
//               strokeColor: Colors.transparent,
//               strokeWidth: 1,
//               fillColor: only_color.withOpacity(0.2));
//
//           Marker marker = Marker(
//               markerId: markerId,
//               icon: BitmapDescriptor.fromBytes(markerIcon),
//               position: latLng,
//               infoWindow: InfoWindow(title: object['name'], snippet: '($radius m)'));
//           _marker.add(marker);
//           _circle.add(circle);
//         }
//       } else {
//         showMessageDialogIOS(context,
//             description: Utils.getString(context, txt_get_data_failed),
//             onPress: () => Navigator.pop(context),
//             onPressX: () {
//               Navigator.pop(context);
//               setState(() {
//                 _isSubmitted = false;
//               });
//             });
//       }
//     }
//   }
//
//   _checkNearestPosition(List<dynamic> placeList) async {
//     LocationData location = await Location().getLocation();
//     _currentLocation = Position(latitude: location.latitude, longitude: location.longitude);
//     double distanceMinimum = 0;
//     for (int i = 0; i < placeList.length; i++) {
//       var place = placeList[i];
//       double distance = Utils.getDistance(_currentLocation.latitude, _currentLocation.longitude,
//           double.parse(place['lat']), double.parse(place['lng']));
//       if (distanceMinimum == 0) {
//         distanceMinimum = distance;
//         positionMinValue = i;
//       } else {
//         if (distance < distanceMinimum) {
//           distanceMinimum = distance;
//           positionMinValue = i;
//         }
//       }
//     }
//     Future.delayed(Duration(seconds: 1), () {
//       setState(() {
//         reloadLocation = false;
//         _distance = distanceMinimum.roundToDouble();
//       });
//     });
//   }
//
//   _submitTimekeeping(BuildContext context) async {
//     setState(() {
//       _isSubmitted = true;
//     });
//     if (!isDetectSuccess && isFaceDataExist && widget.arguments.timekeepingType == TimekeepingType.Face) {
//       openCamera();
//     } else {
//       var data = {
//         "IsMobileApp": true,
//         "x": _currentLocation.latitude,
//         "y": _currentLocation.longitude,
//         "time": DateTime.now().toString(),
//         "status_working_id": _timeDefineSelected != null ? _timeDefineSelected['id'] : -1,
//         "isFaceID": true
//       };
//       switch (widget.arguments.timekeepingType) {
//         case TimekeepingType.Face:
//           final imageBase64 = Utils.convertBase64(uInt8list);
//           data = {
//             ...data,
//             ...{"url": "data:image/jpeg;base64,$imageBase64"}
//           };
//           break;
//         case TimekeepingType.QRCode:
//           Uint8List imageByte = await _readFileByte(widget.arguments.path.path);
//           final imageBase64 = Utils.convertBase64(imageByte);
//           data = {
//             ...data,
//             ...{"qrcode": widget.arguments.deviceBrand},
//             ...{"url": "data:image/jpeg;base64,$imageBase64"}
//           };
//           break;
//         case TimekeepingType.NFC:
//           data = {
//             ...data,
//             ...{"nfc": widget.arguments.deviceBrand}
//           };
//       }
//       if (connectStatus == ConnectivityStatus.Offline) {
//         // save local
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         String oldOfflineData = prefs.getString(TIMEKEEPING_DATA_KEY);
//         prefs.setString(PREDICTED_DATA, _faceNetService.predictedData.toString());
//         List<dynamic> newOfflineData = [];
//         if (oldOfflineData != null) {
//           newOfflineData.addAll(jsonDecode(oldOfflineData));
//           newOfflineData.add(data);
//           prefs.setString(TIMEKEEPING_DATA_KEY, jsonEncode(newOfflineData).toString());
//         } else {
//           newOfflineData.add(data);
//           prefs.setString(TIMEKEEPING_DATA_KEY, jsonEncode(newOfflineData).toString());
//         }
//         showMessageDialogIOS(context, description: Utils.getString(context, txt_title_timekeeping_offline_warning),
//             onPress: () {
//               addTimeKeepingBackgroundFetch(init: true);
//               Navigator.popUntil(context, ModalRoute.withName(Routers.main));
//             }, onPressX: () {
//               Navigator.pop(context);
//               setState(() {
//                 _isSubmitted = false;
//               });
//             });
//       } else {
//         showLoadingDialog(context);
//         var submitResponse = await BaseViewModel().callApis({
//           ...{"isOffline": false},
//           ...{"error": false},
//           ...data
//         }, timeKeepingUrl, method_post, isNeedAuthenticated: true, shouldSkipAuth: false);
//         Navigator.pop(context);
//         if (submitResponse.status.code == 200) {
//           debugPrint(submitResponse.data.toString());
//           if (submitResponse.data['data'][0]['isSuccees'] == 0) {
//             showMessageDialog(context, description: submitResponse.data['data'][0]['msg'], onPress: () {
//               if (widget.arguments.timekeepingType == TimekeepingType.Face)
//                 openCamera();
//               else {
//                 Navigator.popUntil(context, ModalRoute.withName(Routers.main));
//               }
//             }, onPressX: () {
//               Navigator.pop(context);
//               setState(() {
//                 _isSubmitted = false;
//               });
//             });
//           } else {
//             Navigator.pushReplacementNamed(context, Routers.timeKeepingSuccess,
//                 arguments: submitResponse.data['data'][0]);
//           }
//         } else {
//           setState(() {
//             _isSubmitted = false;
//           });
//           showMessageDialog(context, description: Utils.getString(context, txt_timekeeping_failed), onPress: () {
//             if (widget.arguments.timekeepingType == TimekeepingType.Face)
//               Navigator.pushReplacementNamed(context, Routers.timeKeeping,
//                   arguments: CameraArgument(deviceBrand: widget.arguments.deviceBrand));
//             else
//               Navigator.pop(context);
//           }, onPressX: () {
//             Navigator.pop(context);
//             setState(() {
//               _isSubmitted = false;
//             });
//           });
//         }
//       }
//     }
//   }
//
//   Future<Uint8List> _readFileByte(String filePath) async {
//     Directory tempDir = await getTemporaryDirectory();
//     var tempPath = tempDir.path;
//     Uri myUri = Uri.parse(filePath);
//     File file = new File.fromUri(myUri);
//     file = await FlutterExifRotation.rotateImage(path: file.path);
//     Uint8List bytes = file.readAsBytesSync();
//     img.Image imageTemp = img.decodeImage(bytes);
//     var splitPath = filePath.split("/");
//     File myCompressedFile = new File(tempPath + 'resize-${splitPath[splitPath.length - 1]}')
//       ..writeAsBytesSync(img.encodeJpg(imageTemp, quality: 70));
//     var bytesResponse = myCompressedFile.readAsBytesSync();
//     final dir = Directory(tempPath + 'resize-${splitPath[splitPath.length - 1]}');
//     dir.deleteSync(recursive: true);
//     return bytesResponse;
//   }
//
//   _navigateShowMapView(BuildContext context) async {
//     var result = await Navigator.pushNamed(context, Routers.showMap,
//         arguments: CameraArgument(
//             place: _placeList[positionMinValue],
//             currentLocation: _currentLocation,
//             distance: _distance,
//             marker: _marker,
//             circle: _circle));
//     if (result != null) {
//       CameraArgument argument = result;
//       setState(() {
//         _distance = argument.distance;
//         _currentLocation = argument.currentLocation;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     //_user = context.watch<BaseResponse>();
//     return WillPopScope(
//       onWillPop: () async {
//         if (widget.arguments.timekeepingType == TimekeepingType.Face) {
//           //uInt8list = null;
//           openCamera();
//         } else
//           Navigator.pop(context);
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: bg_view_color,
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//             elevation: 0,
//             backgroundColor: Colors.transparent,
//             brightness: Brightness.light,
//             leading: InkWell(
//               onTap: () {
//                 if (widget.arguments.timekeepingType == TimekeepingType.Face) {
//                   //uInt8list = null;
//                   openCamera();
//                 } else
//                   Navigator.pop(context);
//                 return false;
//               },
//               child: Icon(
//                 Icons.arrow_back_ios,
//                 color: txt_grey_color_v3,
//                 size: Utils.resizeWidthUtil(context, app_bar_icon_size),
//               ),
//             )),
//         body: detecting && widget.arguments.timekeepingType == TimekeepingType.Face
//             ? Container()
//             : Stack(
//           children: <Widget>[
//             _buildBody(),
//             if (_isSubmitted) LoadingWidget(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     return SizedBox.expand(
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             _buildReviewImage(),
//             SizedBox(height: Utils.resizeHeightUtil(context, 26)),
//             Container(
//                 padding: EdgeInsets.symmetric(horizontal: Utils.resizeWidthUtil(context, 30)),
//                 child: widget.arguments.timekeepingType == TimekeepingType.QRCode
//                     ? Text(widget.arguments.deviceBrand, textAlign: TextAlign.center, style: _bigStyle)
//                     : widget.arguments.timekeepingType == TimekeepingType.Face
//                     ? Text(_resultMessage, textAlign: TextAlign.center, style: _bigStyle)
//                     : Text(widget.arguments.deviceBrand, textAlign: TextAlign.center, style: _bigStyle)),
//             SizedBox(height: Utils.resizeHeightUtil(context, 81)),
//             _buildLocationView(),
//             _buildTimeDefineAllowed(),
//             _buildLocationAllowed(),
//             _buildTimeKeepingButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildReviewImage() {
//     return Container(
//       margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 182)),
//       width: Utils.resizeHeightUtil(context, 415),
//       height: Utils.resizeHeightUtil(context, 415),
//       child: Stack(
//         children: <Widget>[
//           Positioned(
//             left: 0,
//             right: 0,
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: widget.arguments.timekeepingType == TimekeepingType.QRCode
//                     ? Image.file(widget.arguments.path)
//                     : widget.arguments.timekeepingType == TimekeepingType.Face
//                     ? uInt8list != null
//                     ? Transform(
//                   alignment: Alignment.center,
//                   transform: Matrix4.rotationY(pi),
//                   child: Image.memory(uInt8list,
//                       width: Utils.resizeHeightUtil(context, 380),
//                       height: Utils.resizeHeightUtil(context, 380),
//                       fit: BoxFit.cover),
//                 )
//                     : Image.asset(avatar_default)
//                     : Image.asset(ic_nfc_success)),
//           ),
//           Positioned(
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: uInt8list == null && widget.arguments.timekeepingType == TimekeepingType.Face ||
//                   !isDetectSuccess && isFaceDataExist
//                   ? Center(
//                 child: Container(
//                   alignment: Alignment.center,
//                   width: Utils.resizeWidthUtil(context, 76),
//                   height: Utils.resizeWidthUtil(context, 76),
//                   decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 38)),
//                       color: Colors.white),
//                   child: Container(
//                     width: Utils.resizeWidthUtil(context, 68),
//                     height: Utils.resizeWidthUtil(context, 68),
//                     decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(Utils.resizeWidthUtil(context, 34)),
//                         color: txt_fail_color),
//                     child: Icon(
//                       Icons.close,
//                       color: Colors.white,
//                       size: Utils.resizeWidthUtil(context, 50),
//                     ),
//                   ),
//                 ),
//               )
//                   : Image.asset(ic_success,
//                   width: Utils.resizeHeightUtil(context, 70), height: Utils.resizeHeightUtil(context, 70)))
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationView() {
//     return Container(
//       decoration: _decoration,
//       child: Column(
//         children: <Widget>[
//           Container(
//             padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
//             child: Row(
//               children: <Widget>[
//                 Expanded(
//                   child: Row(
//                     children: [
//                       Text(Utils.getString(context, txt_your_position), style: _bigStyle),
//                       SizedBox(
//                         width: 10,
//                       ),
//                       Text('(', style: _bigStyle),
//                       GestureDetector(
//                         behavior: HitTestBehavior.translucent,
//                         onTap: !reloadLocation ? () async {
//                           setState(() {
//                             reloadLocation = true;
//                           });
//                           await _checkNearestPosition(_placeList);
//                         } : () => {},
//                         child: Text('Tải lại', style: TextStyle(fontSize: 20, color: reloadLocation ? Colors.grey : txt_blue)),
//                       ),
//                       Text(')', style: _bigStyle),
//                     ],
//                   ),
//                 ),
//                 GestureDetector(
//                   behavior: HitTestBehavior.translucent,
//                   onTap: () => _navigateShowMapView(context),
//                   child: Text(Utils.getString(context, txt_title_view_map), style: _blueStyle),
//                 )
//               ],
//             ),
//           ),
//           Container(
//             margin: EdgeInsets.symmetric(horizontal: Utils.resizeHeightUtil(context, 30)),
//             padding: EdgeInsets.only(bottom: Utils.resizeHeightUtil(context, 30)),
//             child: DottedBorder(
//               borderType: BorderType.RRect,
//               color: _placeList.length > 0 && _distance != null
//                   ? _distance < double.parse(_placeList[positionMinValue]['radius'])
//                   ? txt_success_color
//                   : txt_fail_color
//                   : txt_success_color,
//               strokeWidth: Utils.resizeWidthUtil(context, 2),
//               radius: Radius.circular(Utils.resizeWidthUtil(context, 8)),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                     vertical: Utils.resizeHeightUtil(context, 16), horizontal: Utils.resizeHeightUtil(context, 20)),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Flexible(
//                       flex: 3,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           Container(
//                             margin: EdgeInsets.only(top: 4),
//                             child: Image.asset(ic_location,
//                                 width: Utils.resizeWidthUtil(context, 36), height: Utils.resizeWidthUtil(context, 36)),
//                           ),
//                           SizedBox(width: Utils.resizeWidthUtil(context, 12)),
//                           Expanded(
//                               child: Container(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: <Widget>[
//                                     Text(Utils.getString(context, txt_coordinate), style: _normalStyle),
//                                     SizedBox(height: 8),
//                                     if (reloadLocation)
//                                       CupertinoActivityIndicator()
//                                     else
//                                       _currentLocation != null
//                                           ? Text(
//                                         '${_currentLocation.latitude.toStringAsFixed(6)}, '
//                                             '${_currentLocation.longitude.toStringAsFixed(6)}',
//                                         style: _normalStyle,
//                                       )
//                                           : CupertinoActivityIndicator()
//                                   ],
//                                 ),
//                               )
//                             /*BlocBuilder<LocationBloc, Position>(builder: (context, position) {
//                             if (position.latitude != null) {
//                               _currentLocation = position;
//                             } else
//                               context.bloc<LocationBloc>().add(LocationEvent.getCurrentPosition);
//                             return Container(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: <Widget>[
//                                   Text(Utils.getString(context, txt_coordinate),
//                                       style: _normalStyle),
//                                   SizedBox(height: 8),
//                                   if (reloadLocation)
//                                     CupertinoActivityIndicator()
//                                   else
//                                     position.latitude != null
//                                         ? Text(
//                                             '${position.latitude.toStringAsFixed(6)}, '
//                                             '${position.longitude.toStringAsFixed(6)}',
//                                             style: _normalStyle,
//                                           )
//                                         : _currentLocation != null
//                                             ? Text(
//                                                 '${_currentLocation.latitude.toStringAsFixed(6)}, '
//                                                 '${_currentLocation.longitude.toStringAsFixed(6)}',
//                                                 style: _normalStyle,
//                                               )
//                                             : CupertinoActivityIndicator()
//                                 ],
//                               ),
//                             );
//                           })*/
//                           )
//                         ],
//                       ),
//                     ),
//                     Flexible(
//                       flex: 2,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: <Widget>[
//                           Container(
//                             margin: EdgeInsets.only(top: 4),
//                             child: Image.asset(ic_distance,
//                                 width: Utils.resizeWidthUtil(context, 36), height: Utils.resizeWidthUtil(context, 36)),
//                           ),
//                           SizedBox(width: Utils.resizeWidthUtil(context, 12)),
//                           Expanded(
//                             child: Container(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: <Widget>[
//                                   TKText(Utils.getString(context, txt_distance), style: _normalStyle),
//                                   SizedBox(height: 5),
//                                   if (reloadLocation || _currentLocation == null)
//                                     CupertinoActivityIndicator()
//                                   else
//                                     TKText('${_distance ?? ' 10.0'}m',
//                                         style: _placeList.length > 0 && _distance != null
//                                             ? _distance < double.parse(_placeList[positionMinValue]['radius'])
//                                             ? _normalStyle
//                                             : _normalStyle.merge(TextStyle(color: txt_fail_color))
//                                             : _normalStyle)
//                                   /*BlocBuilder<LocationBloc, Position>(
//                                         builder: (context, position) {
//                                       if (position.latitude != null) {
//                                         Future.microtask(() async {
//                                           double distance = await _checkNearestPosition(_placeList);
//                                           if (mounted) {
//                                             setState(() {
//                                               _distance = distance.roundToDouble();
//                                             });
//                                           }
//                                         });
//                                       }
//                                       return TKText('${_distance ?? ' 10.0'}m',
//                                           style: _placeList.length > 0 && _distance != null
//                                               ? _distance <
//                                                       double.parse(
//                                                           _placeList[positionMinValue]['radius'])
//                                                   ? _normalStyle
//                                                   : _normalStyle
//                                                       .merge(TextStyle(color: txt_fail_color))
//                                               : _normalStyle);
//                                     }),*/
//                                 ],
//                               ),
//                             ),
//                           )
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeDefineAllowed() {
//     return Container(
//       decoration: _decoration,
//       margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
//       padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
//       child: Row(
//         children: <Widget>[
//           TKText(Utils.getString(context, txt_time_define), style: _normalStyle),
//           SizedBox(width: Utils.resizeWidthUtil(context, 20)),
//           Expanded(
//             child: SelectBoxCustomUtil(
//               title: _timeDefineSelected != null ? _timeDefineSelected['name'] : '',
//               data: _timeDefineList,
//               selectedItem: 0,
//               enableSearch: false,
//               enable: _timeDefineList.length > 1,
//               initCallback: (state) {
//                 getTimeDefine(state: state);
//               },
//               clearCallback: () {},
//               callBack: (selected) {
//                 setState(() {
//                   _timeDefineSelected = selected;
//                 });
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocationAllowed() {
//     return Container(
//       decoration: _decoration,
//       margin: EdgeInsets.only(top: Utils.resizeHeightUtil(context, 20)),
//       padding: EdgeInsets.all(Utils.resizeHeightUtil(context, 30)),
//       child: Row(
//         children: <Widget>[
//           Expanded(
//             child: TKText(Utils.getString(context, txt_location_allowed), style: _normalStyle),
//           ),
//           _placeList.length > 0
//               ? Expanded(
//             child: TKText(
//               _placeList.length > 1
//                   ? '${Utils.getString(context, txt_allow_multiple_location)} \n (${_placeList[positionMinValue]['name']})'
//                   : _placeList[positionMinValue]['name'],
//               style: _normalStyle,
//               textAlign: TextAlign.right,
//             ),
//           )
//               : Container(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeKeepingButton() {
//     return Container(
//       alignment: Alignment.centerLeft,
//       margin: EdgeInsets.all(Utils.resizeWidthUtil(context, 30)),
//       child: TKButton(
//           Utils.getString(context, !isDetectSuccess && isFaceDataExist ? txt_go_camera : txt_title_time_keeping),
//           backgroundColor: isDetectSuccess || !isFaceDataExist ? only_color : txt_fail_color,
//           width: double.infinity, onPress: () async {
//         try {
//           if (!await Utils.platform.invokeMethod('checkAutoDateTime'))
//             showMessageDialogIOS(context,
//                 buttonText: txt_go_settings,
//                 description: 'Vui lòng bật chế độ ngày/giờ tự động trên thiết bị của bạn', onPress: () async {
//                   Navigator.pop(context);
//                   await Utils.platform.invokeMethod('startAutoDateTimeSettings');
//                 });
//           else {
//             if (isDetectSuccess || !isFaceDataExist)
//               checkUpdate(context);
//             else
//               openCamera();
//           }
//         } catch (e) {
//           print(e.toString());
//           if (isDetectSuccess)
//             checkUpdate(context);
//           else
//             openCamera();
//         }
//       }, enable: _currentLocation != null && !reloadLocation),
//     );
//   }
// }
