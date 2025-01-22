import 'package:flutter/material.dart';

AppBar appbarComponent(String title) {
  return AppBar(
    title: Text(title),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.transparent,
    titleTextStyle: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );
}
