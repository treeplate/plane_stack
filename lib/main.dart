// TODO: redesign plane logic

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';

import 'dart:math';
import 'PAParser.dart';
import 'pa.dart';
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

class PositionedPlane {
  PositionedPlane(this.boxPosition, this.t, this.displayN);
  double t;
  int? boxPosition;
  final int displayN;

  String toString() => "(at $t) >$displayN> [$boxPosition]";
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  List<PositionedPlane> stack = [
    PositionedPlane(0, 0, 0),
  ];
  bool loaded = false;
  bool autoplay = false;
  late List<Instruction> instructionStack;
  late final List<Instruction> origInstructionStack;
  Map<String, Box> boxes = LinkedHashMap.of({
    "identity": Box(
      "identity",
      "Returns the input plane",
      identity,
      1,
    ),
    "add": Box(
      "add",
      "Adds the two input planes",
      add,
      2,
    ),
    "copy": Box(
      "copy",
      "Copies the input plane",
      copy,
      1,
    ),
    "delete": Box(
      "delete",
      "Deletes the input plane",
      delete,
      1,
    ),
    "loopback": Box(
      "loopback",
      "Jump to start. Returns input.",
      identity, // special-cased in executeNext
      0,
    ),
    "skip": Box(
      "skip",
      "Skip <input plane> instructions.",
      delete, // special-cased in handleBox
      1,
    ),
  });

  late Ticker ticker;
  final List<PositionedPlane> waitingForClearance = [];
  bool finishedBox = true;

  void initState() {
    super.initState();
    () async {
      instructionStack =
          parsePA(await rootBundle.loadString('assembly/test.pa')).toList();
      origInstructionStack = instructionStack.toList();
      ticker = createTicker((elapsed) {
        List<PositionedPlane> planesAtPointFive = [];
        setState(() {
          for (PositionedPlane plane in stack) {
            bool lessThanHalf = false;
            if (plane.t > 1) plane.t = 1;
            if (plane.t == 1) plane.t = 0;
            if (plane.t > 0 && plane.t < 1 && plane.t != .5) {
              lessThanHalf = plane.t < .5;
              plane.t += 1 / 120;
              if (plane.t > 1) plane.t = 1;
              if (plane.t == 1) plane.t = 0;
              if (plane.t > .5 && lessThanHalf) {
                plane.t = .5;
              }
              if (plane.t == .5 || plane.t == 0) {
                if (waitingForClearance.isNotEmpty) {
                  waitingForClearance.removeAt(0).t += 1 / 120;
                } else if (plane.t == 0) {
                  finishedBox = true;
                }
              }
            }
            if (plane.t == .5 && !waitingForClearance.contains(plane)) {
              planesAtPointFive.add(plane);
            }
          }
          if (planesAtPointFive.length > 0 &&
              planesAtPointFive.length ==
                  boxes.values
                      .toList()[planesAtPointFive.first.boxPosition!]
                      .planeCountRequested) {
            handleBox(boxes.keys.toList()[planesAtPointFive.first.boxPosition!],
                planesAtPointFive.map((e) => e.displayN).toList());
            for (PositionedPlane plane in planesAtPointFive)
              stack.remove(plane);
          }
          if (finishedBox && autoplay && instructionStack.isNotEmpty) {
            executeNext();
          }
        });
      })
        ..start();
      setState(() {
        loaded = true;
      });
    }();
  }

  void dispose() {
    super.dispose();
    ticker.dispose();
  }

  void executeNext() async {
    finishedBox = false;
    if (instructionStack.isEmpty) return;
    for (Input input in instructionStack.first.inputs) {
      switch (input.runtimeType) {
        case ConstantNumber:
          stack.add(PositionedPlane(
              boxes.keys.toList().indexOf(instructionStack.first.boxName),
              .5,
              (input as ConstantNumber).number));
          break;
        case FromStack:
          PositionedPlane plane = stack
              .firstWhere((element) => !waitingForClearance.contains(element));
          plane.boxPosition =
              boxes.keys.toList().indexOf(instructionStack.first.boxName);
          print(plane);
          waitingForClearance.add(plane);

          break;
        case FromUser:
          stack.add(PositionedPlane(
              boxes.keys.toList().indexOf(instructionStack.first.boxName),
              .5,
              await getNumberFromUser((input as FromUser).desc)));
          break;
      }
    }
    if (waitingForClearance.isNotEmpty) {
      waitingForClearance.removeAt(0).t += 1 / 120;
    }
    if (boxes[instructionStack.first.boxName]!.planeCountRequested == 0) {
      finishedBox = true;
    }
    if (instructionStack.first.boxName == 'loopback') {
      instructionStack = origInstructionStack.toList();
    } else {
      instructionStack.removeAt(0);
    }
    setState(() {});
  }

