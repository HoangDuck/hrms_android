library flutter_camera_ml_vision;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
// import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:gsot_timekeeping/core/enums/timekeeping_type.dart';
import 'package:gsot_timekeeping/core/router/router.dart';
import 'package:gsot_timekeeping/ui/views/check_location_view.dart';
import 'package:gsot_timekeeping/ui/views/time_keeping_view.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

export 'package:camera/camera.dart';

// typedef HandleDetection<T> = Future<T> Function(FirebaseVisionImage image);
typedef Widget ErrorWidgetBuilder(BuildContext context, CameraError error);

enum CameraError {
  unknown,
  cantInitializeCamera,
  androidVersionNotSupported,
  noCameraAvailable,
}

enum _CameraState {
  loading,
  error,
  ready,
}

class CameraMlVision<T> extends StatefulWidget {
  //final HandleDetection<T> detector;
  // final Function/*(T)*/ onResult;
  final WidgetBuilder loadingBuilder;
  final ErrorWidgetBuilder errorBuilder;
  final WidgetBuilder overlayBuilder;
  final CameraLensDirection cameraLensDirection;
  final ResolutionPreset resolution;
  final Function onDispose;
  final String deviceBrand;
  final Function(int faces) reCapture;
  //final String mqtt;

  CameraMlVision({
    Key key,
    // @required this.onResult,
    //@required this.detector,
    this.loadingBuilder,
    this.errorBuilder,
    this.overlayBuilder,
    this.cameraLensDirection = CameraLensDirection.back,
    this.resolution,
    this.onDispose,
    this.deviceBrand,
    this.reCapture,
    //this.mqtt
  }) : super(key: key);

  @override
  CameraMlVisionState createState() => CameraMlVisionState<T>();
}

