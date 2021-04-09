import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pyeonpyeon/screen/component/ExpiredCalendar.dart';
import 'package:pyeonpyeon/screen/component/Notice.dart';
import 'package:pyeonpyeon/screen/component/Setting.dart';

class StoreDetailScreen extends StatefulWidget {
  StoreDetailScreen(this.storeDoc);

  final DocumentSnapshot storeDoc;

  @override
  _StoreDetailScreenState createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  int _selectedIndex = 0;
  DocumentSnapshot ownerDoc;
  User user;
  List<Widget> componentList = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;

    componentList.addAll([
      ExpiredCalendar(widget.storeDoc),
      Notice(widget.storeDoc),
    ]);
    DocumentReference ownerRef = widget.storeDoc.data()['ownerRef'];
    if (ownerRef.id == user.uid) {
      //owner
      componentList.add(Setting(widget.storeDoc));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.storeDoc.data()['name'],
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: componentList.elementAt(_selectedIndex),
      bottomNavigationBar: widget.storeDoc.data()['ownerRef'].id == user.uid
          ? BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Notice',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Setting',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            )
          : BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications),
                  label: 'Notice',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.amber[800],
              onTap: _onItemTapped,
            ),
    );
  }
}
