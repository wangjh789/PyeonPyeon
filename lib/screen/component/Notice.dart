import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Notice extends StatefulWidget {
  Notice(this.storeDoc);

  final DocumentSnapshot storeDoc;

  @override
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: widget.storeDoc.reference.collection("notice").snapshots(),
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
          return Container();
        });
  }
}
