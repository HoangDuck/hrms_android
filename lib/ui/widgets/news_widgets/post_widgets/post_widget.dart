import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/ui/constants/app_colors.dart';
import 'package:line_icons/line_icons.dart';
import 'package:provider/provider.dart';

import '../../../../core/animation/expand_collapse_animation.dart';
import '../../../../core/animation/reaction_animation.dart';
import '../../../../core/util/utils.dart';
import '../../../constants/text_styles.dart';
import '../dottedline.dart';
import '../reaction_post_statistic_widget.dart';
import 'comment_to_post_widget.dart';
import 'dropdown_menu_item_post.dart';
import 'list_image_widget.dart';
import 'share_post.dart';
import 'textform_comment.dart';

class PostWidget extends StatefulWidget {
  final dynamic data;
  final dynamic user;

  const PostWidget({
    Key key,
    this.data,
    this.user,
  }) : super(key: key);

  @override
  PostWidgetState createState() => PostWidgetState();
}

class PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {
  //number of images
  int numberImages = 0;

  //List image of post
  List<String> listImages = [];

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

  //tap position
  Offset _tapPosition;

  //show comment box animation
  ExpandCollapseAnimation expandCollapseAnimation;

  //animation reaction button
  ReactionAnimation reactionAnimation;

  //store position tap on screen
  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  @override
  void initState() {
    super.initState();
    //fetch number of images
    numberImages = 5;
    //fetch 4 first image of post
    listImages.addAll([
      widget.data['image'].toString(),
      "https://raw.githubusercontent.com/Sameera-Perera/flutter-carousel-slider-example/master/home.png",
      "https://images.unsplash.com/photo-1520342868574-5fa3804e551c?ixlib=rb-0.3.5&ixid=eyJhcHBfaWQiOjEyMDd9&s=6ff92caffcdd63681a35134a6770ed3b&auto=format&fit=crop&w=1951&q=80",
      "http://www.androidcoding.in/wp-content/uploads/flutter_image_slider-1024x1024.png",
    ]);

    //fetch number of reactions
    numberOfReaction = 0;
    //fetch number of sharing post
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
    //assign current icon user choose to previous variable icon user choose
    //So as to store current icon user choose, because current icon user choose
    //can be changed in the future.
    reactionAnimation.previousWhichIconUserChoose =
        reactionAnimation.whichIconUserChoose;
  }

  @override
  void dispose() {
    super.dispose();
    reactionAnimation.disposeAnimationReaction();
  }

  //add comment function
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
                                  widget.data['user']['picture'].toString(),
                                ),
                                backgroundColor: only_color,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.data['user']['name'].toString(),
                                  style: avatarNameTextStyle,
                                ),
                                Text(
                                  widget.data['user']['nickname'].toString(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: only_color,
                                  ),
                                )
                              ],
                            ),
                          ),
                          Expanded(
                            child: moreHorizontalButton(),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          widget.data['content'].toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            color: txt_grey_color_v3,
                          ),
                        ),
                      ),
                      listImagesWidget(context, listImages, numberImages),
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
                        //'displayed' variable mean reaction box is appear or not
                        //if yes code will init a transparent widget to
                        //make a zone to tap outside reaction box to close it.
                        //if no ==> don't init the transparent tap zone
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
                        //render Box
                        reactionAnimation.renderBox(),
                        //render Icons
                        reactionAnimation.renderIcons(),
                      ],
                      alignment: Alignment.bottomLeft,
                    ),
                  ),
                ],
              ),
              //expand or collapse comment text form widget
              SizeTransition(
                axisAlignment: 1.0,
                sizeFactor: expandCollapseAnimation.animation,
                child: TextFormComment(),
              ),
              Column(
                children: listCommentWidgetLoad(),
              ),
              //display text button "Load more comments"
              loadMoreComment(),
              Container(
                padding: EdgeInsets.only(top: 30),
                child: dottedLine(context),
              ),
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

  Widget moreHorizontalButton() {
    return Container(
      padding: EdgeInsets.only(right: 10),
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          showMenu(
            color: Color(0xfff6f6f6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            context: context,
            position: RelativeRect.fromRect(
                _tapPosition & const Size(30, 30),
                // smaller rect, the touch area
                Offset.zero & overlay.size // Bigger rect, the entire screen
                ),
            items: [
              PopupMenuItem(
                onTap: () {
                  // int? idComment = comment.id;
                  // dataConvert.deleteDataComment(idPost!, idComment!);
                },
                child: dropdownMenuItemPost(
                  LineIcons.trash,
                  "Delete post",
                ),
              ),
              PopupMenuItem(
                onTap: () {
                  // int? idComment = comment.id;
                  // dataConvert.deleteDataComment(idPost!, idComment!);
                },
                child: dropdownMenuItemPost(
                  LineIcons.alternatePencil,
                  "Edit post",
                ),
              ),
            ],
          );
        },
        onTapDown: _storePosition,
        child: Icon(Icons.more_horiz),
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
