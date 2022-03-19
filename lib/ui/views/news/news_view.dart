import 'package:flutter/material.dart';
import 'package:gsot_timekeeping/core/util/utils.dart';
import 'package:gsot_timekeeping/ui/widgets/app_bar_custom.dart';

import '../../constants/app_colors.dart';
import '../../widgets/news_widgets/avatar_widgets/avatar_widget.dart';

import '../../widgets/news_widgets/post_widgets/post_widget.dart';

class NewsView extends StatelessWidget {
  final dynamic data;

  NewsView(this.data);

  @override
  Widget build(BuildContext context) {
    //init appbar with left button
    return Scaffold(
      appBar: appBarCustom(context, () {
        Utils.closeKeyboard(context);
        Navigator.pop(context, 0);
      }, () {
        Utils.closeKeyboard(context);
      }, data['title'], null),
      body: ListPosts(),
    );
  }
}

class ListPosts extends StatefulWidget {
  const ListPosts({Key key}) : super(key: key);

  @override
  _ListPostsState createState() => _ListPostsState();
}

class _ListPostsState extends State<ListPosts> {
  //current user
  dynamic currentUser = {};

  //number of posts
  int numberOfPosts = 0;

  //get list post
  dynamic listPosts = [];

  void _getCurrentUser() {
    currentUser = {
      'name': 'Hoàng Đức',
      'nickname': '@duckute',
      'avatar':
          'https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banh-trang-tron.jpg?alt=media&token=e0ad728d-cf53-4b7c-a310-24d9381d3419',
    };
  }

  @override
  void initState() {
    super.initState();
    //call api get current user
    _getCurrentUser();
    //call api get number of posts.
    numberOfPosts = 0;
    //call fetch api list post from api
    listPosts.addAll([
      {
        "id": 1,
        "user": {
          "id": 13,
          "name": "Duc Le",
          "nickname": "@leute",
          "picture":
              "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-1.jpg?alt=media&token=87046e84-439a-4419-b528-81a93e33a93d",
          "cover":
              "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
        },
        "content": "Hello this is my first time. I've got to GSOT.",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/bamboo_staff_2.jpg?alt=media&token=45fa8353-a38a-4080-a2c2-72dffcb3c8ac",
        "numberlikes": 0,
        "numbercomments": 0,
        "likes": [],
        "comments": []
      },
      {
        "id": 2,
        "user": {
          "id": 13,
          "name": "Duc Le",
          "nickname": "@leute",
          "picture":
              "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-1.jpg?alt=media&token=87046e84-439a-4419-b528-81a93e33a93d",
          "cover":
              "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
        },
        "content": "Hello today i go to school.",
        "image": "",
        "numberlikes": 0,
        "numbercomments": 0,
        "likes": [],
        "comments": []
      },
      {
        "id": 3,
        "user": {
          "id": 2,
          "name": "Minh Thien",
          "nickname": "@thienute",
          "picture":
              "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banh-trang.jpg?alt=media&token=8ab88554-3ca5-494c-9662-af6bc7a988cd",
          "cover":
              "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
        },
        "content": "I met Tim Cook, Bill Gates,...",
        "image": "",
        "numberlikes": 0,
        "numbercomments": 0,
        "likes": [],
        "comments": []
      },
      {
        "id": 4,
        "user": {
          "id": 11,
          "name": "Toan Khanh",
          "nickname": "@khanhute",
          "picture":
              "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-2.jpg?alt=media&token=9645f36a-1f07-4716-aff5-fabd1a9cadc4",
          "cover":
              "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
        },
        "content": "Today. I go to HCMUTE.",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/cach-lam-sua-chua-don-gian-tai-nha.jpg?alt=media&token=65eb2fd3-b952-4ae5-8832-a207ed08e9b9",
        "numberlikes": 0,
        "numbercomments": 0,
        "likes": [],
        "comments": []
      },
      {
        "id": 5,
        "user": {
          "id": 1,
          "name": "Hoang Duc",
          "nickname": "@duckute",
          "picture":
              "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/..png?alt=media&token=9264e0b5-5c0f-4e24-afeb-c8e6c571b20b",
          "cover":
              "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
        },
        "content": "Hello I'm Intership of GSOT.",
        "image":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/hqdefault.jpg?alt=media&token=4bb05076-8a6d-4b8f-9d4c-2dd1d8fb8b70",
        "numberlikes": 0,
        "numbercomments": 0,
        "likes": [],
        "comments": []
      }
    ]);
  }

  @override
  Widget build(BuildContext context) {
    int length = listPosts.length; //api get number of post
    return ListView.builder(
      //increase 1 index because we have to add
      // a widget which includes some items for home page
      itemCount: length + 1,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, i) {
        //before loading post this page have to load some items below.
        //such as: header page name, greeting card, list avatar
        //push back 1 index
        //if index =0 load items need to load before loading post
        //if greater 0 => load posts.
        if (i == 0) {
          return Column(
            children: [
              // headerPageName("Home"),
              // greetingCard(),
              // storiesHeaderCard(),
              Container(
                padding: EdgeInsets.only(
                  top: Utils.resizeHeightUtil(context, 10),
                ),
                child: ListAvatar(),
              ),
            ],
          );
        }
        //minus 1 because list have been pushed back 1 index
        int index = i - 1;
        //build post list
        return length - 1 - index == 0 //if this is the last post,
            // show the last post with circle loading animation
            ? Column(
                children: [
                  PostWidget(
                    data: listPosts[length - 1 - index], //reverse post index,
                    // the newest post is the largest index
                    user: currentUser,
                  ),
                  Container(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(
                      color: only_color,
                    ),
                  ),
                ],
              )
            //if current index is not the last index of list
            // => Just show post item
            : PostWidget(
                data: listPosts[length - 1 - index], //reverse post index,
                // the newest post is the largest index
                user: currentUser,
              );
      },
    );
  }

  Widget storiesHeaderCard() {
    return Container(
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 10,
        top: 45,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            color: only_color,
            child: Text(
              " ",
              style: TextStyle(fontSize: 22),
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 5),
            child: Text(
              "Stories",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
