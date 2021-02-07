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
  List<int> stack = [3, 4, 2];
  List<Instruction> instructionStack = [];
  Map<String, int Function(List<int>)> boxes = {};

  void executeNext() {
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
    instructionStack.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: Text("Planes")),
      body: Center(
        child: ListView(
          scrollDirection: Axis.vertical,
          children: List.generate(
            stack.length,
            (int i) => Center(
              child: Container(
                height: 100,
                child: CustomPaint(
                  painter: Plane.fromInt(stack[i]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleBox(String boxName, List<int> list) {
    stack.insert(0, boxes[boxName]!(list));
  }
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
