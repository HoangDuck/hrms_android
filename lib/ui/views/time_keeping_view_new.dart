import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:path/path.dart' as PATH;
import 'package:path_provider/path_provider.dart';

import '../../core/base/base_response.dart';
import '../../core/components/camera_custom.dart';
import '../../core/enums/timekeeping_type.dart';
import '../../core/router/router.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/util/utils.dart';
import '../constants/app_colors.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/tk_text.dart';
import 'check_location_view.dart';
import 'main_view.dart';
import 'package:provider/provider.dart';

final _opacityColors = Colors.black.withOpacity(0.6);
final mediumFaceRatio = 0.86;
final highFaceRatio = 0.86;

class TimeKeepingViewNew extends StatefulWidget {
  final CameraArgument arguments;

  TimeKeepingViewNew(this.arguments);

  @override
  _TimeKeepingViewNewState createState() => _TimeKeepingViewNewState();
}

class _TimeKeepingViewNewState extends State<TimeKeepingViewNew> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController controller;
  List<CameraDescription> cameras;
  double faceDetectRatio;
  Size _cameraSize;
  GlobalKey _detectFaceKey = GlobalKey();
  bool isAutoDetect = true;
  var _user;
  AnimationController _controllerRotate;
  Timer _timer;
  bool _isShowCountDown = false;
  var _cropTimes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkAutoDetect();
    if (widget.arguments.deviceBrand.contains('samsung'))
      faceDetectRatio = mediumFaceRatio;
    else
      faceDetectRatio = highFaceRatio;
  }

  @override
  void dispose() {
    if (!isAutoDetect) _controllerRotate.dispose();
    if (_timer != null) _timer.cancel();
    if (controller != null) {
      controller.dispose();
    }
    controller = null;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TimeKeepingViewNew oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (controller != null) {
      onNewCameraSelected(controller.description);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
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
          await captureClick(context);
        } else {
          countDownAuto--;
        }
      },
    );
  }

  _initializeCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[1], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      kIsWeb ? ResolutionPreset.max : ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    controller = cameraController;

    // If the controller is updated then update the UI.
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {
        debugPrint('Camera error ${cameraController.value.errorDescription}');
      }
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      debugPrint('Camera error $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  updateChange(bool value) async {
    _user.data['data'][0]['Timekeeping_IsFaceAuto']['v'] = value ? 'True' : 'False';
    await SecureStorage().saveProfileCustomer(_user);
    context.read<BaseResponse>().addData(_user.data);
  }

  Future<void> captureClick(BuildContext context) async {
    if (controller != null && mounted) {
      try {
        bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
        double ratio = widget.arguments.deviceBrand.contains('samsung') ? mediumFaceRatio : highFaceRatio;
        XFile image;
        try {
          // await Future.delayed(Duration(milliseconds: 50));
          image = await controller.takePicture();
        } catch (e) {
          debugPrint('Take picture error: $e');
          await controller.initialize();
          // await Future.delayed(Duration(milliseconds: 200));
          image = await controller.takePicture();
        }
        _cropImage(image, context, isAndroid, ratio);
      } on PlatformException catch (e) {
        debugPrint('$e');
      }
    }
  }

  _cropImage(XFile image, BuildContext context, bool isAndroid, double ratio, {bool rotation = false}) async {
    if (mounted) {
      // if (!isAndroid) Future.delayed(Duration(milliseconds: 200));
      await Navigator.pushReplacementNamed(context, Routers.checkLocation,
          arguments: CameraArgument(
              path: File(image.path),
              deviceBrand: widget.arguments.deviceBrand,
              timekeepingType: TimekeepingType.Face));
      if (controller != null) controller.dispose();
    }
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
            backgroundColor: _opacityColors,
            leading: InkWell(
              onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: Utils.resizeWidthUtil(context, app_bar_icon_size),
              ),
            ),
            systemOverlayStyle: SystemUiOverlayStyle.light),
        body: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              children: <Widget>[
                controller != null && controller.value.isInitialized
                    ? Transform.scale(
                        scale: 1 / (controller.value.aspectRatio * MediaQuery.of(context).size.aspectRatio),
                        alignment: Alignment.center,
                        child: CameraPreview(controller))
                    : Center(
                        child: CircularProgressIndicator(),
                      ),
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
                          clipBehavior: Clip.none,
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
            await captureClick(context);
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
          color: _opacityColors),
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
