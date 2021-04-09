import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/screen/LoginScreen.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:pyeonpyeon/screen/StoreListScreen.dart';
import 'package:toast/toast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  runApp(MyApp());
}

Color mainColor = Color.fromRGBO(96, 172, 188, 1);

CollectionReference userRef = FirebaseFirestore.instance.collection("users");

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Something wrong"),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'PyeonPyeon',
                theme: ThemeData(
                    fontFamily: 'NotoSans',
                    primarySwatch: Colors.teal,
                    primaryColor: mainColor,
                    accentColor: mainColor
                ),
                home: MultiProvider(
                    providers: [
                      ChangeNotifierProvider<AuthProvider>(
                        create: (_) => AuthProvider(),
                      ),
                    ],
                    child: Root())
            );
          }
          return Container();
        });
  }
}

class Root extends StatefulWidget {
  @override
  _RootState createState() => _RootState();
}

DateTime currentBackPressTime;


class _RootState extends State<Root> {
  AuthProvider _auth;


  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Toast.show("한번 더 누를시 앱이 종료됩니다.", context);
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context, listen: true);
    return WillPopScope(
        onWillPop: onWillPop,
        child: _auth.isAuthenticated() ? StoreListScreen() : LoginScreen());
  }
}

