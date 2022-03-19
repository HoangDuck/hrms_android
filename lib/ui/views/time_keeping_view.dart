import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gsot_timekeeping/core/base/base_response.dart';
import 'package:gsot_timekeeping/core/components/camera_custom.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/services/location_service.dart';
import 'package:gsot_timekeeping/core/services/secure_storage_service.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/views/main_view.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:provider/provider.dart';

final _opacityColors = Colors.black.withOpacity(0.6);
final mediumFaceRatio = 0.86;
final highFaceRatio = 0.86;

class TimeKeepingView extends StatefulWidget {
  final CameraArgument arguments;

  TimeKeepingView(this.arguments);

  @override
  _TimeKeepingViewState createState() => _TimeKeepingViewState();
}

class _TimeKeepingViewState extends State<TimeKeepingView> with TickerProviderStateMixin, WidgetsBindingObserver {
  StreamController<int> _numFaces = StreamController();
  GlobalKey _detectFaceKey = GlobalKey();
  final _scanKey = GlobalKey<CameraMlVisionState>();
  Rect _faceDetectRect;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  /*FaceDetector _detector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
    enableTracking: true,
    mode: FaceDetectorMode.accurate,
    enableLandmarks: true,
    enableContours: true,
    minFaceSize: 1.0,
    enableClassification: true,
  ));*/

  bool _isCaptured = false;
  Size _cameraSize;
  double faceDetectRatio;
  int _currentFaces = -1;
  AnimationController _controllerRotate;
  bool isAutoDetect = true;

  //FToast fToast;
  Timer _timer;
  var _user;
  bool _isShowCountDown = false;

  @override
  void initState() {
    super.initState();
    //fToast = FToast();
    //fToast.init(context);
    _checkAutoDetect();
    //_limitTime();
    // context.read<LocationBloc>().add(LocationEvent.getCurrentPosition);
    if (widget.arguments.deviceBrand.contains('samsung'))
      faceDetectRatio = mediumFaceRatio;
    else
      faceDetectRatio = highFaceRatio;
  }

  @override
  void dispose() {
    _numFaces.close();
    if (!isAutoDetect) _controllerRotate.dispose();
    if (_timer != null) _timer.cancel();
    super.dispose();
  }

  _checkAutoDetect() async {
    _user = await SecureStorage().userProfile;
    if (_user.data['data'][0]['Timekeeping_IsFaceAuto']['v'] == 'False') {
      _controllerRotate = AnimationController(
        duration: const Duration(seconds: 7),
        vsync: this,
      );
      _controllerRotate.repeat();
      isAutoDetect = false;
    } else {
      isAutoDetect = true;
      _startCountDown();
    }
    setState(() {});
  }