class CameraMlVisionState<T> extends State<CameraMlVision<T>>
    with WidgetsBindingObserver {
  String lastImage;
  Key _visibilityKey = UniqueKey();
  CameraController cameraController;
  // ImageRotation _rotation;
  _CameraState _cameraMlVisionState = _CameraState.loading;
  CameraError _cameraError = CameraError.unknown;
  bool _alreadyCheckingImage = false;
  bool isStreaming = false;
  bool _isDeactivate = false;
  var _cropTimes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void didUpdateWidget(CameraMlVision<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolution != widget.resolution) {
      initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed && isStreaming) {
      initialize();
    }
  }

  Future<void> captureAuto(BuildContext context, Rect faceDetectRect) async {
    if (cameraController != null && mounted) {
      try {
        bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
        cameraController.stopImageStream();
        final path = join(
          (await getTemporaryDirectory()).path,
          '${DateTime.now().millisecondsSinceEpoch}.png',
        );
        _handleCapture(context, path, isAndroid);
      } on PlatformException catch (e) {
        debugPrint('$e');
      }
    }
  }

  Future<void> captureClick(BuildContext context, Rect faceDetectRect) async {
    if (cameraController != null && mounted) {
      try {
        bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
        cameraController.stopImageStream();
        final path = join(
          (await getTemporaryDirectory()).path,
          '${DateTime.now().millisecondsSinceEpoch}.png',
        );
        double ratio = widget.deviceBrand.contains('samsung')
            ? mediumFaceRatio
            : highFaceRatio;
        try {
          await Future.delayed(Duration(milliseconds: 50));
          XFile picture = await cameraController.takePicture();
          picture.saveTo(path);
          //await cameraController.takePicture(path);
        } catch (e) {
          debugPrint('Take picture error: $e');
          await cameraController.initialize();
          await Future.delayed(Duration(milliseconds: 200));
          XFile picture = await cameraController.takePicture();
          picture.saveTo(path);
          // await cameraController.takePicture(path);
        }
        _cropImage(path, context, isAndroid, ratio);
      } on PlatformException catch (e) {
        debugPrint('$e');
      }
    }
  }

  _handleCapture(BuildContext context, String path, bool isAndroid) async {
    double ratio = widget.deviceBrand.contains('samsung')
        ? mediumFaceRatio
        : highFaceRatio;
    try {
      await Future.delayed(Duration(milliseconds: 50));
      XFile picture = await cameraController.takePicture();
      picture.saveTo(path);
      // await cameraController.takePicture(path);
    } catch (e) {
      debugPrint('Take picture error: $e');
      await cameraController.initialize();
      await Future.delayed(Duration(milliseconds: 200));
      XFile picture = await cameraController.takePicture();
      picture.saveTo(path);
      // await cameraController.takePicture(path);
    }
    /*if (isAndroid)
      _checkFace(path, isAndroid, ratio, context);
    else*/
    _cropImage(path, context, isAndroid, ratio);
  }

  /*_checkFace(
      String path, bool isAndroid, double ratio, BuildContext context) async {
    // final image = FirebaseVisionImage.fromFile(File(path));
    final faceDetector = FirebaseVision.instance.faceDetector();
    await faceDetector.processImage(image).then((faces) async {
      if (faces.length > 1) {
        _reCapture(path, isAndroid, faces.length);
      } else if (faces.length == 0) {
        _reCapture(path, isAndroid, faces.length);
      } else {
        _cropImage(path, context, isAndroid, ratio);
      }
    });
  }*/

  /*_reCapture(String path, bool isAndroid, int length) async {
    final dir = Directory(path);
    dir.deleteSync(recursive: true);
    cameraController.startImageStream(_processImage);
    if (widget.reCapture != null) {
      widget.reCapture(length);
    }
  }*/

  _cropImage(String path, BuildContext context, bool isAndroid, double ratio,
      {bool rotation = false}) async {
    File image = new File(path);
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
          path, rotation ? top : left, rotation ? left : top, size, size)
          .then((cropFile) async {
        if (cropFile != null && path != null && File(path).existsSync()) {
          await File(path).delete();
        }
        if (!isAndroid) Future.delayed(Duration(milliseconds: 200));
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routers.checkLocation,
              arguments: CameraArgument(
                  path: cropFile, deviceBrand: widget.deviceBrand, timekeepingType: TimekeepingType.Face/*, mqtt: widget.mqtt*/));
          cameraController.dispose();
          _cropTimes = 0;
        }
      }).catchError((onError) {
        debugPrint('Crop image error: $onError');
        if (_cropTimes < 1) {
          _cropImage(path, context, isAndroid, ratio, rotation: true);
          _cropTimes++;
        } else {
          Navigator.pop(context);
          _cropTimes = 0;
        }
      });
    }
  }

  /*void _stop(bool silently) {
    scheduleMicrotask(() async {
      if (cameraController?.value?.isStreamingImages == true && mounted) {
        await cameraController.stopImageStream().catchError((_) {});
      }

      if (silently) {
        isStreaming = false;
      } else {
        setState(() {
          isStreaming = false;
        });
      }
    });
  }*/

  void start() {
    if (cameraController != null && !isStreaming) {
      _start();
    }
  }

  void _start() {
    cameraController.startImageStream(_processImage);
    setState(() {
      isStreaming = true;
    });
  }

  CameraValue get cameraValue => cameraController?.value;

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 21) {
        debugPrint('Camera plugin doesn\'t support android under version 21');
        if (mounted) {
          setState(() {
            _cameraMlVisionState = _CameraState.error;
            _cameraError = CameraError.androidVersionNotSupported;
          });
        }
        return;
      }
    }

    CameraDescription description =
    await _getCamera(widget.cameraLensDirection);
    if (description == null) {
      _cameraMlVisionState = _CameraState.error;
      _cameraError = CameraError.noCameraAvailable;

      return;
    }
    await cameraController?.dispose();
    cameraController = CameraController(
      description,
      _getSolution(),
      enableAudio: false,
    );
    if (!mounted) {
      return;
    }

    try {
      await cameraController.initialize();
    } catch (ex, stack) {
      debugPrint('Can\'t initialize camera');
      debugPrint('$ex, $stack');
      if (mounted) {
        setState(() {
          _cameraMlVisionState = _CameraState.error;
          _cameraError = CameraError.cantInitializeCamera;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _cameraMlVisionState = _CameraState.ready;
    });
    /*_rotation = _rotationIntToImageRotation(
      description.sensorOrientation,
    );*/

    //FIXME hacky technique to avoid having black screen on some android devices
    await Future.delayed(Duration(milliseconds: 200));

    start();
  }

  ResolutionPreset _getSolution() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      if (widget.deviceBrand.contains('samsung'))
        return ResolutionPreset.medium;
      else
        return ResolutionPreset.high;
    } else {
      if (widget.deviceBrand.contains('iPhone')) {
        String deviceMachineNum =
        widget.deviceBrand.replaceAll('iPhone', '').replaceAll(',', '.');
        if (double.parse(deviceMachineNum) >= 10.1) {
          return ResolutionPreset.high;
        } else if (double.parse(deviceMachineNum) <= 10.1 &&
            double.parse(deviceMachineNum) >= 9.1) {
          return ResolutionPreset.medium;
        } else {
          return ResolutionPreset.low;
        }
      } else {
        return ResolutionPreset.medium;
      }
    }
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose();
    }
    if (lastImage != null && File(lastImage).existsSync()) {
      File(lastImage).delete();
    }
    if (cameraController != null) {
      cameraController.dispose();
    }
    cameraController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraMlVisionState == _CameraState.loading) {
      return widget.loadingBuilder == null
          ? Center(child: CircularProgressIndicator())
          : widget.loadingBuilder(context);
    }
    if (_cameraMlVisionState == _CameraState.error) {
      return widget.errorBuilder == null
          ? Center(child: Text('$_cameraMlVisionState $_cameraError'))
          : widget.errorBuilder(context, _cameraError);
    }

    Widget cameraPreview = AspectRatio(
      aspectRatio: cameraController.value.aspectRatio,
      child: isStreaming
          ? CameraPreview(
        cameraController,
      )
          : _getPicture(),
    );
    if (widget.overlayBuilder != null) {
      cameraPreview = Stack(
        fit: StackFit.passthrough,
        children: [
          cameraPreview,
          widget.overlayBuilder(context),
        ],
      );
    }
    return /*VisibilityDetector(
      child: */FittedBox(
      alignment: Alignment.center,
      fit: BoxFit.cover,
      child: SizedBox(
        width: cameraController.value.previewSize.height *
            cameraController.value.aspectRatio,
        height: cameraController.value.previewSize.height,
        child: cameraPreview,
      ),
    )/*,
      onVisibilityChanged: (VisibilityInfo info) {
        if (info.visibleFraction == 0) {
          //invisible stop the streaming
          _isDeactivate = true;
          _stop(true);
        } else if (_isDeactivate) {
          //visible restart streaming if needed
          _isDeactivate = false;
          _start();
        }
      },
      key: _visibilityKey,
    )*/;
  }

  void _processImage(CameraImage cameraImage) async {
    /*if (defaultTargetPlatform == TargetPlatform.iOS)
      await Future.delayed(Duration(milliseconds: 200));
    *//*if (!_alreadyCheckingImage && mounted) {
      _alreadyCheckingImage = true;
      try {
        final T results =
            await _detect<T>(cameraImage, widget.detector, _rotation);*//*
        widget.onResult(*//*results*//*);
      *//*} catch (ex, stack) {
        debugPrint('$ex, $stack');
      }
      _alreadyCheckingImage = false;
    }*/
  }

  Widget _getPicture() {
    if (lastImage != null) {
      final file = File(lastImage);
      if (file.existsSync()) {
        return Image.file(file);
      }
    }

    return Container();
  }
}

