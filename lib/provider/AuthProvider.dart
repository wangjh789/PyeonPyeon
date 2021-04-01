import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier{
  AuthProvider({auth}) : _auth = auth ?? FirebaseAuth.instance;

  FirebaseAuth _auth;

  bool isAuthenticated(){
    return _auth.currentUser != null;
  }

  User getUser() => _auth.currentUser;

  Future<User> googleSingIn() async{
    final GoogleSignIn googleSignIn = GoogleSignIn();
    User currentUser;

    final GoogleSignInAccount account = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await account.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User user = userCredential.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    currentUser =  _auth.currentUser;
    assert(user.uid == currentUser.uid);

    notifyListeners();

    return currentUser;
  }

  void googleSignOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await _auth.signOut();
    await googleSignIn.signOut();

    notifyListeners();

    print("User Sign Out");
  }
}
