import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:intl/intl.dart';
import 'package:pyeonpyeon/screen/NoticeWriteScreen.dart';
import 'package:pyeonpyeon/screen/component/PhotoView.dart';

class Notice extends StatefulWidget {
  Notice(this.storeDoc);

  final DocumentSnapshot storeDoc;

  @override
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  DateFormat noticeFormat = DateFormat('yyyy.MM.dd kk:mm');
  User user;

  showDelete(String docId) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text("게시글을 삭제하시겠습니까?"),
            actions: [
              TextButton(
                  onPressed: () {
                    widget.storeDoc.reference
                        .collection("notice")
                        .doc(docId)
                        .delete();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  NoticeWriteScreen(storeDoc: widget.storeDoc)));
        },
      ),
      body: StreamBuilder(
          stream: widget.storeDoc.reference
              .collection("notice")
              .orderBy("wroteAt", descending: true)
              .snapshots(),
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
            print(snapshot.data.docs.length);
            return ListView.builder(
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  return noticeItem(snapshot.data.docs[index]);
                });
          }),
    );
  }

  Widget noticeItem(DocumentSnapshot doc) {
    DocumentReference writerRef = doc.data()['writerRef'];
    Timestamp time = doc.data()['editedAt'] ?? doc.data()['wroteAt'];
    return FutureBuilder(
      future: writerRef.get(),
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
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 1),
          child: ExpansionTileCard(
            title: Text(
              doc.data()['title'],
              style: TextStyle(
                  fontWeight: doc.data()['mustRead']
                      ? FontWeight.bold
                      : FontWeight.normal),
            ),
            subtitle: Text(
              userDoc.data()['name'] +
                  '  |  ' +
                  noticeFormat.format(time.toDate()),
              style: TextStyle(fontSize: 10),
            ),
            initialElevation: 1,
            children: [
              Divider(
                thickness: 1.0,
                height: 1.0,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(doc.data()['content'])),
              ),
              doc.data()["photoUrls"].length > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: doc.data()["photoUrls"].length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => PhotoView(
                                        doc.data()["photoUrls"], index)));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(
                                            doc.data()['photoUrls'][index]),
                                        fit: BoxFit.cover),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5))),
                              ),
                            );
                          }))
                  : Container(),
              userDoc.id == user.uid
                  ? ButtonBar(
                      children: [
                        IconButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => NoticeWriteScreen(
                                        postingDoc: doc,
                                        storeDoc: widget.storeDoc,
                                      )));
                            },
                            icon: Icon(Icons.edit)),
                        IconButton(
                            onPressed: () => showDelete(doc.id),
                            icon: Icon(Icons.delete)),
                      ],
                    )
                  : Container()
            ],
          ),
        );
      },
    );
  }
}
