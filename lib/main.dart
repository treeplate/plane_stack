import 'package:flutter/material.dart';

import 'plane.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: Text("Planes")),
      body: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: List.generate(
            100,
            (int i) => Center(
              child: Container(
                height: 100,
                child: CustomPaint(
                  painter: Plane.fromInt(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Boxes: planes in, calculate stuff, planes out
// Stack: planes in storage
// Instruction Stack: instructions (of the form "Send <n> planes/plane <n> to <box name>"/"Take a plane from the user")
// What the machine does: takes the top instruction, executes it, throws that instruction away, repeat.