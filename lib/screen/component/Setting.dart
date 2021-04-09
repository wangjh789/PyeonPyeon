import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

class Setting extends StatefulWidget {
  final DocumentSnapshot storeDoc;

  Setting(this.storeDoc);

  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {
  DateFormat requestFormat = DateFormat('yyyy.MM.dd kk:mm');

  TextEditingController nameController = TextEditingController();
  FocusNode nameNode;

  User user;
  List<DocumentSnapshot> memberDocs;
  List<DocumentSnapshot> requestDocs;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    nameController.text = widget.storeDoc.data()['name'];
    nameNode = FocusNode();
  }


  Future<QuerySnapshot> getMembers() async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("storeRefs", arrayContains: widget.storeDoc.reference)
        .get();
  }

  Future<QuerySnapshot> getRequests() async {
    return widget.storeDoc.reference.collection("request").get();
  }

  showFireMember(context, DocumentSnapshot memberDoc) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text("해당 멤버를 강퇴하시겠습니까?"),
            actions: [
              TextButton(
                  onPressed: () {
                    memberDoc.reference.update({
                      "storeRefs":
                          FieldValue.arrayRemove([widget.storeDoc.reference])
                    });
                    setState(() {
                      memberDocs.remove(memberDoc);
                    });
                    Navigator.pop(context);
                  },
                  child: Text("예")),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("아니오")),
            ],
          );
        });
  }

  @override
  void dispose() {
    super.dispose();
    nameNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView(
        children: [
          SizedBox(
            height: 30,
          ),
          Text("그룹명"),
          Row(
            children: [
              Flexible(
                child: TextField(
                  focusNode: nameNode,
                  controller: nameController,
                  onSubmitted: (value)async{
                    if (nameController.value.text.trim().length > 0)
                      await widget.storeDoc.reference
                        .update({"name": nameController.value.text.trim()});
                    Navigator.of(context).pop(true);
                  },
                ),
              ),
              SizedBox(
                width: 10,
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (nameController.value.text.trim().length > 0)
                      await widget.storeDoc.reference
                          .update({"name": nameController.value.text.trim()});
                    Navigator.of(context).pop(true);
                  },
                  child: Text("변경"))
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Text("멤버"),
          FutureBuilder(
              future: getMembers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error"),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Text("No Data"),
                  );
                }
                List<DocumentSnapshot> temp = snapshot.data.docs;
                memberDocs = temp;

                return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: memberDocs.length * 2 - 1,
                    itemBuilder: (context, index) {
                      if (index.isOdd) {
                        return Divider();
                      }
                      return ListTile(
                        title: Text(
                          memberDocs[(index / 2).round()].data()['name'],
                        ),
                        subtitle: Text(
                            memberDocs[(index / 2).round()].data()['email']),
                        trailing: memberDocs[(index / 2).round()].id == user.uid
                            ? null
                            : IconButton(
                                onPressed: () => showFireMember(
                                    context, memberDocs[(index / 2).round()]),
                                icon: Icon(Icons.remove_circle),
                              ),
                      );
                    });
              }),
          SizedBox(
            height: 20,
          ),
          Text("합류 요청"),
          FutureBuilder(
              future: getRequests(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error"),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: Text("No Data"),
                  );
                }
                QuerySnapshot query = snapshot.data;
                requestDocs = query.docs;
                return requestDocs.length == 0
                    ? Center(
                        child: Text("합류 요청이 없습니다."),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: requestDocs.length * 2 - 1,
                        itemBuilder: (context, index) {
                          if (index.isOdd) {
                            return Divider();
                          }
                          DocumentReference userRef =
                              requestDocs[(index / 2).round()]
                                  .data()['userRef'];
                          return FutureBuilder(
                              future: userRef.get(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text("Error"),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return Center(
                                    child: Text("No Data"),
                                  );
                                }
                                DocumentSnapshot userDoc = snapshot.data;
                                return userDoc.exists?Row(
                                  children: [
                                    Flexible(
                                      child: ListTile(
                                        title: Text(
                                          userDoc.data()['name'],
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          requestFormat.format(
                                              requestDocs[(index / 2).round()]
                                                  .data()['requestedAt']
                                                  .toDate()),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      child: Text(
                                        "수락",
                                      ),
                                      onPressed: () {
                                        requestDocs[(index / 2).round()]
                                            .reference
                                            .delete();
                                        if (!userDoc
                                            .data()['storeRefs']
                                            .contains(
                                                widget.storeDoc.reference)) {
                                          userRef.update({
                                            "storeRefs": FieldValue.arrayUnion(
                                                [widget.storeDoc.reference])
                                          });
                                          Toast.show("성공적으로 합류되었습니다.", context);
                                        }else{
                                          Toast.show("이미 합류한 멤버입니다.", context);
                                        }
                                        setState(() {
                                          requestDocs.remove(
                                              requestDocs[(index / 2).round()]);
                                        });
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    ElevatedButton(
                                      child: Text("거절"),
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.redAccent, // background
                                      ),
                                      onPressed: () {
                                        requestDocs[(index / 2).round()]
                                            .reference
                                            .delete();
                                        setState(() {
                                          requestDocs.remove(
                                              requestDocs[(index / 2).round()]);
                                        });
                                      },
                                    ),
                                  ],
                                ):
                                Row(
                                  children: [
                                    Flexible(
                                      child: ListTile(
                                        title: Text(
                                          "알수 없음",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          requestFormat.format(
                                              requestDocs[(index / 2).round()]
                                                  .data()['requestedAt']
                                                  .toDate()),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),

                                    ElevatedButton(
                                      child: Text("거절"),
                                      style: ElevatedButton.styleFrom(
                                        primary: Colors.redAccent, // background
                                      ),
                                      onPressed: () {
                                        requestDocs[(index / 2).round()]
                                            .reference
                                            .delete();
                                        setState(() {
                                          requestDocs.remove(
                                              requestDocs[(index / 2).round()]);
                                        });
                                      },
                                    ),
                                  ],
                                );
                              });
                        });
              })

          //  TODO: 합류 요청
        ],
      ),
    );
  }
}
