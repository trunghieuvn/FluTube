import 'package:flutter/material.dart';
import 'package:flutube/flutube.dart';

void main() => runApp(
  MaterialApp(
    home: MyApp(),
  )
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FluTube Example'),
      ),
      body: Center(
        child: FluTube(
          'https://www.youtube.com/watch?v=fq4N0hgOWzU',
        ),
      ),
    );
  }
}
