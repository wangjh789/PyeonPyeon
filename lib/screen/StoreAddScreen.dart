import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class StoreAddScreen extends StatefulWidget {
  @override
  _StoreAddScreenState createState() => _StoreAddScreenState();
}

enum Type { Create, Join }

class _StoreAddScreenState extends State<StoreAddScreen> {
  Type type = Type.Create;
  int step = 1;
  User user;

  List<DocumentSnapshot> searchedStores = [];

  Future<QuerySnapshot> getStoreList() async {
    return await FirebaseFirestore.instance
        .collection("stores")
        .where("name", isEqualTo: searchController.value.text.trim())
        .get();
  }

  FocusNode nameNode;
  FocusNode searchNode;

  TextEditingController nameController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  Future<bool> nameDuplicationCheck() async {
    bool result = true;
    await FirebaseFirestore.instance
        .collection("stores")
        .where("name", isEqualTo: nameController.value.text.trim())
        .get()
        .then((QuerySnapshot query) {
      if (query.docs.length == 0) {
        result = false;
      }
    });
    return result;
  }

  Future<void> createNewGroup() async {
    DateTime temp = DateTime.now();
    await FirebaseFirestore.instance
        .collection("stores")
        .doc(temp.millisecondsSinceEpoch.toString())
        .set({
      "name": nameController.value.text.trim(),
      "id": temp.millisecondsSinceEpoch.toString(),
      "createdAt": Timestamp.fromDate(temp),
      "ownerRef": FirebaseFirestore.instance.collection("users").doc(user.uid)
    });
    DocumentReference storeRef = FirebaseFirestore.instance
        .collection("stores")
        .doc(temp.millisecondsSinceEpoch.toString());
    await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
      "storeRefs": FieldValue.arrayUnion([storeRef])
    });
  }

  List<Widget> buildStep1(context) {
    Size size = MediaQuery.of(context).size;
    return [
      SizedBox(
        height: size.height * 0.3,
      ),
      ListTile(
        title: const Text('새 그룹 만들기'),
        leading: Radio<Type>(
          value: Type.Create,
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value;
            });
          },
        ),
      ),
      ListTile(
        title: const Text('그룹 참여하기'),
        leading: Radio<Type>(
          value: Type.Join,
          groupValue: type,
          onChanged: (value) {
            setState(() {
              type = value;
            });
          },
        ),
      ),
      SizedBox(
        height: 30,
      ),
      ElevatedButton(
          onPressed: () {
            setState(() {
              step++;
            });
          },
          child: Text("다음"))
    ];
  }

  List<Widget> buildStep2(context) {
    Size size = MediaQuery.of(context).size;
    if (type == Type.Create) {
      return [
        SizedBox(
          height: size.height * 0.3,
        ),
        Text(
          "그룹명",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        TextField(
          focusNode: nameNode,
          controller: nameController,
          onSubmitted: (value) async {
            if (nameController.value.text.trim().length != 0) {
              if (!await nameDuplicationCheck()) {
                await createNewGroup();
                Navigator.of(context).pop(true);
                Toast.show("새 그룹을 생성했습니다.", context);
              } else {
                Toast.show("중복된 그룹명입니다.", context);
              }
            }
          },
        ),
        SizedBox(
          height: 30,
        ),
        ElevatedButton(
            onPressed: () async {
              nameNode.unfocus();
              if (nameController.value.text.trim().length != 0) {
                if (!await nameDuplicationCheck()) {
                  await createNewGroup();
                  Navigator.of(context).pop(true);
                  Toast.show("새 그룹을 생성했습니다.", context);
                } else {
                  Toast.show("중복된 그룹명입니다.", context);
                }
              }
            },
            child: Text("그룹 생성하기"))
      ];
    } else {
      return [
        SizedBox(
          height: searchedStores.length == 0
              ? size.height * 0.3
              : size.height * 0.1,
        ),
        Text(
          "그룹 검색",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        TextField(
            focusNode: searchNode,
            controller: searchController,
            onSubmitted: (value) {
              getStoreList().then((QuerySnapshot query) {
                setState(() {
                  searchedStores = query.docs;
                });
              });
            },
            decoration: InputDecoration(
              hintText: "정확한 그룹명을 입력해주세요.",
              hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
              suffixIcon: InkWell(
                  onTap: () {
                    searchNode.unfocus();
                    getStoreList().then((QuerySnapshot query) {
                      setState(() {
                        searchedStores = query.docs;
                      });
                    });
                    if (searchedStores.length == 0) {
                      Toast.show("검색 결과가 없습니다.", context);
                    }
                  },
                  child: Icon(Icons.search)),
            )),
        SizedBox(
          height: 30,
        ),
        searchedStores.length != 0
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: searchedStores.length * 2 - 1,
                itemBuilder: (context, index) {
                  if (index.isOdd) {
                    return Divider();
                  }
                  return InkWell(
                    onTap: () => showJoinDialog(
                        context, searchedStores[(index / 2).round()]),
                    child: ListTile(
                      title: Text(
                          searchedStores[(index / 2).round()].data()['name']),
                    ),
                  );
                })
            : Center(
                child: Text("검색 결과가 없습니다."),
              )
      ];
    }
  }

  showJoinDialog(context, DocumentSnapshot storeDoc) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('합류 요청을 전송하시겠습니까?'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () async {
                    DateTime requestedAt = DateTime.now();
                    DocumentSnapshot userDoc = await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .get();
                    if (!userDoc
                        .data()['storeRefs']
                        .contains(storeDoc.reference)) {
                      storeDoc.reference
                          .collection("request")
                          .doc(requestedAt.millisecondsSinceEpoch.toString())
                          .set({
                        "requestedAt": Timestamp.fromDate(requestedAt),
                        "userRef": userDoc.reference
                      });
                      Toast.show("합류 요청을 전송하였습니다.", context);
                    } else {
                      Toast.show("이미 합류된 그룹입니다.", context);
                    }

                    Navigator.pop(context);
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
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    nameNode = FocusNode();
    searchNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    nameNode.dispose();
    searchNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: ListView(
                children:
                    step == 1 ? buildStep1(context) : buildStep2(context))));
  }
}
