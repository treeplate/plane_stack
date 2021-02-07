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
  List<int> stack = [];
  List<Instruction> instructionStack = [
    Instruction("testBox", ConstantNumber(1)),
  ];
  Map<String, int Function(List<int>)> boxes = {"testBox": boxA};

  void executeNext() {
    if (instructionStack.isEmpty) return;
    switch (instructionStack.first.input.runtimeType) {
      case ConstantNumber:
        handleBox(
          instructionStack.first.boxName,
          [(instructionStack.first.input as ConstantNumber).number],
        );
        break;
      case FromStack:
        handleBox(
          instructionStack.first.boxName,
          stack
            ..getRange(
              0,
              (instructionStack.first.input as FromStack).amount,
            )
            ..removeRange(
              0,
              (instructionStack.first.input as FromStack).amount,
            ),
        );
        break;
    }
    //instructionStack.removeAt(0);
  }

  Airport get airport => Airport(stack.toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: Text("Planes")),
      body: SingleChildScrollView(
        child: ListBody(
          children: [
            TextButton(
              onPressed: () => setState(executeNext),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Add 2 to stack"),
                ),
                color: Colors.green,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  height: airport.height,
                  child: CustomPaint(
                    painter: airport,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleBox(String boxName, List<int> list) {
    stack.insert(0, boxes[boxName]!(list));
  }
}

class Airport extends CustomPainter {
  Airport(this.stack);
  final List<int> stack;
  double get height => Plane.planeHeight * stack.length;

  @override
  void paint(Canvas canvas, Size size) {
    List<int> stack = this.stack.toList();
    int n = 0;
    while (stack.isNotEmpty) {
      Plane.fromInt(stack.last).paint(canvas, size, Offset(0, n * Plane.planeHeight));
      stack.removeLast();
      n++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Instruction {
  Instruction(this.boxName, this.input);
  final String boxName;
  final Input input;
}

abstract class Input {}

class FromStack extends Input {
  FromStack(this.amount);
  final int amount;
}

class ConstantNumber extends Input {
  ConstantNumber(this.number);
  final int number;
}

class FromUser extends Input {}

// Boxes: planes in, calculate stuff, planes out
// Stack: planes in storage
// Instruction Stack: instructions (of the form "Send <n> planes/plane <n> to <box name>"/"Take a plane from the user")
// What the machine does: takes the top instruction, executes it, throws that instruction away, repeat.

int boxA(List<int> ints) {
  return 2;
}