  Airport get airport => Airport(stack.toList(), boxes.values.toList(),
      instructionStack.map((e) => e.toString()).toList());

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Loading...'),
        ),
      );
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(title: Text("Planes")),
      body: SingleChildScrollView(
        child: ListBody(
          children: [
            TextButton(
              onPressed: () {
                autoplay = !autoplay;
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.yellow),
                child: Text('Turn autoplay ${autoplay ? 'off' : 'on'}'),
              ),
            ),
            TextButton(
              onPressed:
                  instructionStack.isEmpty || !finishedBox ? null : executeNext,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Execute next (${instructionStack.isEmpty ? 'none' : instructionStack.first})",
                  ),
                ),
                decoration: BoxDecoration(color: Colors.yellow),
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
    List<int> result = boxes[boxName]!.callback(list);
    for (int number in result) {
      stack.insert(
        0,
        PositionedPlane(
          boxes.keys.toList().indexOf(boxName),
          .5,
          number.clamp(0, 99),
        ),
      );
      waitingForClearance.add(stack.first);
    }
    if (result.length == 0) finishedBox = true;
    if (waitingForClearance.isNotEmpty) {
      waitingForClearance.removeAt(0).t += 1 / 120;
    }
    if (boxName == 'skip') {
      instructionStack.removeRange(0, list.first);
    }
  }

  static List<int> identity(List<int> ints) {
    return [ints.first];
  }

  static List<int> add(List<int> ints) {
    return [ints.fold(0, (previousValue, element) => previousValue + element)];
  }

  static List<int> copy(List<int> ints) {
    return [ints.first, ints.first];
  }

  static List<int> delete(List<int> ints) {
    return [];
  }

  Future<int> getNumberFromUser(String message) async {
    Completer<int> result = Completer();
    int value = 50;
    showDialog(
      context: context,
      builder: (context) {
        return BoilerplateDialog(
          title: message,
          children: [
            StatefulBuilder(builder: (context, setStateDialog) {
              return NumberPicker(
                minValue: 0,
                maxValue: 99,
                value: value,
                onChanged: (v) {
                  setStateDialog(() {
                    value = v;
                  });
                },
              );
            }),
            TextButton(
              child: Text("Select number"),
              onPressed: () {
                result.complete(value);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    return result.future;
  }
}

class BoilerplateDialog extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const BoilerplateDialog(
      {super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title),
            const SizedBox(height: 15),
            ...children,
          ],
        ),
      ),
    );
  }
}

class Box {
  final String desc;

  final String name;

  final int planeCountRequested;

  Box(this.name, this.desc, this.callback, this.planeCountRequested);
  List<int> Function(List<int> ints) callback;
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
        //n++;
        continue;
      }
      Offset stackOffset = Offset(500, n * Plane.height);
      if (plane.t == 0 || plane.t == 1 || plane.boxPosition == null) {
        // stack.removeLast();
        // n++;
        // Plane.fromInt(plane.displayN).paint(canvas, size, stackOffset);
        //  continue;
      }
      Offset boxOffset = Offset(0,
          (plane.boxPosition! * (Plane.height + 20)) + Plane.tailHeight + 10);
      double planet = plane.t;
      if (planet > .5) {
        planet = 1 - planet;
      }
      if (planet < .5) {
        double straightLineLength = Plane.planeWidth + 20;
        Offset cornerOffset = boxOffset + Offset(straightLineLength, 0);
        Offset line = stackOffset - cornerOffset;
        double diagLineLength = line.distance;
        double percentDiag =
            diagLineLength / (diagLineLength + straightLineLength);
        Offset position =
            Offset.lerp(stackOffset, cornerOffset, (planet * 2) / percentDiag)!;
        if (planet * 2 > percentDiag)
          position = Offset.lerp(cornerOffset, boxOffset,
              ((planet * 2) - percentDiag) / (1 - percentDiag))!;
        Plane.fromInt(plane.displayN).paint(canvas, size, position);
      }
      stack.removeLast();
      n++;
    }
    List<Box> boxes = this.boxes.reversed.toList();
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
