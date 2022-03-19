import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/animation/expand_collapse_animation.dart';
import '../../../core/animation/reaction_animation.dart';
import '../../../core/util/utils.dart';
import '../../widgets/app_bar_custom.dart';
import '../../widgets/news_widgets/dottedline.dart';
import '../../widgets/news_widgets/post_widgets/comment_to_post_widget.dart';
import '../../widgets/news_widgets/post_widgets/share_post.dart';
import '../../widgets/news_widgets/post_widgets/textform_comment.dart';
import '../../widgets/news_widgets/reaction_post_statistic_widget.dart';
import 'slider_images.dart';

class ListImagePage extends StatefulWidget {
  final dynamic data;
  ListImagePage(this.data);

  @override
  _ListImagePageState createState() => _ListImagePageState();
}

class _ListImagePageState extends State<ListImagePage> {
  //Scroll controller
  ScrollController listImagesController;

  //number of images
  int numberOfImages = 0;

  //list images path string
  List<String> listImagePaths = [];

  //current post content
  dynamic currentPost = {};

  //current index
  int currentIndex = 0;

  _scrollListenerListImages() {
    if (listImagesController.position.pixels ==
        listImagesController.position.maxScrollExtent) {
      if (listImagePaths.length < numberOfImages) {
        setState(() {
          //currentIndex += 10;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    //initiate scroll controller
    listImagesController = ScrollController();
    listImagesController.addListener(() {
      _scrollListenerListImages();
    });
    //fetch number of images
    numberOfImages = 6;
    //fetch list path images
    listImagePaths.addAll([
      "https://raw.githubusercontent.com/Sameera-Perera/flutter-carousel-slider-example/master/home.png",
      "https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80",
      "http://www.androidcoding.in/wp-content/uploads/flutter_image_slider-1024x1024.png",
      "https://raw.githubusercontent.com/Sameera-Perera/flutter-carousel-slider-example/master/home.png",
      "https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80",
      "http://www.androidcoding.in/wp-content/uploads/flutter_image_slider-1024x1024.png",
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBarCustom(context, () {
          Utils.closeKeyboard(context);
          Navigator.pop(context, 0);
        }, () {
          Utils.closeKeyboard(context);
        }, widget.data['title'], null),
      body: ListView.builder(
        itemCount: listImagePaths.length + 1,
        scrollDirection: Axis.vertical,
        controller: listImagesController,
        itemBuilder: (context, i) {
          if (i == 0) {
            return PageHeader();
          } else if (i == listImagePaths.length) {
            return Column(
              children: [
                ItemListImage(
                  pathImage: listImagePaths[i - 1],
                ),
                Container(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(
                    color: only_color,
                  ),
                ),
              ],
            );
          }
          return ItemListImage(
            pathImage: listImagePaths[i - 1],
          );
        },
      ),
    );
  }
}

class PageHeader extends StatefulWidget {
  const PageHeader({Key key}) : super(key: key);

  @override
  PageHeaderState createState() => PageHeaderState();
}

class PageHeaderState extends State<PageHeader> with TickerProviderStateMixin {
  //current user
  dynamic currentUser;

  //current post
  dynamic currentPost;

  //list reaction icon of this post
  List<String> listReactionIcons = [];
  int numberOfReaction = 0;

  //number of sharing post
  int numberOfSharing = 0;

  //field comment data
  List<Widget> listCommentWidgets = [];
  List<dynamic> listCommentData = []; //list comment data
  int numberOfComment = 0; //request api give back number of comment this.post
  //number comments of this post is replies
  int numberOfRepliesPost = 0;

  //show comment box
  ExpandCollapseAnimation expandCollapseAnimation;

  //animation reaction button
  ReactionAnimation reactionAnimation;

  @override
  void initState() {
    super.initState();
    //get current user
    currentUser = {
      'image':
          "https://storage.googleapis.com/support-kms-prod/ZAl1gIwyUsvfwxoW9ns47iJFioHXODBbIkrK",
      'name': 'Hoàng Đức',
      'nickname': '@duckute',
    };
    //get current post
    currentPost = {
      'content': 'Hello world',
    };
    //fetch number of comment
    numberOfComment = 0;
    //fetch list and number of reactions
    listReactionIcons.addAll([]);
    numberOfReaction = 0;
    //fetch number of sharing
    numberOfSharing = 0;
    //fetch list reaction icons
    listReactionIcons.addAll([]);
    //fetch number of replies post
    numberOfRepliesPost = 0;
    //fetch number of comments
    numberOfComment = 0;
    //fetch 2 first comments
    listCommentData = [];

    //init animation show comment box
    expandCollapseAnimation = ExpandCollapseAnimation(state: this);
    //init animation reaction animation
    reactionAnimation = ReactionAnimation(context, state: this);
    //fetch which icon user choose
    reactionAnimation.whichIconUserChoose = 0;
    reactionAnimation.previousWhichIconUserChoose =
        reactionAnimation.whichIconUserChoose;
  }

  @override
  void dispose() {
    super.dispose();
    reactionAnimation.disposeAnimationReaction();
  }

  void addComment(dynamic comment) {
    numberOfComment++;
    listCommentData.add(comment);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: this,
      child: GestureDetector(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.only(
                              left: 10,
                              right: 10,
                            ),
                            child: SizedBox(
                              height: 55,
                              width: 55,
                              child: CircleAvatar(
                                radius: 30.0,
                                backgroundImage: NetworkImage(
                                  currentUser['image'],
                                ),
                                backgroundColor: only_color,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentUser['name'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                      color: gradient_start_color,
                                    ),
                                  ),
                                  Text(
                                    currentUser['nickname'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: only_color,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(15),
                        child: Text(
                          currentPost['content'],
                          style: TextStyle(
                            fontSize: 20,
                            color: txt_grey_color_v3,
                          ),
                        ),
                      ),
                      dottedLine(context),
                      Row(
                        children: [
                          Expanded(
                            child: ReactionStatisticWidget(
                              listOfReactionsIcon: listReactionIcons,
                              numberReaction: numberOfReaction,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                LineIcons.commentDots,
                                color: txt_grey_color_v1,
                              ),
                              Text(
                                "${Utils.formatNumberReaction(numberOfComment)} Comments",
                                style: TextStyle(
                                  color: txt_grey_color_v1,
                                ),
                              )
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Icon(
                                  LineIcons.shareSquare,
                                  color: txt_grey_color_v1,
                                ),
                                Text(
                                  "${Utils.formatNumberReaction(numberOfSharing)} Shares",
                                  style: TextStyle(
                                    color: txt_grey_color_v1,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10),
                        child: SizedBox(
                          height: 50.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              likeButton(),
                              commentButton(),
                              shareButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -60,
                    child: Stack(
                      children: <Widget>[
                        reactionAnimation.displayed
                            ? Positioned(
                                left: 0,
                                right: 0,
                                top: -40,
                                bottom: -40,
                                child: GestureDetector(
                                  onTap: reactionAnimation.outTapReactionBox,
                                ),
                              )
                            : Container(),
                        // Box
                        reactionAnimation.renderBox(),
                        // Icons
                        reactionAnimation.renderIcons(),
                      ],
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                ],
              ),
              SizeTransition(
                axisAlignment: 1.0,
                sizeFactor: expandCollapseAnimation.animation,
                child: TextFormComment(),
              ),
              Column(
                children: listCommentWidgetLoad(),
              ),
              loadMoreComment(),
              dottedLine(context),
            ],
          ),
        ),
        onHorizontalDragEnd: reactionAnimation.onHorizontalDragEndBoxIcon,
        onHorizontalDragUpdate: reactionAnimation.onHorizontalDragUpdateBoxIcon,
      ),
    );
  }

  List<Widget> listCommentWidgetLoad() {
    listCommentWidgets.clear();
    for (final element in listCommentData) {
      listCommentWidgets.add(
        CommentToPostWidget(
          contentOfComment: element,
        ),
      );
    }
    return listCommentWidgets;
  }

  Widget loadMoreComment() {
    if (numberOfComment > 2 &&
        listCommentData.length < numberOfComment - numberOfRepliesPost) {
      //put get comment list here
      //add all list
      //reload list comment widget
      return GestureDetector(
        onTap: () {
          setState(() {
            listCommentData.add(4);
          });
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            top: 10,
          ),
          child: Text(
            "Load more comments...",
            style: TextStyle(
              color: only_color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container();
  }

  Widget likeButton() {
    return GestureDetector(
      onTapDown: reactionAnimation.onTapDownBtn,
      onTapUp: reactionAnimation.onTapUpBtn,
      child: SizedBox(
        height: 35,
        width: 90,
        child: TextButton(
          onPressed: reactionAnimation.shortPressLikeButton,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: reactionAnimation.whichIconUserChoose == 0
                    ? Icon(
                        LineIcons.heart,
                        color: txt_grey_color_v1,
                        size: 20,
                      )
                    : Image.asset(
                        reactionAnimation.getImageIconBtn(),
                        width: 20.0,
                        height: 20.0,
                        fit: BoxFit.contain,
                        color: reactionAnimation.getTintColorIconBtn(),
                      ),
              ),
              Container(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  reactionAnimation.getTextBtn(),
                  style: TextStyle(
                    color: reactionAnimation.getColorTextBtn(),
                  ),
                ),
              ),
            ],
          ),
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(btn_post_background),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget shareButton() {
    return SizedBox(
      height: 35,
      width: 90,
      child: TextButton(
        onPressed: () {
          popUpSharePost(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                LineIcons.shareSquare,
                color: txt_grey_color_v1,
                size: 20,
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                "Share",
                style: TextStyle(
                  color: txt_grey_color_v1,
                ),
              ),
            ),
          ],
        ),
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(btn_post_background),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget commentButton() {
    return SizedBox(
      height: 35,
      width: 110,
      child: TextButton(
        onPressed: () {
          setState(() {
            expandCollapseAnimation.runExpand();
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                LineIcons.commentDots,
                color: txt_grey_color_v1,
                size: 20,
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                "Comment",
                style: TextStyle(color: txt_grey_color_v1),
              ),
            ),
          ],
        ),
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(btn_post_background),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }
}

class ItemListImage extends StatefulWidget {
  final String pathImage;

  const ItemListImage({Key key, this.pathImage}) : super(key: key);

  @override
  ItemListImageState createState() => ItemListImageState();
}

class ItemListImageState extends State<ItemListImage>
    with TickerProviderStateMixin {
  //list reaction icon of this post
  List<String> listReactionIcons = [];
  int numberOfReaction = 0;

  //number of sharing post
  int numberOfSharing = 0;

  //field comment data
  List<Widget> listCommentWidgets = [];
  List<dynamic> listCommentData = []; //list comment data
  int numberOfComment = 0; //request api give back number of comment this.post
  //number comments of this post is replies
  int numberOfRepliesPost = 0;

  //show comment box
  ExpandCollapseAnimation expandCollapseAnimation;

  //animation reaction button
  ReactionAnimation reactionAnimation;

  @override
  void initState() {
    super.initState();
    //fetch number of comment
    numberOfComment = 0;
    //fetch list and number of reactions
    listReactionIcons.addAll([]);
    numberOfReaction = 0;
    //fetch number of sharing
    numberOfSharing = 0;
    //fetch list reaction icons
    listReactionIcons.addAll([]);
    //fetch number of replies post
    numberOfRepliesPost = 0;
    //fetch number of comments
    numberOfComment = 0;
    //fetch 2 first comments
    listCommentData = [];
    //init animation show comment box
    expandCollapseAnimation = ExpandCollapseAnimation(state: this);
    //init animation reaction animation
    reactionAnimation = ReactionAnimation(context, state: this);
    //fetch which icon user choose
    reactionAnimation.whichIconUserChoose = 0;
    reactionAnimation.previousWhichIconUserChoose =
        reactionAnimation.whichIconUserChoose;
  }

  @override
  void dispose() {
    super.dispose();
    reactionAnimation.disposeAnimationReaction();
  }

  void addComment(dynamic comment) {
    numberOfComment++;
    listCommentData.add(comment);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: this,
      child: GestureDetector(
        child: Container(
          padding: EdgeInsets.all(10),
          child: Column(
            children: [
              Stack(
                children: [
                  Column(
                    children: [
                      showImageWidget(context, widget.pathImage),
                      dottedLine(context),
                      Row(
                        children: [
                          Expanded(
                            child: ReactionStatisticWidget(
                              listOfReactionsIcon: listReactionIcons,
                              numberReaction: numberOfReaction,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                LineIcons.commentDots,
                                color: txt_grey_color_v1,
                              ),
                              Text(
                                "${Utils.formatNumberReaction(numberOfComment)} Comments",
                                style: TextStyle(
                                  color: txt_grey_color_v1,
                                ),
                              )
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.only(left: 10),
                            child: Row(
                              children: [
                                Icon(
                                  LineIcons.shareSquare,
                                  color: txt_grey_color_v1,
                                ),
                                Text(
                                  "${Utils.formatNumberReaction(numberOfSharing)} Shares",
                                  style: TextStyle(
                                    color: txt_grey_color_v1,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10),
                        child: SizedBox(
                          height: 50.0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              likeButton(),
                              commentButton(),
                              shareButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -60,
                    child: Stack(
                      children: <Widget>[
                        reactionAnimation.displayed
                            ? Positioned(
                                left: 0,
                                right: 0,
                                top: -40,
                                bottom: -40,
                                child: GestureDetector(
                                  onTap: reactionAnimation.outTapReactionBox,
                                ),
                              )
                            : Container(),
                        // Box
                        reactionAnimation.renderBox(),
                        // Icons
                        reactionAnimation.renderIcons(),
                      ],
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                ],
              ),
              SizeTransition(
                axisAlignment: 1.0,
                sizeFactor: expandCollapseAnimation.animation,
                child: TextFormComment(),
              ),
              Column(
                children: listCommentWidgetLoad(),
              ),
              loadMoreComment(),
              dottedLine(context),
            ],
          ),
        ),
        onHorizontalDragEnd: reactionAnimation.onHorizontalDragEndBoxIcon,
        onHorizontalDragUpdate: reactionAnimation.onHorizontalDragUpdateBoxIcon,
      ),
    );
  }

  List<Widget> listCommentWidgetLoad() {
    listCommentWidgets.clear();
    for (final element in listCommentData) {
      listCommentWidgets.add(
        CommentToPostWidget(
          contentOfComment: element,
        ),
      );
    }
    return listCommentWidgets;
  }

  Widget loadMoreComment() {
    if (numberOfComment > 2 &&
        listCommentData.length < numberOfComment - numberOfRepliesPost) {
      //put get comment list here
      //add all list
      //reload list comment widget
      return GestureDetector(
        onTap: () {
          setState(() {
            listCommentData.add(4);
          });
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            top: 10,
          ),
          child: Text(
            "Load more comments...",
            style: TextStyle(
              color: only_color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return Container();
  }

  Widget showImageWidget(BuildContext context, String pathImage) {
    return GestureDetector(
      onTap: () {
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

  Widget likeButton() {
    return GestureDetector(
      onTapDown: reactionAnimation.onTapDownBtn,
      onTapUp: reactionAnimation.onTapUpBtn,
      child: SizedBox(
        height: 35,
        width: 90,
        child: TextButton(
          onPressed: reactionAnimation.shortPressLikeButton,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: reactionAnimation.whichIconUserChoose == 0
                    ? Icon(
                        LineIcons.heart,
                        color: txt_grey_color_v1,
                        size: 20,
                      )
                    : Image.asset(
                        reactionAnimation.getImageIconBtn(),
                        width: 20.0,
                        height: 20.0,
                        fit: BoxFit.contain,
                        color: reactionAnimation.getTintColorIconBtn(),
                      ),
              ),
              Container(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  reactionAnimation.getTextBtn(),
                  style: TextStyle(
                    color: reactionAnimation.getColorTextBtn(),
                  ),
                ),
              ),
            ],
          ),
          style: ButtonStyle(
            backgroundColor:
                MaterialStateProperty.all<Color>(btn_post_background),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget shareButton() {
    return SizedBox(
      height: 35,
      width: 90,
      child: TextButton(
        onPressed: () {
          popUpSharePost(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                LineIcons.shareSquare,
                color: txt_grey_color_v1,
                size: 20,
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                "Share",
                style: TextStyle(
                  color: txt_grey_color_v1,
                ),
              ),
            ),
          ],
        ),
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(btn_post_background),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget commentButton() {
    return SizedBox(
      height: 35,
      width: 110,
      child: TextButton(
        onPressed: () {
          setState(() {
            expandCollapseAnimation.runExpand();
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                LineIcons.commentDots,
                color: txt_grey_color_v1,
                size: 20,
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 10),
              child: Text(
                "Comment",
                style: TextStyle(color: txt_grey_color_v1),
              ),
            ),
          ],
        ),
        style: ButtonStyle(
          backgroundColor:
              MaterialStateProperty.all<Color>(btn_post_background),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
          ),
        ),
      ),
    );
  }
}
