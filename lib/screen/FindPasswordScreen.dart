import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';

class FindPasswordScreen extends StatefulWidget {
  @override
  _FindPasswordScreenState createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends State<FindPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  FocusNode emailNode;

  @override
  void initState() {
    super.initState();
    emailNode = FocusNode();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    emailNode.dispose();
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    return (!regex.hasMatch(value)) ? false : true;
  }

  Future<bool> existEmail() async {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection("users")
        .where("email", isEqualTo: emailController.value.text.trim())
        .get();

    return query.docs.length == 1;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 30),
        child: ListView(
          children: [
            SizedBox(
              height: size.height * 0.1,
            ),
            Text("이메일"),
            TextField(
              controller: emailController,
              focusNode: emailNode,
              onSubmitted: (value) async {
                if(validateEmail(emailController.value.text.trim())){
                  if (await existEmail()) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: emailController.value.text.trim());
                    Navigator.of(context).pop();
                    Toast.show("해당 이메일로 전송되었습니다.", context);
                  } else {
                    Toast.show("가입되지 않은 이메일 입니다.", context);
                  }
                }else{
                  Toast.show("잘못된 이메일 형식입니다.", context);
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "입력하신 메일로 비밀번호 초기화 메일이 발송됩니다.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            SizedBox(
              height: size.height * 0.1,
            ),
            Container(
                width: size.width * 55,
                child: ElevatedButton(
                    onPressed: () async {
                      emailNode.unfocus();
                      if(validateEmail(emailController.value.text.trim())){
                        if (await existEmail()) {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: emailController.value.text.trim());
                          Navigator.of(context).pop();
                          Toast.show("해당 이메일로 전송되었습니다.", context);
                        } else {
                          Toast.show("가입되지 않은 이메일 입니다.", context);
                        }
                      }else{
                        Toast.show("잘못된 이메일 형식입니다.", context);
                      }

                    },
                    child: Text("확인")))
          ],
        ),
      ),
    );
  }
}
