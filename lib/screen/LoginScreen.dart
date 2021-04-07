import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/main.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider _auth;

  Future<void> signIn() async {
    await _auth.googleSingIn().catchError((e) {
      print(e.toString());
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context, listen: false);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage('assets/logo/logo_transparent.png')),
          SignInButton(
            Buttons.Google,
            elevation: 1,
            onPressed: ()async{
              await signIn();
            },
          )
        ],
      ),
    );
  }
}
