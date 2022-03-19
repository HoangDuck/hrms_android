import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/constants/app_images.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';

class ShowImageView extends StatelessWidget {

  final image;
  final type;

  ShowImageView({this.image, this.type = 'url'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBarCustom(context, () => Navigator.pop(context), () => {}, '', null, hideBackground: true),
      body: Container(
        margin: EdgeInsets.only(left: Utils.resizeWidthUtil(context, 30), right: Utils.resizeWidthUtil(context, 30)),
        child: Center(
          child: type == 'url' ? AspectRatio(
            aspectRatio: 1 / 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  Utils.resizeWidthUtil(context, 10)),
              child: FadeInImage.assetNetwork(
                  fit: BoxFit.cover,
                  placeholder: avatar_default,
                  image: image),
            ),
          ) : Image.file(image),
        ),
      ),
    );
  }
}
