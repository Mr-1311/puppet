import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hoveredSectionProvider = StateProvider((ref) => 0);

class Wheel extends ConsumerWidget {
  Wheel({required this.sectionSize, super.key});

  final int sectionSize;
  late final double sectionAngle = 2 * pi / sectionSize;

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
                  sectionSize: sectionSize,
                  section: section,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Text("1,a",
                    style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        decoration: TextDecoration.none)),
              ),
            ),
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
            ..shader = ui.Gradient.radial(
                center, shortSide, [Colors.white, Colors.black]));
    }

    final strokeWidth = shortSide * 0.002;
    // sperators
    var p1 = Offset(size.width / 2, size.height / 2);
    var p2 = Offset((size.width / 2) + (shortSide / 2), size.height / 2);

    for (var i = 0; i < sectionSize; i++) {
      canvas.drawLine(p1, p2, Paint()..strokeWidth = strokeWidth);
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(sectionAngle);
      canvas.translate(-size.width / 2, -size.height / 2);
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
