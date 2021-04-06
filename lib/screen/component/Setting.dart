import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Setting extends StatefulWidget {
  final DocumentSnapshot storeDoc;

  Setting(this.storeDoc);
  @override
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Setting> {

  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = widget.storeDoc.data()['name'];
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20,vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("그룹명"),
          Row(
            children: [
              Flexible(
                child: TextField(
                  controller: nameController,
                ),
              ),
              SizedBox(width: 10,),
              ElevatedButton(onPressed: null, child: Text("변경"))
            ],
          ),
        ],
      ),
    );
  }
}