  _startCountDown() {
    int countDownAuto = 5;
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (!_isShowCountDown)
          setState(() {
            _isShowCountDown = true;
          });
        if (countDownAuto == 1) {
          timer.cancel();
          await _scanKey.currentState.captureClick(context, _faceDetectRect);
        } else {
          countDownAuto--;
        }
      },
    );
  }

  _limitTime() {
    Future.delayed(Duration(seconds: 15), () {
      if (mounted) {
        FToast().showToast(
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: Colors.grey,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TKText(Utils.getString(context, txt_no_face),
                      style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          gravity: ToastGravity.BOTTOM,
          toastDuration: Duration(seconds: 3),
        );
        Navigator.pushNamedAndRemoveUntil(context, Routers.main, (r) => false);
      }
    });
  }

  _getFacePositions() {
    RenderBox renderFaceBox = _detectFaceKey.currentContext.findRenderObject();
    _faceDetectRect = Rect.fromLTRB(
        renderFaceBox.localToGlobal(Offset.zero).dx,
        renderFaceBox.localToGlobal(Offset.zero).dy,
        (renderFaceBox.localToGlobal(Offset.zero).dx + renderFaceBox.size.width),
        renderFaceBox.localToGlobal(Offset.zero).dy + renderFaceBox.size.height);
  }

  _onFaceDetectResult(/*List<Face> faces, */ BuildContext context) async {
    /*if (faces == null || !mounted || _isCaptured) {
      return;
    }*/
    /*if (faces.length == 0) {
      if (_currentFaces != 0) {
        _numFaces.add(0);
        _currentFaces = 0;
      }
    } else if (faces.length > 1) {
      if (_currentFaces != 2) {
        _numFaces.add(2);
        _currentFaces = 2;
      }
    } else {
      if (_currentFaces != 1) {
        _numFaces.add(1);
        _currentFaces = 1;
      }
      if (_faceDetectRect == null) _getFacePositions();
      final reflection = _reflectionRect(true, faces.last.boundingBox,
          _scanKey.currentState.cameraValue.previewSize.flipped);
      final currentBoundScale = _scaleRect(
          rect: reflection,
          imageSize: _scanKey.currentState.cameraValue.previewSize.flipped,
          widgetSize: _cameraSize);

      if (_checkingFaceRect(
          faces, context, currentBoundScale, _faceDetectRect)) {
        _isCaptured = true;*/
    /*if (mounted) {
          if(isAutoDetect)
            await _scanKey.currentState.captureAuto(context, _faceDetectRect);
        }*/
    /*} else {
        _isCaptured = false;
      }
    }*/
  }

  /*_checkingFaceRect(List<Face> faces, BuildContext context, Rect currentBound, Rect faceBoundScale) {
    var depreciationTop = MediaQuery.of(context).padding.top;
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (currentBound.right >= _faceDetectRect.left &&
          currentBound.top >= _faceDetectRect.top - depreciationTop &&
          currentBound.left <= _faceDetectRect.right &&
          currentBound.bottom <= _faceDetectRect.bottom - depreciationTop &&
          !_isCaptured) return true;
    } else if (currentBound.left >= _faceDetectRect.left &&
        currentBound.top >= _faceDetectRect.top - depreciationTop &&
        currentBound.right <= _faceDetectRect.right &&
        currentBound.bottom <= _faceDetectRect.bottom - depreciationTop &&
        !_isCaptured) return true;
    return false;
  }*/

  updateChange(bool value) async {
    _user.data['data'][0]['Timekeeping_IsFaceAuto']['v'] = value ? 'True' : 'False';
    await SecureStorage().saveProfileCustomer(_user);
    context.read<BaseResponse>().addData(_user.data);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: InkWell(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: Utils.resizeWidthUtil(context, app_bar_icon_size),
              ),
            ), systemOverlayStyle: SystemUiOverlayStyle.light),
        body: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              children: <Widget>[
                _buildCamera(),
                _buildFaceDetectSquare(),
                if (!isAutoDetect) _buildIconTimekeeping() else if (_isShowCountDown) _buildCountDown(),
                _buildAutoButton()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoButton() => Positioned(
        right: 20,
        top: 20,
        child: Row(
          children: [
            TKText('Auto ${isAutoDetect ? 'ON' : 'OFF'}', style: TextStyle(color: Colors.white)),
            SizedBox(
              width: 10,
            ),
            CupertinoSwitch(
              value: isAutoDetect,
              trackColor: Colors.red,
              onChanged: (value) async {
                if (isAutoDetect) {
                  _controllerRotate = AnimationController(
                    duration: const Duration(seconds: 7),
                    vsync: this,
                  );
                  _controllerRotate.repeat();
                  _timer.cancel();
                  await updateChange(false);
                  isAutoDetect = false;
                } else {
                  _controllerRotate.dispose();
                  isAutoDetect = true;
                  await updateChange(true);
                  _startCountDown();
                }
                setState(() {});
              },
            ),
          ],
        ),
      );

  Widget _buildCountDown() => Positioned.fill(
        child: Align(
          alignment: Alignment.centerRight,
          child: AnimatedTextKit(
            repeatForever: false,
            isRepeatingAnimation: false,
            animatedTexts: [
              RotateAnimatedText('3',
                  textStyle: TextStyle(fontSize: 70, color: Colors.white), duration: Duration(milliseconds: 700)),
              RotateAnimatedText('2',
                  textStyle: TextStyle(fontSize: 70, color: Colors.white), duration: Duration(milliseconds: 700)),
              RotateAnimatedText('1',
                  textStyle: TextStyle(fontSize: 70, color: Colors.white), duration: Duration(milliseconds: 700)),
            ],
          ),
        ),
      );

  Widget _buildIconTimekeeping() => Positioned(
        bottom: 20,
        left: 20,
        right: 20,
        child: GestureDetector(
          onTap: () async {
            await _scanKey.currentState.captureClick(context, _faceDetectRect);
          },
          child: Container(
              width: Utils.resizeWidthUtil(context, 120),
              height: Utils.resizeWidthUtil(context, 120),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(shape: BoxShape.circle, color: white_color),
              child: RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0).animate(_controllerRotate),
                  child: Image.network(
                    '$avatarUrl/fileman/Uploads/vw_tbDefineMenu/436/thumb/ictimekeeping.png',
                    color: only_color,
                  ))),
        ),
      );

  Widget _buildCamera() {
    return SizedBox.expand(
      child: CameraMlVision(
        key: _scanKey,
        deviceBrand: widget.arguments.deviceBrand,
        cameraLensDirection: _cameraLensDirection,
        //detector: _detector.processImage,
        //mqtt: widget.arguments.mqtt,
        // onResult: (/*faces*/) => _onFaceDetectResult(/*faces, */ context),
        onDispose: () {
          //_detector.close();
        },
        reCapture: (faces) {
          _isCaptured = false;
          _numFaces.add(faces);
        },
        overlayBuilder: (e) {
          return _scanKey.currentState.isStreaming ? Container() : Container(color: Colors.black);
        },
      ),
    );
  }

  Widget _buildFaceDetectSquare() {
    return SizedBox.expand(
      child: Stack(
        children: <Widget>[
          SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraint) {
                var height = constraint.maxHeight;
                var sizeDetectBox = constraint.maxWidth * faceDetectRatio;
                var minorSpace = 0.06;
                var horizontalSpace = constraint.maxWidth * ((1 - faceDetectRatio) / 2);
                var verticalSpace = ((height - sizeDetectBox) / 2);
                if (_cameraSize == null) _cameraSize = Size(constraint.maxWidth, constraint.maxHeight);
                return Stack(
                  children: <Widget>[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: verticalSpace,
                        color: _opacityColors,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: verticalSpace - minorSpace,
                      child: Container(
                        width: horizontalSpace,
                        height: sizeDetectBox,
                        color: _opacityColors,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: verticalSpace - minorSpace,
                      child: Container(
                        width: horizontalSpace,
                        height: sizeDetectBox,
                        color: _opacityColors,
                      ),
                    ),
                    Positioned(
                      top: verticalSpace - minorSpace,
                      bottom: (height - sizeDetectBox) / 2,
                      left: horizontalSpace - minorSpace,
                      right: horizontalSpace - minorSpace,
                      child: Container(
                        key: _detectFaceKey,
                        child: Stack(
                          overflow: Overflow.visible,
                          children: <Widget>[
                            _corner(context, left: 0, top: 0),
                            _corner(context, right: 0, top: 0, rotation: pi / 2),
                            _corner(context, left: 0, bottom: 0, rotation: -(pi / 2)),
                            _corner(context, right: 0, bottom: 0, rotation: pi),
                          ],
                        ),
                      ),
                    ),
                    _buildContentOverlay(verticalSpace, sizeDetectBox, horizontalSpace, minorSpace, constraint)
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(BuildContext context, {double top, double left, double right, double bottom, double rotation}) {
    return Positioned(
      left: left ?? null,
      top: top ?? null,
      right: right ?? null,
      bottom: bottom ?? null,
      child: Transform.rotate(
        angle: rotation ?? 0,
        child: Stack(
          children: <Widget>[
            Container(
                width: Utils.resizeWidthUtil(context, 115),
                height: Utils.resizeWidthUtil(context, 115),
                child: CustomPaint(
                  painter: CornerPainter(Utils.resizeWidthUtil(context, 30)),
                )),
            Image.asset(
              'images/img_corner.png',
              width: Utils.resizeWidthUtil(context, 115),
              height: Utils.resizeWidthUtil(context, 115),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildContentOverlay(double verticalSpace, double sizeDetectBox, double horizontalSpace, double minorSpace,
      BoxConstraints constraint) {
    return Positioned(
      left: 0,
      right: 0,
      top: verticalSpace + sizeDetectBox - minorSpace,
      height: verticalSpace,
      child: Container(
        height: (constraint.maxHeight - (constraint.maxWidth * faceDetectRatio)),
        width: double.infinity,
        padding: EdgeInsets.only(top: 20, left: horizontalSpace + 30, right: horizontalSpace + 30),
        alignment: Alignment.topCenter,
        color: _opacityColors,
        child: StreamBuilder(
          stream: _numFaces.stream,
          builder: (BuildContext context, snapshot) {
            if (snapshot.data != null && snapshot.data > 1)
              return Container(
                child: Text(
                  Utils.getString(context, txt_multi_faces_camera),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 36)),
                ),
              );
            if (snapshot.data != null && snapshot.data == 0)
              return Container(
                child: Text(
                  Utils.getString(context, txt_no_face),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 36)),
                ),
              );
            return Text(
              Utils.getString(context, txt_move_camera),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 36)),
            );
          },
        ),
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  double sizeCorner;

  CornerPainter(this.sizeCorner);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = _opacityColors;
    paint.style = PaintingStyle.fill;
    paint.strokeWidth = 10;

    var path = Path();

    path.moveTo(0, 0);
    path.lineTo(sizeCorner, 0);
    path.quadraticBezierTo(0, 0, 0, sizeCorner);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

/*Rect _reflectionRect(bool reflection, Rect boundingBox, Size size) {
  if (!reflection) {
    return boundingBox;
  }
  final centerX = size.width / 2;
  final left = ((boundingBox.left - centerX) * -1) + centerX;
  final right = ((boundingBox.right - centerX) * -1) + centerX;
  return Rect.fromLTRB(left, boundingBox.top, right, boundingBox.bottom);
}

Rect _scaleRect({
  @required Rect rect,
  @required Size imageSize,
  @required Size widgetSize,
}) {
  final scaleX = widgetSize.width / imageSize.width;
  final scaleY = widgetSize.height / imageSize.height;

  final scaledRect = defaultTargetPlatform == TargetPlatform.android
      ? Rect.fromLTRB(
          rect.left.toDouble() * scaleX,
          rect.top.toDouble() * scaleY,
          rect.right.toDouble() * scaleX,
          rect.bottom.toDouble() * scaleY,
        )
      : Rect.fromLTRB(
          widgetSize.width - rect.left.toDouble() * scaleX,
          rect.top.toDouble() * scaleY,
          widgetSize.width - rect.right.toDouble() * scaleX,
          rect.bottom.toDouble() * scaleY,
        );
  return scaledRect;*//*
}*/
