import 'dart:math';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config/config.dart';

final hoveredSectionProvider = StateProvider((ref) => 0);

class Wheel extends ConsumerWidget {
  Wheel({required this.menu, super.key});

  final Menus menu;
  late final double sectionAngle = 2 * pi / menu.items.length;

  _updateHoverSection(PointerEvent event, Size size, WidgetRef ref) {
    // normalize mouse position and make origin to center
    var x = event.position.dx / size.width - 0.5;
    var y = (event.position.dy / size.height - 0.5) * -1;

    const radius = 0.5;

    // rescale mouse position based on largest dimension
    // if window will always be square then this can be deleted
    if (size.width > size.height) {
      x *= size.width / size.height;
    } else {
      y *= size.height / size.width;
    }

    var distToCenter = sqrt(x * x + y * y);
    // if mouse position is outside of wheel
    if (distToCenter > radius) {
      ref.read(hoveredSectionProvider.notifier).state = 0;
      return;
    }

    // angle of mouse position relative to center in radians
    var angle = atan2(y, x);
    if (angle < 0) {
      // remap bottom angle from (-PI - 0) to (PI - 2PI) left to right
      angle += 2 * pi;
    }

    var section = (angle / sectionAngle).ceil();
    if (angle == 0) {
      section = 1;
    }

    ref.read(hoveredSectionProvider.notifier).state = section;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final section = ref.watch(hoveredSectionProvider);

    return MouseRegion(
      onExit: (event) => ref.read(hoveredSectionProvider.notifier).state = 0,
      child: Listener(
        onPointerHover: (event) => _updateHoverSection(event, size, ref),
        onPointerUp: (event) {
          print(ref.read(hoveredSectionProvider));
          _updateHoverSection(event, size, ref);
        },
        child: Stack(
          children: [
            SizedBox.expand(
              child: CustomPaint(
                painter: WheelPainter(
                  size: size,
                  sectionSize: menu.items.length,
                  section: section,
                ),
              ),
            ),
            ...getMenuItems(menu.items, size, sectionAngle)
          ],
        ),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.size,
    required this.sectionSize,
    required this.section,
  });

  final Size size;
  final int sectionSize;
  final int section;

  @override
  void paint(Canvas canvas, Size size) {
    final shortSide = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final sectionAngle = 2 * pi / sectionSize;

    // background
    canvas.drawCircle(center, shortSide / 2, Paint()..color = Colors.blue);

    // section
    if (section != 0) {
      canvas.drawArc(
          Rect.fromCenter(center: center, width: shortSide, height: shortSide),
          -section * sectionAngle,
          sectionAngle,
          true,
          Paint()
            ..blendMode = BlendMode.overlay
            ..shader = ui.Gradient.radial(center, shortSide, [Colors.white, Colors.black]));
    }

    final strokeWidth = shortSide * 0.002;
    // separators
    var p1 = Offset(size.width / 2, size.height / 2);
    var p2 = Offset((size.width / 2) + (shortSide / 2), size.height / 2);

    if (sectionSize > 1) {
      for (var i = 0; i < sectionSize; i++) {
        canvas.drawLine(p1, p2, Paint()..strokeWidth = strokeWidth);
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(sectionAngle);
        canvas.translate(-size.width / 2, -size.height / 2);
      }
    }

    // outline
    canvas.drawCircle(
        center,
        (shortSide / 2) - (strokeWidth / 2),
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) {
    if (oldDelegate.section != section) {
      return true;
    }
    return false;
  }
}

double calculateMaxSquare(double side, double angle) {
  double heightOfTriangle = cos(angle) * side;
  double baseOfTriangle = 2 * sin(angle) * side;

  // https://math.stackexchange.com/questions/2784043/square-inside-of-an-isosceles-triangle
  return (baseOfTriangle * heightOfTriangle) / (baseOfTriangle + heightOfTriangle);
}

List<Positioned> getMenuItems(List<Items> items, Size size, double sectionAngle) {
  List<Positioned> menuItems = [];

  final radius = size.shortestSide * 0.5;
  // biggest square inside the circle is when angle is tau/5
  final squareLength = calculateMaxSquare(radius, min(sectionAngle * 0.5, pi / 5));
  final distance = (radius * 0.9) - (squareLength * 0.5);

  for (int i = 1; i <= items.length; i++) {
    final angle = items.length == 1 ? pi * 0.5 : sectionAngle * i - sectionAngle * 0.5;
    menuItems.add(Positioned(
      left: radius + cos(angle) * distance - squareLength / 2,
      bottom: radius + sin(angle) * distance - squareLength / 2,
      child: Container(
        width: squareLength,
        height: squareLength,
        // color: Colors.green,
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.terminal,
              size: squareLength * 0.3,
            ),
            AutoSizeText(
              items[i - 1].name,
              maxFontSize: (squareLength * 0.245).floor().toDouble(),
              minFontSize: (squareLength * 0.19).floor().toDouble(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(decoration: TextDecoration.none),
              textAlign: TextAlign.center,
            ),
            AutoSizeText(
              items[i - 1].description,
              maxFontSize: (squareLength * 0.135).floor().toDouble(),
              minFontSize: (squareLength * 0.11).floor().toDouble(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(decoration: TextDecoration.none),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }
  return menuItems;
}
