import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'plane.dart';
import 'dart:math';

void main() {
  print("1");
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

class PositionedPlane {
  PositionedPlane(this.boxPosition, this.t, this.displayN);
  double t;
  int? boxPosition;
  final int displayN;
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<PositionedPlane> stack = [
    PositionedPlane(0, 0, 0),
  ];
  List<Instruction> instructionStack = [
    Instruction("testBox", FromStack(1)),
  ];
  Map<String, Box> boxes = {
    "testBox": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox2": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox3": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox4": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox5": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox6": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox7": Box("testBox", "Adds 10 to the first arg", boxA),
    //"testBox8": Box("testBox", "Adds 10 to the first arg", boxA),
  };

  late Ticker ticker;

  void initState() {
    super.initState();
    ticker = createTicker((elapsed) {
      bool isPlanes = false;
      List<PositionedPlane> planesAtPointFive = [];
      setState(() {
        print("Tick tick tick");
        for (PositionedPlane plane in stack) {
          bool lessThanHalf = false;
          if (plane.t > 0 && plane.t < 1) {
            lessThanHalf = plane.t < .5;
            plane.t += 1 / 120;
            if (plane.t > .5 && lessThanHalf) {
              plane.t = .5;
            }
          }
          if (plane.t == .5) {
            isPlanes = true;
            planesAtPointFive.add(plane);
          }
          if (plane.t > 1) plane.t = 1;
        }
        if (isPlanes) {
          print("Plane!");
          handleBox(boxes.keys.toList()[planesAtPointFive.first.boxPosition!],
              planesAtPointFive.map((e) => e.displayN).toList());
          for (PositionedPlane plane in planesAtPointFive) stack.remove(plane);
        }
      });
    })
      ..start();
  }

  void dispose() {
    super.dispose();
    ticker.dispose();
  }

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
        for (PositionedPlane plane in stack.getRange(
          0,
          (instructionStack.first.input as FromStack).amount,
        )) {
          plane.boxPosition =
              boxes.keys.toList().indexOf(instructionStack.first.boxName);
          plane.t = 1 / 120;
        }
        break;
    }
    //instructionStack.removeAt(0);
  }

  Airport get airport => Airport(stack.toList(), boxes.values.toList(),
      instructionStack.map((e) => e.toString()).toList());

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
                  child: Text(
                    "Execute next (${instructionStack.last})",
                    style: TextStyle(color: Colors.red),
                  ),
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
    stack.insert(
      0,
      PositionedPlane(
        boxes.keys.toList().indexOf(boxName),
        61 / 120,
        boxes[boxName]!.callback(list).clamp(0, 99),
      ),
    );
  }
}

class Box {
  final String desc;

  final String name;

  Box(this.name, this.desc, this.callback);
  int Function(List<int> ints) callback;
}

class Airport extends CustomPainter {
  Airport(this.stack, this.boxes, this.instrs);
  final List<PositionedPlane> stack;
  final List<Box> boxes;
  final List<String> instrs;
  double get height => Plane.height * stack.length;

  @override
  void paint(Canvas canvas, Size size) {
    //print("Paint calleds");
    List<PositionedPlane> stack = this.stack.toList();
    int n = 0;
    while (stack.isNotEmpty) {
      PositionedPlane plane = stack.last;
      if (plane.t == .5) {
        stack.removeLast();
        n++;
        continue;
      }
      Offset stackOffset = Offset(500, n * Plane.height);
      if (plane.t == 0 || plane.t == 1 || plane.boxPosition == null) {
        stack.removeLast();
        n++;
        Plane.fromInt(plane.displayN).paint(canvas, size, stackOffset);
        continue;
      }
      Offset boxOffset = Offset(0,
          (plane.boxPosition! * (Plane.height + 20)) + Plane.tailHeight + 10);
      if (plane.t < .5) {
        double straightLineLength = Plane.planeWidth + 20;
        Offset cornerOffset = boxOffset + Offset(straightLineLength, 0);
        Offset line = stackOffset - cornerOffset;
        double diagLineLength = line.distance;
        double percentDiag =
            diagLineLength / (diagLineLength + straightLineLength);
        Offset position = Offset.lerp(
            stackOffset, cornerOffset, (plane.t * 2) / percentDiag)!;
        if (plane.t * 2 > percentDiag)
          position = Offset.lerp(cornerOffset, boxOffset,
              ((plane.t * 2) - percentDiag) / (1 - percentDiag))!;
        Plane.fromInt(plane.displayN).paint(canvas, size, position);
      }
      if (plane.t > .5) {
        //print(plane.t);
        double r = 20;
        Offset rDown = boxOffset.dy < stackOffset.dy
            ? boxOffset - Offset(0, r)
            : Offset(0, -r);
        double h = (rDown - stackOffset).distance;
        Offset position =
            Offset.lerp(boxOffset, stackOffset, (plane.t - 0.5) * 2)!;
        Plane.fromInt(plane.displayN).paint(canvas, size, position);
      }
      stack.removeLast();
      n++;
    }
    List<Box> boxes = this.boxes.toList();
    n = 0;
    while (boxes.isNotEmpty) {
      TextPainter painter = TextPainter(
        text: TextSpan(
          text: boxes.last.name + "\n" + boxes.last.desc,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      Rect rect = Offset(0, n * (Plane.height + 20)) &
          Size(max(painter.width, Plane.planeWidth + 20), (Plane.height + 20));
      canvas.drawRect(rect, Paint()..color = Colors.red);
      //print(rect);
      painter..paint(canvas, Offset(0, n * (Plane.height + 20)));
      boxes.removeLast();
      n++;
    }
    List<String> instrs = this.instrs.toList();
    n = 0;
    while (instrs.isNotEmpty) {
      TextPainter(
          text: TextSpan(text: instrs.last), textDirection: TextDirection.ltr)
        ..layout()
        ..paint(canvas, Offset(-500, n * 40));
      instrs.removeLast();
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
  String toString() => "$input => $boxName";
}

abstract class Input {}

class FromStack extends Input {
  FromStack(this.amount);
  final int amount;
  String toString() => "$amount planes from stack";
}

class ConstantNumber extends Input {
  ConstantNumber(this.number);
  final int number;
  String toString() => "$number";
}

class FromUser extends Input {}

int boxA(List<int> ints) {
  return ints.first + 10;
}
