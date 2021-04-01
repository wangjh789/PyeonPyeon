import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/screen/HomeScreen.dart';
import 'package:pyeonpyeon/screen/LoginScreen.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:pyeonpyeon/screen/StoreListScreen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  runApp(MyApp());
}

CollectionReference userRef = FirebaseFirestore.instance.collection("users");
class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot){
          if (snapshot.hasError) {
            return Center(
              child: Text("Someting wrong"),
            );
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
                title: 'PyeonPyeon',
                home : MultiProvider(
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
class _RootState extends State<Root> {
  AuthProvider _auth;

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context,listen: true);
    return _auth.isAuthenticated()?StoreListScreen():LoginScreen();
  }
}

