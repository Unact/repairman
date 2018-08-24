import 'package:flutter/material.dart';

class Dialogs {
  static void showLoading(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new Padding(padding: EdgeInsets.all(5.0), child: Center(child: CircularProgressIndicator()));
      }
    );
  }
}