Future<CameraDescription> _getCamera(CameraLensDirection dir) async {
  return await availableCameras().then(
        (cameras) => cameras.firstWhere(
          (camera) => camera.lensDirection == dir,
      orElse: () => cameras.isNotEmpty ? cameras.first : null,
    ),
  );
}

Uint8List _concatenatePlanes(List<Plane> planes) {
  final WriteBuffer allBytes = WriteBuffer();
  planes.forEach((plane) => allBytes.putUint8List(plane.bytes));
  return allBytes.done().buffer.asUint8List();
}

/*FirebaseVisionImageMetadata buildMetaData(
  CameraImage image,
  ImageRotation rotation,
) {
  return FirebaseVisionImageMetadata(
    rawFormat: image.format.raw,
    size: Size(image.width.toDouble(), image.height.toDouble()),
    rotation: rotation,
    planeData: image.planes
        .map(
          (plane) => FirebaseVisionImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          ),
        )
        .toList(),
  );
}*/

/*Future<T> _detect<T>(
  CameraImage image,
  HandleDetection<T> handleDetection,
  ImageRotation rotation,
) async {
  return handleDetection(
    FirebaseVisionImage.fromBytes(
      _concatenatePlanes(image.planes),
      buildMetaData(image, rotation),
    ),
  );
}

ImageRotation _rotationIntToImageRotation(int rotation) {
  switch (rotation) {
    case 0:
      return ImageRotation.rotation0;
    case 90:
      return ImageRotation.rotation90;
    case 180:
      return ImageRotation.rotation180;
    default:
      assert(rotation == 270);
      return ImageRotation.rotation270;
  }
}*/
