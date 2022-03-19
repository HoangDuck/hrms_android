// import 'dart:math' as math;
//
// import 'package:camera/camera.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:gsot_timekeeping/core/services/camera.service.dart';
// import 'package:gsot_timekeeping/core/services/ml_vision_service.dart';
// import 'package:gsot_timekeeping/core/util/utils.dart';
// import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
// import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
// import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
// import 'package:image/image.dart' as imbLib;
// import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
//
// class TimekeepingViewV2 extends StatefulWidget {
//
//   final String deviceBrand;
//
//   TimekeepingViewV2(this.deviceBrand);
//
//   @override
//   _TimekeepingViewV2State createState() => _TimekeepingViewV2State();
// }
//
// class _TimekeepingViewV2State extends State<TimekeepingViewV2> {
//   List<CameraDescription> cameras;
//   CameraService _cameraService = CameraService();
//   CameraDescription cameraDescription;
//   CameraImage cameraImage;
//   MLVisionService _mlVisionService = MLVisionService();
//   bool detecting = false;
//   imbLib.Image image;
//   List<Face> faces = [];
//   bool saving = false;
//   bool loading = true;
//   String detectMessage = '';
//   bool isAutoDetect = false;
//
//   @override
//   void initState() {
//     super.initState();
//     initialize();
//   }
//
//   @override
//   void dispose() {
//     _cameraService.dispose();
//     super.dispose();
//   }
//
//   initialize() async {
//     await _checkAutoDetect();
//     List<CameraDescription> cameras = await availableCameras();
//     cameraDescription = cameras.firstWhere(
//       (CameraDescription camera) =>
//           camera.lensDirection == CameraLensDirection.front,
//     );
//     _mlVisionService.initialize();
//     await _cameraService.startService(cameraDescription, widget.deviceBrand);
//     setState(() {});
//     detectFace();
//   }
//
//   detectFace() {
//     _cameraService.cameraController.startImageStream((CameraImage img) async {
//       if (loading) {
//         setState(() {
//           loading = false;
//         });
//         if (isAutoDetect)
//           Future.delayed(Duration(seconds: 1), () {
//             saving = true;
//           });
//       }
//       if (detecting && mounted) return;
//       detecting = true;
//       if (saving)
//         try {
//           faces = await _mlVisionService.getFacesFromImage(img);
//           if (faces.length == 1) {
//             _cameraService.dispose();
//             if (!mounted) return;
//             Navigator.pop(context, {'image': img, 'face': faces[0]});
//           } else if (faces.length == 0) {
//             detectMessage = Utils.getString(context, txt_no_face);
//           } else
//             detectMessage = Utils.getString(context, txt_multi_faces_camera);
//           setState(() {});
//         } catch (ex, stack) {
//           debugPrint('$ex, $stack');
//         }
//       Future.delayed(Duration(milliseconds: 300), () {
//         detecting = false;
//       });
//     });
//   }
//
//   _checkAutoDetect() async {
//     var _user = await SecureStorage().userProfile;
//     if (_user.data['data'][0]['Timekeeping_IsFaceAuto']['v'] != 'False') {
//       isAutoDetect = true;
//     } else
//       detectMessage =
//           'Bạn đang ở chế độ thủ công\nchạm vào màn hình để bắt đầu';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return WillPopScope(
//           onWillPop: () async {
//             _cameraService.dispose();
//             Navigator.of(context).popUntil((route) => route.isFirst);
//             return false;
//           },
//           child: Scaffold(
//               appBar: appBarCustom(context, () {
//                 _cameraService.dispose();
//                 Navigator.of(context).popUntil((route) => route.isFirst);
//               }, () => {}, '', null,
//                   hideBackground: true, leadingIconColor: only_color),
//               body: Container(
//                   child: Center(
//                 child: CircularProgressIndicator(),
//               ))));
//     }
//     var tmp = MediaQuery.of(context).size;
//     var screenH = math.max(tmp.height, tmp.width);
//     var screenW = math.min(tmp.height, tmp.width);
//     tmp = _cameraService.cameraController.value.previewSize;
//     var previewH = math.max(tmp.height, tmp.width);
//     var previewW = math.min(tmp.height, tmp.width);
//     var screenRatio = screenH / screenW;
//     var previewRatio = previewH / previewW;
//
//     return WillPopScope(
//         onWillPop: () async {
//           _cameraService.dispose();
//           Navigator.of(context).popUntil((route) => route.isFirst);
//           return false;
//         },
//         child: Scaffold(
//             extendBodyBehindAppBar: true,
//             backgroundColor: Colors.black,
//             appBar: AppBar(
//                 elevation: 0,
//                 backgroundColor: Colors.transparent,
//                 brightness: Brightness.dark,
//                 leading: InkWell(
//                   onTap: () {
//                     _cameraService.dispose();
//                     Navigator.of(context).popUntil((route) => route.isFirst);
//                   },
//                   child: Icon(
//                     Icons.arrow_back_ios,
//                     color: Colors.white,
//                     size: Utils.resizeWidthUtil(context, app_bar_icon_size),
//                   ),
//                 )),
//             body: OverflowBox(
//               maxHeight: screenRatio > previewRatio
//                   ? screenH
//                   : screenW / previewW * previewH,
//               maxWidth: screenRatio > previewRatio
//                   ? screenH / previewH * previewW
//                   : screenW,
//               child: Stack(
//                 children: <Widget>[
//                   CameraPreview(_cameraService.cameraController),
//                   CustomPaint(
//                     painter: Painter(),
//                     child: ClipPath(
//                       clipper: FaceDetectSquare(),
//                       child: Container(
//                         width: double.infinity,
//                         height: double.infinity,
//                         color: Color.fromRGBO(0, 0, 0, 0.5),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: MediaQuery.of(context).size.height * 0.8,
//                     left: MediaQuery.of(context).size.width * 0.2,
//                     right: MediaQuery.of(context).size.width * 0.2,
//                     child: Text(
//                       detectMessage,
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                           color: Colors.white,
//                           fontSize: Utils.resizeWidthUtil(context, 36)),
//                     ),
//                   ),
//                   if (!isAutoDetect)
//                     GestureDetector(
//                       onTap: () {
//                         setState(() {
//                           detectMessage = 'Đang xử lý...';
//                           saving = true;
//                         });
//                       },
//                     ),
//                 ],
//               ),
//             )));
//   }
// }
//
// class FaceDetectSquare extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     var path = Path();
//     path.moveTo(size.width * 0.18, size.height * 0.3);
//     path.lineTo(size.width * 0.82, size.height * 0.3);
//     path.quadraticBezierTo(size.width * 0.86, size.height * 0.3,
//         size.width * 0.86, size.height * 0.33);
//     path.lineTo(size.width * 0.86, size.height * 0.68);
//     path.quadraticBezierTo(size.width * 0.86, size.height * 0.7,
//         size.width * 0.82, size.height * 0.7);
//     path.lineTo(size.width * 0.18, size.height * 0.7);
//     path.quadraticBezierTo(size.width * 0.14, size.height * 0.7,
//         size.width * 0.14, size.height * 0.67);
//     path.lineTo(size.width * 0.14, size.height * 0.33);
//     path.quadraticBezierTo(size.width * 0.14, size.height * 0.3,
//         size.width * 0.18, size.height * 0.3);
//     /*path.moveTo(size.width * 0.14, size.height * 0.3);
//     path.lineTo(size.width * 0.86, size.height * 0.3);
//     path.lineTo(size.width * 0.86, size.height * 0.7);
//     path.lineTo(size.width * 0.14, size.height * 0.7);*/
//     path.fillType = PathFillType.evenOdd;
//     path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
//     return path;
//   }
//
//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }
//
// class Painter extends CustomPainter {
//   bool fade = true;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.amber
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;
//     var path1 = Path();
//     var path2 = Path();
//     var path3 = Path();
//     var path4 = Path();
//     path1.moveTo(size.width * 0.16, size.height * 0.345);
//     path1.lineTo(size.width * 0.16, size.height * 0.33);
//     path1.quadraticBezierTo(size.width * 0.16, size.height * 0.31,
//         size.width * 0.2, size.height * 0.31);
//     path1.lineTo(size.width * 0.23, size.height * 0.31);
//     path1.lineTo(size.width * 0.23, size.height * 0.313);
//
//     path1.lineTo(size.width * 0.2, size.height * 0.313);
//     path1.quadraticBezierTo(size.width * 0.165, size.height * 0.313,
//         size.width * 0.165, size.height * 0.33);
//     path1.lineTo(size.width * 0.165, size.height * 0.345);
//     path1.lineTo(size.width * 0.165, size.height * 0.345);
//     path1.close();
//
//     path2.moveTo(size.width * 0.77, size.height * 0.31);
//     path2.lineTo(size.width * 0.81, size.height * 0.31);
//     path2.quadraticBezierTo(size.width * 0.84, size.height * 0.31,
//         size.width * 0.84, size.height * 0.33);
//     path2.lineTo(size.width * 0.84, size.height * 0.345);
//
//     path2.lineTo(size.width * 0.835, size.height * 0.345);
//     path2.lineTo(size.width * 0.835, size.height * 0.330);
//     path2.quadraticBezierTo(size.width * 0.835, size.height * 0.3125,
//         size.width * 0.810, size.height * 0.3125);
//     path2.lineTo(size.width * 0.77, size.height * 0.3125);
//     path2.close();
//
//     path3.moveTo(size.width * 0.84, size.height * 0.65);
//     path3.lineTo(size.width * 0.84, size.height * 0.67);
//     path3.quadraticBezierTo(size.width * 0.84, size.height * 0.69,
//         size.width * 0.81, size.height * 0.69);
//     path3.lineTo(size.width * 0.77, size.height * 0.69);
//
//     path3.lineTo(size.width * 0.77, size.height * 0.6875);
//     path3.lineTo(size.width * 0.805, size.height * 0.6875);
//     path3.quadraticBezierTo(size.width * 0.838, size.height * 0.6875,
//         size.width * 0.835, size.height * 0.667);
//     path3.lineTo(size.width * 0.835, size.height * 0.65);
//     path3.close();
//
//     path4.moveTo(size.width * 0.235, size.height * 0.69);
//     path4.lineTo(size.width * 0.2, size.height * 0.69);
//     path4.quadraticBezierTo(size.width * 0.16, size.height * 0.69,
//         size.width * 0.16, size.height * 0.67);
//     path4.lineTo(size.width * 0.16, size.height * 0.65);
//
//     path4.lineTo(size.width * 0.165, size.height * 0.65);
//     path4.lineTo(size.width * 0.165, size.height * 0.667);
//     path4.quadraticBezierTo(size.width * 0.165, size.height * 0.6875,
//         size.width * 0.2, size.height * 0.6875);
//     path4.lineTo(size.width * 0.235, size.height * 0.6875);
//
//     path1.fillType = PathFillType.evenOdd;
//     path2.fillType = PathFillType.evenOdd;
//     path3.fillType = PathFillType.evenOdd;
//     path4.fillType = PathFillType.evenOdd;
//
//     canvas.drawPath(path1, paint);
//     canvas.drawPath(path2, paint);
//     canvas.drawPath(path3, paint);
//     canvas.drawPath(path4, paint);
//   }
//
//   @override
//   bool shouldRepaint(Painter oldDelegate) {
//     return fade = !fade;
//   }
// }
