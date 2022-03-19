// import 'dart:math';
// import 'dart:typed_data';
//
// import 'package:camera/camera.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:image/image.dart' as imbLib;
// import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
//
// class FaceNetService {
//   static final FaceNetService _faceNetService = FaceNetService._internal();
//
//   factory FaceNetService() {
//     return _faceNetService;
//   }
//
//   FaceNetService._internal();
//
//   tflite.Interpreter _interpreter;
//
//   double threshold = 1.0;
//
//   List _predictedData;
//
//   List get predictedData => this._predictedData;
//
//   Future loadModel() async {
//     try {
//       final gpuDelegateV2 = tflite.GpuDelegateV2(
//           options: tflite.GpuDelegateOptionsV2(
//               false,
//               tflite.TfLiteGpuInferenceUsage.fastSingleAnswer,
//               tflite.TfLiteGpuInferencePriority.minLatency,
//               tflite.TfLiteGpuInferencePriority.auto,
//               tflite.TfLiteGpuInferencePriority.auto));
//
//       var interpreterOptions = tflite.InterpreterOptions()
//         ..addDelegate(gpuDelegateV2);
//       this._interpreter = await tflite.Interpreter.fromAsset(
//           'mobilefacenet.tflite',
//           options: interpreterOptions);
//       print('model loaded successfully');
//     } catch (e) {
//       print('Failed to load model.');
//       print(e);
//     }
//   }
//
//   setCurrentPrediction(CameraImage cameraImage, Face face) async {
//     dynamic inputDynamic = await _preProcess(cameraImage, face);
//     List input = inputDynamic['imageAsList'];
//     //List input = await _preProcess(cameraImage, face);
//
//     input = input.reshape([1, 112, 112, 3]);
//     List output = List(1 * 192).reshape([1, 192]);
//
//     this._interpreter.run(input, output);
//     output = output.reshape([192]);
//
//     this._predictedData = List.from(output);
//
//     return inputDynamic['image'];
//   }
//
//   dynamic predict(List predictedData) {
//     return _searchResult(predictedData);
//   }
//
//   Future<dynamic> _preProcess(CameraImage image, Face face) async {
//     dynamic croppedImage = _cropFace(image, face);
//     imbLib.Image img = imbLib.copyResizeCropSquare(croppedImage['imageCrop'], 112);
//
//     imbLib.Image imgShow = imbLib.copyResizeCropSquare(croppedImage['imageFull'], 448);
//     Float32List imageAsList = imageToByteListFloat32(img);
//
//     return {'imageAsList': imageAsList, 'image': imbLib.encodePng(imgShow)};
//   }
//
//   _cropFace(CameraImage image, Face faceDetected) {
//     imbLib.Image convertedImage = _convertCameraImage(image);
//     double x = faceDetected.boundingBox.left - 10.0;
//     double y = faceDetected.boundingBox.top - 10.0;
//     double w = faceDetected.boundingBox.width + 10.0;
//     double h = faceDetected.boundingBox.height + 10.0;
//     return {
//       'imageCrop': imbLib.copyCrop(
//           convertedImage, x.round(), y.round(), w.round(), h.round()),
//       'imageFull': convertedImage
//     };
//   }
//
//   imbLib.Image _convertCameraImage(CameraImage image) {
//     int width = image.width;
//     int height = image.height;
//     var img = imbLib.Image(width, height);
//     const int hexFF = 0xFF000000;
//     final int uvyButtonStride = image.planes[1].bytesPerRow;
//     final int uvPixelStride = image.planes[1].bytesPerPixel;
//     for (int x = 0; x < width; x++) {
//       for (int y = 0; y < height; y++) {
//         final int uvIndex =
//             uvPixelStride * (x / 2).floor() + uvyButtonStride * (y / 2).floor();
//         final int index = y * width + x;
//         final yp = image.planes[0].bytes[index];
//         final up = image.planes[1].bytes[uvIndex];
//         final vp = image.planes[2].bytes[uvIndex];
//         int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
//         int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
//             .round()
//             .clamp(0, 255);
//         int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
//         img.data[index] = hexFF | (b << 16) | (g << 8) | r;
//       }
//     }
//     var img1 = imbLib.copyRotate(img, -90);
//     return img1;
//   }
//
//   Float32List imageToByteListFloat32(imbLib.Image image) {
//     var convertedBytes = Float32List(1 * 112 * 112 * 3);
//     var buffer = Float32List.view(convertedBytes.buffer);
//     int pixelIndex = 0;
//
//     for (var i = 0; i < 112; i++) {
//       for (var j = 0; j < 112; j++) {
//         var pixel = image.getPixel(j, i);
//         buffer[pixelIndex++] = (imbLib.getRed(pixel) - 128) / 128;
//         buffer[pixelIndex++] = (imbLib.getGreen(pixel) - 128) / 128;
//         buffer[pixelIndex++] = (imbLib.getBlue(pixel) - 128) / 128;
//       }
//     }
//     return convertedBytes.buffer.asFloat32List();
//   }
//
//   dynamic _searchResult(List predictedData) {
//     double minDist = 999;
//     double currDist = 0.0;
//     bool match = false;
//
//     currDist = _euclideanDistance(this.predictedData, predictedData);
//     if (currDist <= threshold && currDist < minDist) {
//       minDist = currDist;
//       match = true;
//     }
//     return {
//       'result': match,
//       'value': currDist
//     };
//   }
//
//   double _euclideanDistance(List e1, List e2) {
//     double sum = 0.0;
//     for (int i = 0; i < e1.length; i++) {
//       sum += pow((e1[i] - e2[i]), 2);
//     }
//     return sqrt(sum);
//   }
//
//   void setPredictedData(value) {
//     this._predictedData = value;
//   }
// }
