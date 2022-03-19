import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:gsot_timekeeping/core/enums/timekeeping_type.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_strings.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/widgets/tk_text.dart';
import 'package:path_provider/path_provider.dart';

final mediumFaceRatio = 0.86;
final highFaceRatio = 0.86;

class QRCodeScanView extends StatefulWidget {
  final CameraArgument arguments;

  QRCodeScanView(this.arguments);

  @override
  _QRCodeScanViewState createState() => _QRCodeScanViewState();
}

class _QRCodeScanViewState extends State<QRCodeScanView> {
  CameraController cameraController;
  List cameras;
  int selectedCameraIndex;
  Timer _timer;
  String _barcodeRead = "";
  bool scanNull = false;
  bool redEnable = false;
  BarcodeScanner barcodeScanner = GoogleMlKit.vision.barcodeScanner();

  @override
  void initState() {
    super.initState();
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {});
      } else {
        print('No camera available');
      }
      _startTimer();
    }).catchError((e) {
      print('Error : ${e.code}');
    });
  }

  void _startTimer() {
    _timer = new Timer(Duration(milliseconds: 1000), _timerElapsed);
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  Future<void> _timerElapsed() async {
    _stopTimer();
    File file = await _takePicture();
    await _readBarcode(file);
    var decodedImage = await decodeImageFromList(file.readAsBytesSync());
    bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    int height = decodedImage.height > decodedImage.width
        ? decodedImage.height
        : decodedImage.width;
    int width = decodedImage.width > decodedImage.height
        ? decodedImage.height
        : decodedImage.width;
    double ratio = widget.arguments.deviceBrand.contains('samsung')
        ? mediumFaceRatio
        : highFaceRatio;
    var left = isAndroid
        ? (height - (width * ratio)) ~/ 2
        : (width * (1 - ratio)) ~/ 2;
    var top = isAndroid
        ? (width * (1 - ratio)) ~/ 2
        : (height - (width * ratio)) ~/ 2;
    var size = (width * ratio).toInt();
    if (_barcodeRead != "" && !scanNull && file.path.isNotEmpty) {
      if (mounted) {
        await FlutterNativeImage.cropImage(
            file.path, left, top, size, size)
            .then((cropFile) async {
          if (cropFile != null && file.path != null && File(file.path).existsSync()) {
            await File(file.path).delete();
          }
          if (!isAndroid) Future.delayed(Duration(milliseconds: 200));
          Navigator.pushReplacementNamed(context, Routers.checkLocation,
              arguments: CameraArgument(
                  path: cropFile,
                  timekeepingType: TimekeepingType.QRCode,
                  deviceBrand: _barcodeRead));
          cameraController.dispose();
        }).catchError((onError) {
          debugPrint('Crop image error: $onError');
        });
      }
    }
    _startTimer();
  }

  Future _readBarcode(File file) async {
    final barCodes = await barcodeScanner.processImage(InputImage.fromFile(file));

    /*FirebaseVisionImage firebaseImage = FirebaseVisionImage.fromFile(file);
    final BarcodeDetector barcodeDetector =
    FirebaseVision.instance.barcodeDetector();
    final List<Barcode> barCodes =
    await barcodeDetector.detectInImage(firebaseImage);*/
    if (barCodes.isEmpty) {
      setState(() {
        scanNull = true;
      });
    }
    _barcodeRead = "";
    for (Barcode barcode in barCodes) {
      if (barcode.type != BarcodeType.values[0]) {
        if (!barcode.value.rawValue.contains("typeNumber")) {
          print(barcode.type.name);
          if (_barcodeRead != "") {
            setState(() {
              scanNull = false;
              _barcodeRead = "";
              _barcodeRead += barcode.value.rawValue;
            });
          } else
            setState(() {
              scanNull = false;
              _barcodeRead += barcode.value.rawValue;
            });
        }
      }
    }
  }

  Future initCamera(CameraDescription cameraDescription) async {
    cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);
    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    try {
      await cameraController.initialize();
    } catch (e) {
      print('Error ${e.code} \nError message: ${e.description}');
    }
    if (mounted) {
      setState(() {});
    }
  }

  getCameraLensIcons(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
      case CameraLensDirection.external:
        return CupertinoIcons.photo_camera;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  void dispose() {
    if (cameraController != null) {
      cameraController.dispose();
    }
    cameraController = null;
    super.dispose();
  }

  Future<File> _takePicture() async {
    Directory extDir = await getApplicationDocumentsDirectory();
    String dirPath = '${extDir.path}/Pictures/barcode';
    await Directory(dirPath).create(recursive: true);
    String timestamp() =>
        DateTime
            .now()
            .millisecondsSinceEpoch
            .toString();
    File file = File('$dirPath/${timestamp()}.jpg');
    // await cameraController.takePicture(file.path);
    XFile picture = await cameraController.takePicture();
    picture.saveTo(file.path);
    if(_barcodeRead != '')
      cameraController.dispose();
    return file;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        brightness: Brightness.dark,
        leading: InkWell(
          onTap: () =>
              Navigator.pushNamedAndRemoveUntil(
                  context, Routers.main, (r) => false),
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: Utils.resizeWidthUtil(context, 40),
          ),
        )),
    body: Container(
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: cameraPreview(),
          ),
          Container(
              alignment: Alignment.bottomCenter,
              margin: EdgeInsets.only(bottom: 50),
              child: TKText(
                Utils.getString(context, txt_no_barcode),
                style: TextStyle(color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 28)),
              )),
        ],
      ),
    ),
  );
}

