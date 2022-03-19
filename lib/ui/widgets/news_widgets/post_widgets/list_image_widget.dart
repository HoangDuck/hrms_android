import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/widgets/news_widgets/post_widgets/show_full_image_widget.dart';

import '../../../../core/router/router.dart';
import '../../../views/news/slider_images.dart';

Widget listImagesWidget(
    BuildContext context, List<String> list, int numberOfImages) {
  if (numberOfImages == 0) {
    return Container();
  } else if (numberOfImages == 1) {
    return Center(
      child: showImageWidget(context, list[0], numberOfImages),
    );
  } else if (numberOfImages == 2) {
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 2,
      // Generate 100 widgets that display their index in the List.
      children: List.generate(
        2,
        (index) {
          return Container(
            padding: EdgeInsets.all(2),
            child: showImageWidget(context, list[index], numberOfImages),
          );
        },
      ),
    );
  } else if (numberOfImages == 3) {
    return Column(
      children: [
        showImageWidget(context, list[0], numberOfImages),
        SizedBox(
          height: 2,
        ),
        GridView.count(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          // Create a grid with 2 columns. If you change the scrollDirection to
          // horizontal, this produces 2 rows.
          crossAxisCount: 2,
          // Generate 100 widgets that display their index in the List.
          children: List.generate(
            2,
            (index) {
              return Container(
                padding: EdgeInsets.all(2),
                child:
                    showImageWidget(context, list[index + 1], numberOfImages),
              );
            },
          ),
        ),
      ],
    );
  } else if (numberOfImages == 4) {
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 2,
      // Generate 100 widgets that display their index in the List.
      children: List.generate(
        list.length,
        (index) {
          return Container(
            padding: EdgeInsets.all(2),
            child: showImageWidget(context, list[index], numberOfImages),
          );
        },
      ),
    );
  } else if (numberOfImages > 4) {
    return GridView.count(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 2,
      // Generate 100 widgets that display their index in the List.
      children: List.generate(
        list.length,
        (index) {
          if (index == 3) {
            return Container(
              padding: EdgeInsets.all(2),
              child: Stack(
                children: [
                  showImageWidget(context, list[3], numberOfImages),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, Routers.listImagesView,arguments: {'title':'Bản tin'});
                      },
                      child: Container(
                        alignment: Alignment.center,
                        color: Colors.black38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 40,
                              color: Colors.white,
                            ),
                            Text(
                              "${numberOfImages - 4}",
                              style: TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Container(
            padding: EdgeInsets.all(2),
            child: showImageWidget(context, list[index], numberOfImages),
          );
        },
      ),
    );
  }
  return Container();
}

Widget showImageWidget(
    BuildContext context, String pathImage, int numberOfImages) {
  return GestureDetector(
    onTap: () {
      if (numberOfImages > 4) {
        Navigator.pushNamed(context, Routers.listImagesView,arguments: {'title':'Bản tin'});
        return;
      } else if (numberOfImages == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShowFullImageWidget(pathImage: pathImage),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SlideImages(),
        ),
      );
    },
    child: Image.network(
      pathImage,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stacktrace) {
        if (pathImage == "") {
          return Container();
        }
        return Image.file(
          File(pathImage),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stacktrace) {
            return Container();
          },
        );
      },
    ),
  );
}
