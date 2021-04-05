import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:pyeonpyeon/widget/loading.dart';

class NoticeWriteScreen extends StatefulWidget {
  final DocumentSnapshot postingDoc;
  final DocumentSnapshot storeDoc;

  NoticeWriteScreen({this.postingDoc, this.storeDoc});

  @override
  _NoticeWriteScreenState createState() => _NoticeWriteScreenState();
}

class _NoticeWriteScreenState extends State<NoticeWriteScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  List oldImg;
  List newImg = [];
  bool mustRead;

  bool loading = false;

  initData() {

    final DateTime today = DateTime.now();

    titleController.text = widget.postingDoc == null
        ? today.month.toString() + "월 " + today.day.toString() + "일자 특이사항"
        : widget.postingDoc.data()['title'];
    contentController.text =
        widget.postingDoc == null ? "" : widget.postingDoc.data()['content'];

    oldImg = widget.postingDoc == null ? [] : widget.postingDoc['photoUrls'];

    mustRead =
        widget.postingDoc == null ? false : widget.postingDoc['mustRead'];
  }

  showPicker() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            actions: [
              InkWell(
                  onTap: () async {
                    await ImagePicker()
                        .getImage(source: ImageSource.camera, imageQuality: 10)
                        .then((PickedFile img) {
                      Navigator.pop(context);
                      if (img != null) {
                        setState(() {
                          newImg.add(File(img.path));
                        });
                      }
                    });
                  },
                  child: ListTile(
                    title: Text("카메라"),
                  )),
              InkWell(
                onTap: () async {
                  await ImagePicker()
                      .getImage(source: ImageSource.gallery, imageQuality: 10)
                      .then((PickedFile img) {
                    Navigator.pop(context);
                    if (img != null) {
                      setState(() {
                        newImg.add(File(img.path));
                      });
                    }
                  });
                },
                child: ListTile(
                  title: Text("갤러리"),
                ),
              ),
            ],
          );
        });
  }

  FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  Future<void> uploadToFB() async {
    setState(() {
      loading = true;
    });
    List newUrls = [];
    for (File img in  newImg){
      DateTime temp = DateTime.now();
      Reference storageReference = _firebaseStorage
          .ref()
          .child("${widget.storeDoc.id}/notice/${temp.millisecondsSinceEpoch}");
      UploadTask storageUploadTask = storageReference.putFile(img);
      // 파일 업로드 완료까지 대기
      await storageUploadTask;

      String downloadURL = await storageReference.getDownloadURL();
      newUrls.add(downloadURL);
    }
    if (widget.postingDoc != null) {
      await widget.storeDoc.reference
          .collection("notice")
          .doc(widget.postingDoc.id)
          .update({
        "title": titleController.value.text.trim(),
        "content": contentController.value.text.trim(),
        "editedAt": Timestamp.fromDate(DateTime.now()),
        "mustRead": mustRead,
        "photoUrls": oldImg+newUrls
      });
    }
    else{
      User user = FirebaseAuth.instance.currentUser;
      DocumentReference userRef = FirebaseFirestore.instance.collection("users").doc(user.uid);
      DateTime temp = DateTime.now();
      await widget.storeDoc.reference
          .collection("notice")
          .doc(temp.millisecondsSinceEpoch.toString())
          .set({
        "title": titleController.value.text.trim(),
        "content": contentController.value.text.trim(),
        "editedAt": Timestamp.fromDate(temp),
        "mustRead": mustRead,
        "photoUrls": newUrls,
        "writerRef" : userRef
      });
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: ListView(
              children: [
                TextField(
                  controller: titleController,
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: contentController,
                  maxLines: 20,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: new BorderSide(color: Colors.grey))),
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: oldImg.length + newImg.length + 1,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return InkWell(
                            onTap: showPicker,
                            child: Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                              child: Icon(Icons.add),
                            ),
                          );
                        }
                        if (index < oldImg.length + 1) {
                          //old Img
                          return Stack(
                            children: [
                              Container(
                                margin: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(oldImg[index-1]),
                                        fit: BoxFit.cover),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10))),
                              ),
                              Align(
                                  alignment: Alignment.topRight,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        oldImg.remove(oldImg[index - 1]);
                                      });
                                    },
                                    child: Icon(
                                      Icons.remove_circle,
                                      size: 25,
                                      color: Colors.red,
                                    ),
                                  ))
                            ],
                          );
                        }
                        //new Img
                        return Stack(
                          children: [
                            Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: FileImage(
                                          newImg[index - (oldImg.length + 1)]),
                                      fit: BoxFit.cover),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10))),
                            ),
                            Align(
                                alignment: Alignment.topRight,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      newImg.remove(
                                          newImg[index - (oldImg.length + 1)]);
                                    });
                                  },
                                  child: Icon(
                                    Icons.remove_circle,
                                    size: 25,
                                    color: Colors.red,
                                  ),
                                ))
                          ],
                        );
                      }),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: mustRead,
                      onChanged: (bool value) {
                        setState(() {
                          mustRead = value;
                        });
                      },
                    ),
                    Text(
                      "중요 게시물",
                    )
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                ElevatedButton(onPressed: () async{
                  await uploadToFB();
                  Navigator.pop(context);
                }, child: Text("확인"))
              ],
            ),
          ),
          Loading().circularLoading(loading)
        ],
      ),
    );
  }
}
