import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  FocusNode nameNode;
  FocusNode emailNode;
  FocusNode passwordNode;
  FocusNode confirmPasswordNode;

  FirebaseAuth _auth = FirebaseAuth.instance;

  String errMsg;

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    return (!regex.hasMatch(value)) ? false : true;
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameNode = FocusNode();
    emailNode = FocusNode();
    passwordNode = FocusNode();
    confirmPasswordNode = FocusNode();
  }

  Future<bool> emailDuplicationCheck() async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where("email", isEqualTo: emailController.value.text.trim())
        .get();
    if (query.docs.length != 0) {
      return false;
    }
    return true; //중복 없음
  }

  Future<User> emailSignUp(String name, String email, String password) async {
    User user = await _auth
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((UserCredential credential) async {
      await credential.user.updateProfile(displayName: name);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(credential.user.uid)
          .set({
        "name": nameController.value.text.trim(),
        'email': emailController.value.text.trim(),
        "registerAt": Timestamp.now(),
        "uuid": credential.user.uid,
        "storeRefs": []
      });
    }).catchError((error) {
      print("+============" + error.toString());
      return error;
    });
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(
                height: 70,
              ),
              Text("이름"),
              TextFormField(
                controller: nameController,
                focusNode: nameNode,
                onFieldSubmitted: (value) {
                  emailNode.requestFocus();
                },
                validator: (value) {
                  if (value.length < 2) {
                    return "올바른 이름을 입력해주세요.";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 30,
              ),
              Text("이메일"),
              TextFormField(
                controller: emailController,
                focusNode: emailNode,
                onFieldSubmitted: (value) {
                  passwordNode.requestFocus();
                },
                validator: (value) {
                  if (value.length < 5) {
                    return "이메일을 입력해주세요.";
                  } else if (!validateEmail(value.trim())) {
                    return "올바른 이메일 형식이 아닙니다.";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 30,
              ),
              Text("비밀번호"),
              TextFormField(
                controller: passwordController,
                focusNode: passwordNode,
                obscureText: true,
                onFieldSubmitted: (value) {
                  confirmPasswordNode.requestFocus();
                },
                validator: (value) {
                  if (value.length < 6) {
                    return "6자 이상의 비밀번호를 입력해주세요.";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 30,
              ),
              Text("비밀번호 확인"),
              TextFormField(
                controller: confirmPasswordController,
                focusNode: confirmPasswordNode,
                obscureText: true,
                onFieldSubmitted: (value) async {
                  confirmPasswordNode.unfocus();
                  if (_formKey.currentState.validate()) {
                    if (await emailDuplicationCheck()) {
                      await emailSignUp(
                              nameController.value.text.trim(),
                              emailController.value.text.trim(),
                              passwordController.value.text.trim())
                          .then((User user) async {
                          Navigator.pop(context);
                          Toast.show("성공적으로 회원가입이 완료되었습니다.", context);
                      }).catchError((error) {
                        print("123123" + error.toString());
                        Toast.show(error.toString(), context);
                      });
                    } else {
                      Toast.show("이미 존재하는 회원입니다.", context);
                    }
                  }
                },
                validator: (value) {
                  if (value.trim() != passwordController.value.text.trim()) {
                    return "비밀번호가 서로 일치하지 않습니다.";
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 70,
              ),
              ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState.validate()) {
                      if (await emailDuplicationCheck()) {
                        await emailSignUp(
                                nameController.value.text.trim(),
                                emailController.value.text.trim(),
                                passwordController.value.text.trim())
                            .then((User user) {
                            Navigator.pop(context);
                            Toast.show("성공적으로 회원가입이 완료되었습니다.", context);
                        }).catchError((error) {
                          print(error.toString());
                          Toast.show(error.toString(), context);
                        });
                      } else {
                        Toast.show("이미 존재하는 회원입니다.", context);
                      }
                    }
                  },
                  child: Text("회원가입"))
            ],
          ),
        ),
      ),
    );
  }
}
