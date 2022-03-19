import 'package:meta/meta.dart';

/// Represents the size object
@immutable
class Size {
  /// Creates [Size] from width and height
  const Size({
     this.height,
     this.width,
  });

  /// Height
  final double height;

  /// Width
  final double width;
}
