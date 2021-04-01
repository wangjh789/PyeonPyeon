import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/main.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider _auth;

  Future<void> signIn()async{
    await _auth.googleSingIn().then((User user)async{
      DocumentSnapshot userDoc = await userRef.doc(user.uid).get();
      if(!userDoc.exists){
        await userRef.doc(user.uid).set({
          "uuid" : user.uid,
          "email" : user.email,
          "name" : user.displayName,
          "storeRefs" : [],
          "registerAt" : Timestamp.now(),
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context,listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("Login Screen"),
      ),
      body: Column(
        children: [
          Center(
              child: ElevatedButton(
            child: Text("Google Login"),
            onPressed: () async {
              await signIn();
            },
          )),

        ],
      ),
    );
  }
}
