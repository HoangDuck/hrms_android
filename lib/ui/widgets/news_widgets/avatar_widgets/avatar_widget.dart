import 'package:flutter/material.dart';

import '../../../../core/util/utils.dart';
import '../../../constants/app_colors.dart';
import '../../tk_text.dart';

class ListAvatar extends StatefulWidget {
  const ListAvatar({Key key}) : super(key: key);

  @override
  _ListAvatarState createState() => _ListAvatarState();
}

class _ListAvatarState extends State<ListAvatar> {
  dynamic currentUser = {};
  dynamic listAvatar = [];

  void _getCurrentUser() {
    currentUser = {
      'name': 'Hoàng Đức',
      'nickname': '@duckute',
      'avatar':
          'https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banh-trang-tron.jpg?alt=media&token=e0ad728d-cf53-4b7c-a310-24d9381d3419'
    };
  }

  void _getListAvatar() {
    listAvatar.addAll([
      {
        "id": 1,
        "name": "Hoang Duc",
        "nickname": "@duckute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/..png?alt=media&token=9264e0b5-5c0f-4e24-afeb-c8e6c571b20b",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 2,
        "name": "Minh Thien",
        "nickname": "@thienute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banh-trang.jpg?alt=media&token=8ab88554-3ca5-494c-9662-af6bc7a988cd",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 3,
        "name": "Phuc Minh",
        "nickname": "@minhute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banhtrang.jpg?alt=media&token=778ada73-2694-4665-9ab3-1e60095415bc",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 4,
        "name": "Duc Tinh",
        "nickname": "@tinhute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/cach-lam-nem-nuong-lui-2.jpg?alt=media&token=17fb7222-dc5c-4681-bd57-c1a485edff7c",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 5,
        "name": "Thien Toan",
        "nickname": "@toanute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banhtrang2.jpg?alt=media&token=7b0c5f6f-098d-49f1-9cc9-00f77e19df6b",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 6,
        "name": "Thanh Bao",
        "nickname": "@baoute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/combo.jpg?alt=media&token=72eba609-c5b6-4834-b88b-1d9e32ee14b2",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 7,
        "name": "Bao Toan",
        "nickname": "@btoankute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/v4-460px-Make-Homemade-Spaghetti-Sauce-Step-18-Version-4.jpg?alt=media&token=50ada86c-57a4-4325-8ad2-271f29da3361",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 8,
        "name": "Minh Duc",
        "nickname": "@mduckute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/pho-bo-bap-hoa-500.jpg?alt=media&token=f405ff71-b138-4d8f-9269-90d2d002e890",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 9,
        "name": "Hoang Phuc",
        "nickname": "@phucute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/goodshit.png?alt=media&token=3bab3e0c-878f-417d-a98d-abe8dbd3c2c9",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 10,
        "name": "Vo Tam",
        "nickname": "@tamute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/e-signature.png?alt=media&token=94572a39-a527-4119-a151-d4ee837183ef",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 11,
        "name": "Toan Khanh",
        "nickname": "@khanhute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-2.jpg?alt=media&token=9645f36a-1f07-4716-aff5-fabd1a9cadc4",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 12,
        "name": "Hoang Minh",
        "nickname": "@minhute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-7.jpg?alt=media&token=a167db92-cc8d-45c1-94ed-68aac9c99d59",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 13,
        "name": "Duc Le",
        "nickname": "@leute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/menu-1.jpg?alt=media&token=87046e84-439a-4419-b528-81a93e33a93d",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      },
      {
        "id": 14,
        "name": "Huu Duc",
        "nickname": "@ducute",
        "picture":
            "https://firebasestorage.googleapis.com/v0/b/quickstart-1614695450393.appspot.com/o/banh-trang-tron.jpg?alt=media&token=e0ad728d-cf53-4b7c-a310-24d9381d3419",
        "cover":
            "https://suckhoedoisong.qltns.mediacdn.vn/324455921873985536/2021/12/14/cay-thong-14-1639467420970451858714.jpg"
      }
    ]);
  }

  @override
  void initState() {
    super.initState();
    //api fetch current user
    _getCurrentUser();
    //api fetch list avatar
    _getListAvatar();
  }

  @override
  Widget build(BuildContext context) {
    //return list avatar with limited height not to get error when app running
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.1,
      child: _buildSuggestions(),
    );
  }

  //build list view of avatars
  Widget _buildSuggestions() {
    return ListView.builder(
      itemCount: listAvatar.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, i) {
        return buildItemListAvatar(listAvatar[i]);
      },
    );
  }

  Widget buildItemListAvatar(dynamic data) {
    return SizedBox(
      width: Utils.resizeWidthUtil(context, 100),
      height: Utils.resizeHeightUtil(context, 60),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: only_color,
                  image: DecorationImage(
                    image: NetworkImage(
                      data['picture'].toString(),
                    ),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(50.0),
                  ),
                ),
                child: IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.transparent,
                  ),
                  onPressed: () {},
                ),
              ),
              Positioned(
                top: 35,
                left: 35,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: Utils.resizeWidthUtil(context, 90),
            child: TKText(
              data['name'].toString(),
              textAlign: TextAlign.center,
              tkFont: TKFont.SFProDisplayMedium,
              style: TextStyle(
                fontSize: Utils.resizeWidthUtil(context, 20),
              ),
            ),
          )
        ],
      ),
    );
  }
}
