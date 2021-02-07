import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

List<List<bool>> displays = [
  // 0
  [
    true,
    true,
    true,
    false,
    true,
    true,
    true,
  ],
  //1
  [
    false,
    false,
    true,
    false,
    false,
    true,
    false,
  ],
  //2
  [
    true,
    false,
    true,
    true,
    true,
    false,
    true,
  ],
  //3
  [
    true,
    false,
    true,
    true,
    false,
    true,
    true,
  ],
  //4
  [
    false,
    true,
    true,
    true,
    false,
    true,
    false,
  ],
  // 5
  [
    true,
    true,
    false,
    true,
    false,
    true,
    true,
  ],
  // 6
  [
    true,
    true,
    false,
    true,
    true,
    true,
    true,
  ],
  //7
  [
    true,
    false,
    true,
    false,
    false,
    true,
    false,
  ],
  // 8
  [
    true,
    true,
    true,
    true,
    true,
    true,
    true,
  ],
  //9
  [
    true,
    true,
    true,
    true,
    false,
    true,
    true,
  ],
];

class Plane {
  Plane(this.display,this.display2);
  factory Plane.fromInt(int i) => Plane(displays[(i/10).truncate()], displays[i%10]);
  final List<bool> display;
  final List<bool> display2;
  static const double planeHeight = 60;
  void paint(Canvas canvas, Size size, Offset offset) {
    int dN = 2;
    Size arcSize = Size(80, 80);
    double lineLength = dN * 40;
    double tailWidth = 30;
    double tailHeight = 20;
    Path path = Path();
    double planeWidth = arcSize.width * 3 / 2 + lineLength;
    path.arcTo(offset & arcSize, pi, pi / 2, false);
    path.lineTo(lineLength + arcSize.width + offset.dx, offset.dy);
    path.arcTo(
        Offset(arcSize.width / 2 + lineLength + offset.dx, -arcSize.height / 2 + offset.dy) & arcSize,
        0,
        pi / 2,
        false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawVertices(
      Vertices(
        VertexMode.triangles,
        [
          Offset(planeWidth+offset.dx, offset.dy),
          Offset(planeWidth - tailWidth + offset.dx, offset.dy),
          Offset(planeWidth + offset.dx, -tailHeight + offset.dy),
        ],
      ),
      BlendMode.color,
      Paint()..color = Colors.white,
    );
    double segmentX = arcSize.width / 2 + offset.dx;
    //display
    List<bool> display = this.display.toList();
    drawDisplay(canvas, segmentX, offset.dy, lineLength / 3, arcSize.height / 2, display);
    drawDisplay(canvas, segmentX + lineLength * 2 / 3, offset.dy, lineLength / 3,
        arcSize.height / 2, display2.toList());
  }

  void drawHorizontalSegment(
      Canvas canvas, double startX, double startY, double width) {
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + width, startY),
      Paint()..strokeWidth = 5,
    );
  }

  void drawVerticalSegment(
      Canvas canvas, double startX, double startY, double height) {
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, startY + height),
      Paint()..strokeWidth = 5,
    );
  }

  void drawDisplay(Canvas canvas, double segmentX, double originY, double width, double height,
      List<bool> display) {
    if (display.first) drawHorizontalSegment(canvas, segmentX, originY, width);
    display.removeAt(0);
    if (display.first) drawVerticalSegment(canvas, segmentX, originY, height / 2);
    display.removeAt(0);
    if (display.first)
      drawVerticalSegment(canvas, segmentX + width, originY, height / 2);
    display.removeAt(0);
    if (display.first)
      drawHorizontalSegment(canvas, segmentX, height / 2 + originY, width);
    display.removeAt(0);
    if (display.first)
      drawVerticalSegment(canvas, segmentX, height / 2 + originY, height / 2);
    display.removeAt(0);
    if (display.first)
      drawVerticalSegment(canvas, segmentX + width, height / 2 + originY, height / 2);
    display.removeAt(0);
    if (display.first) drawHorizontalSegment(canvas, segmentX, height + originY, width);
    display.removeAt(0);
  }
}