Widget cameraPreview() {
  if (cameraController == null || !cameraController.value.isInitialized) {
    return TKText(
      'Loading',
      tkFont: TKFont.SFProDisplayMedium,
      style: TextStyle(
          color: Colors.white, fontSize: Utils.resizeWidthUtil(context, 28), fontWeight: FontWeight.bold),
    );
  }
  return Stack(
    alignment: FractionalOffset.center,
    children: [
      Positioned.fill(
          child: AspectRatio(
            aspectRatio: cameraController.value.aspectRatio,
            child: CameraPreview(cameraController),
          )),
      IgnorePointer(
        child: ClipPath(
          clipper: InvertedCircleClipper(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
        ),
      ),
      CustomPaint(
        painter: Painter(),
        child: ClipPath(
          clipper: InvertedCircleClipper1(),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Color.fromRGBO(0, 0, 0, 0.5),
          ),
        ),
      )
    ],
  );
}}

class InvertedCircleClipper extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.65);
    path.lineTo(size.width * 0.1, size.height * 0.65);
    path.fillType = PathFillType.evenOdd;
    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class InvertedCircleClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.65);
    path.lineTo(size.width * 0.1, size.height * 0.65);
    path.fillType = PathFillType.evenOdd;
    path.addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height));
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class Painter extends CustomPainter {
  bool fade = true;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Offset(size.width * 0.12, size.height * 0.31);
    final p2 = Offset(size.width * 0.2, size.height * 0.31);
    final p3 = Offset(size.width * 0.12,
        size.height * 0.31 + (size.width * 0.2 - size.width * 0.12));

    final p4 = Offset(size.width * 0.8, size.height * 0.31);
    final p5 = Offset(size.width * 0.88, size.height * 0.31);
    final p6 = Offset(size.width * 0.88,
        size.height * 0.31 + (size.width * 0.2 - size.width * 0.12));

    final p7 = Offset(size.width * 0.88,
        size.height * 0.64 - (size.width * 0.2 - size.width * 0.12));
    final p8 = Offset(size.width * 0.88, size.height * 0.64);
    final p9 = Offset(size.width * 0.8, size.height * 0.64);

    final p10 = Offset(size.width * 0.12,
        size.height * 0.64 - (size.width * 0.2 - size.width * 0.12));
    final p11 = Offset(size.width * 0.12, size.height * 0.64);
    final p12 = Offset(size.width * 0.2, size.height * 0.64);
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final paint1 = Paint()
      ..color = Colors.red
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final p13 = Offset(size.width * 0.12, size.height * 0.480);
    final p14 = Offset(size.width * 0.88, size.height * 0.480);
    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p3, p1, paint);
    canvas.drawLine(p5, p4, paint);
    canvas.drawLine(p5, p6, paint);
    canvas.drawLine(p8, p7, paint);
    canvas.drawLine(p8, p9, paint);
    canvas.drawLine(p11, p10, paint);
    canvas.drawLine(p11, p12, paint);
    if (fade) canvas.drawLine(p13, p14, paint1);
  }

  @override
  bool shouldRepaint(Painter oldDelegate) {
    return fade = !fade;
  }
}
