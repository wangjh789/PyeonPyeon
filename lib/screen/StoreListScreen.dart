import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailto/mailto.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/main.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:pyeonpyeon/screen/StoreAddScreen.dart';
import 'package:pyeonpyeon/screen/StoreDetailScreen.dart';
import 'package:pyeonpyeon/widget/loading.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreListScreen extends StatefulWidget {
  @override
  _StoreListScreenState createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  bool loading = true;
  List<DocumentSnapshot> storeList = [];
  AuthProvider _auth;

  TextEditingController nameController = TextEditingController();

  DateFormat listFormat = DateFormat('yyyy.MM.dd');

  @override
  void initState() {
    super.initState();
    getStores();
  }

  getStores() async {
    storeList = [];
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    DocumentSnapshot documentSnapshot =
        await userRef.doc(auth.getUser().uid).get();
    List storeRefs = documentSnapshot.data()['storeRefs'];
    for (DocumentReference doc in storeRefs) {
      storeList.add(await doc.get());
    }

    setState(() {
      loading = false;
    });
  }

  showEditName(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "이름 변경",
              style: TextStyle(fontSize: 20),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5)),
            ),
            actions: [
              TextButton(
                child: Text("확인"),
                onPressed: () async {
                  if (nameController.value.text.length > 0) {
                    await _auth
                        .getUser()
                        .updateProfile(displayName: nameController.value.text);
                    Toast.show("성공적으로 변경되었습니다.", context);
                    setState(() {});
                    Navigator.pop(context);

                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(_auth.getUser().uid)
                        .update({"name": nameController.value.text});
                  } else {
                    Toast.show("올바른 입력이 아닙니다.", context);
                  }
                },
              ),
              TextButton(
                child: Text("취소"),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  showWithDraw(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text("정말 탈퇴하시겠습니까?"),
            actions: [
              TextButton(
                child: Text("예"),
                onPressed: () {
                  Navigator.pop(context);
                  _auth.withDrawUser();
                  Toast.show("정상적으로 탈퇴되었습니다.", context);
                },
              ),
              TextButton(
                child: Text("아니오"),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  String _url = 'https://github.com/wangjh789/PyeonPyeon';
  void _launchURL() async =>
      await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';

  launchMailto() async {
    final mailtoLink = Mailto(
      to: ['wangjh789@gmail.com'],
      subject: 'PyeonPyeon 개발자 피드백',
    );
    await launch('$mailtoLink');
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "PyeonPyeon",
            style: TextStyle(color: Colors.white),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                padding: EdgeInsets.zero,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  color: mainColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: <TextSpan>[
                                TextSpan(
                                    text: _auth.getUser().displayName,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20)),
                                TextSpan(
                                    text: '  님',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: InkWell(
                              onTap: () => showEditName(context),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Text(
                            _auth.getUser().email,
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
              ListTile(
                title: Text("로그아웃"),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text("로그아웃 하시겠습니까?"),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _auth.googleSignOut();
                                  Toast.show("정상적으로 로그아웃 되었습니다.", context);
                                },
                                child: Text("예")),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("아니오"))
                          ],
                        );
                      });
                },
              ),
              ListTile(
                title: Text("회원탈퇴"),
                onTap: ()  {
                  showWithDraw(context);
                },
              ),
              Divider(),
              ListTile(
                title: Text("개발자 피드백"),
                onTap: ()  async{
                  await launchMailto();
                },
              ),
              ListTile(
                title: Text("Github"),
                onTap: ()  async{
                  _launchURL();
                },
              )
            ],
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
                child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: ListView.builder(
                  itemCount: storeList.length + 1,
                  itemBuilder: (context, index) {
                    if (index == storeList.length) {
                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StoreAddScreen(),
                              )).then((result) {
                            if (result == true) {
                              getStores();
                            }
                          });
                        },
                        child: Card(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Column(
                                children: [
                                  Text(
                                    "추가하기",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Icon(Icons.add),
                                ],
                              )),
                        ),
                      );
                    }
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  StoreDetailScreen(storeList[index])),
                        ).then((result) {
                          if (result == true) {
                            getStores();
                          }
                        });
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Column(
                            children: [
                              Text(
                                storeList[index].data()['name'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                listFormat.format(storeList[index].data()['createdAt'].toDate()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            )),
            Loading().circularLoading(loading)
          ],
        ));
  }
}
