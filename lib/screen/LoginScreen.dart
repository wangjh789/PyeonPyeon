import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyeonpyeon/provider/AuthProvider.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:pyeonpyeon/screen/FindPasswordScreen.dart';
import 'package:pyeonpyeon/screen/SignUpScreen.dart';
import 'package:toast/toast.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthProvider _auth;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode emailNode;
  FocusNode passwordNode;

  @override
  void initState() {
    super.initState();
    emailNode = FocusNode();
    passwordNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();

    emailNode.dispose();
    passwordNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthProvider>(context, listen: false);
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: ListView(
        children: [
          Container(
            height: size.height * 0.4,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/logo/logo_transparent.png'),
                    fit: BoxFit.cover)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                TextField(
                  controller: emailController,
                  focusNode: emailNode,
                  onSubmitted: (value) {
                    passwordNode.requestFocus();
                  },
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email), hintText: "Email"),
                ),
                TextField(
                  controller: passwordController,
                  focusNode: passwordNode,
                  obscureText: true,
                  onSubmitted: (value) async {
                    await _auth
                        .emailSignIn(emailController.value.text.trim(),
                            passwordController.value.text.trim())
                        .catchError((error) {
                      if(error.code == "invalid-email"){
                        Toast.show("잘못된 이메일 형식입니다.", context);
                      }
                      if(error.code == "user-not-found"){
                        Toast.show("가입된 이메일이 아닙니다.", context);
                      }
                      if(error.code == "wrong-password"){
                        Toast.show("잘못된 패스워드 입니다.", context);
                      }
                    });
                  },
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock), hintText: "Password"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SignUpScreen()));
                        },
                        child: Text("회원가입")),
                    Text("|"),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => FindPasswordScreen()));
                        },
                        child: Text("비밀번호 찾기")),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  width: size.width * 0.55,
                  child: ElevatedButton(
                      onPressed: () async {
                        await _auth
                            .emailSignIn(emailController.value.text.trim(),
                                passwordController.value.text.trim())
                            .catchError((error) {
                          if (error.code == "invalid-email") {
                            Toast.show("잘못된 이메일 형식입니다.", context);
                          }
                          if (error.code == "user-not-found") {
                            Toast.show("가입된 이메일이 아닙니다.", context);
                          }
                          if (error.code == "wrong-password") {
                            Toast.show("잘못된 패스워드 입니다.", context);
                          }
                        });
                      },
                      child: Text("이메일 로그인")),
                ),
                SizedBox(
                  height: 30,
                ),
                Container(
                  width: size.width * 0.55,
                  child: SignInButton(
                    Buttons.GoogleDark,
                    elevation: 1,
                    onPressed: () async {
                      await _auth.googleSignIn();
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
