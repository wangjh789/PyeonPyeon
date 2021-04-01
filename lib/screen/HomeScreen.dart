import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthProvider _auth;

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context,listen: false);
    return Scaffold(
      appBar: AppBar(title:Text("HomeScreen")),
      body: Column(
        children: [
          Center(
              child: ElevatedButton(
                child: Text("Google Logout"),
                onPressed: ()  {
                  _auth.googleSignOut();
                },
              ))
        ],
      ),
    );
  }
}
