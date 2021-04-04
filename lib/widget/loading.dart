import 'package:flutter/material.dart';

class Loading {
  Widget circularLoading(bool isLoading) {
    return isLoading
        ? Container(
            color: Colors.black12,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Container();
  }
}
