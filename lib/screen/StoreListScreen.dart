import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/main.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:pyeonpyeon/screen/StoreDetailScreen.dart';
import 'package:pyeonpyeon/widget/loading.dart';

class StoreListScreen extends StatefulWidget {
  @override
  _StoreListScreenState createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  bool loading = true;
  List<DocumentSnapshot> storeList = [];
  AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    getStores();
  }

  getStores() async {
    AuthProvider auth = Provider.of<AuthProvider>(context, listen: false);
    DocumentSnapshot documentSnapshot =
        await userRef.doc(auth.getUser().uid).get();
    List storeRefs = documentSnapshot.data()['storeRefs'];
    for (DocumentReference doc in storeRefs) {
      storeList.add(await doc.get());
    }
    print(storeList.length);
    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text("PyeonPyeon",style: TextStyle(color: Colors.white),),
          actions: [
            IconButton(
              icon: Icon(Icons.power_settings_new),
              onPressed: () {
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
            )
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
                child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: ListView.builder(
                  itemCount: storeList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  StoreDetailScreen(storeList[index])),
                        );
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Column(
                            children: [
                              Text(
                                storeList[index].data()['name'],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                storeList[index].id,
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
