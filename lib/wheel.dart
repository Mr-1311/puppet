import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wheelShaderProgramProvider = FutureProvider((_) async {
  return await FragmentProgram.fromAsset('shaders/wheel.frag');
});

final wheelShaderProvider = Provider((ref) {
  final shaderProgram = ref.watch(wheelShaderProgramProvider);

  return shaderProgram.whenData((value) => value.fragmentShader()).value;
});

final hoveredSectionProvider = StateProvider((ref) => 0);

class Wheel extends ConsumerWidget {
  Wheel({required this.sectionSize, super.key});

  final int sectionSize;
  late final double sectionAngle = 2 * pi / sectionSize;

  _updateHoverdSection(PointerEvent event, Size size, WidgetRef ref) {
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
    final shader = ref.watch(wheelShaderProvider);
    final section = ref.watch(hoveredSectionProvider);

    return Listener(
      onPointerHover: (event) => _updateHoverdSection(event, size, ref),
      child: CustomPaint(
        painter: WheelPainter(
            size: size,
            sectionSize: sectionSize,
            section: section,
            shader: shader),
      ),
    );
  }
}

class WheelPainter extends CustomPainter {
  WheelPainter(
      {required this.size,
      required this.sectionSize,
      required this.section,
      required this.shader});

  final Size size;
  final int sectionSize;
  final int section;
  final FragmentShader? shader;

  @override
  void paint(Canvas canvas, Size size) {
    if (shader != null) {
      shader!.setFloat(0, size.width);
      shader!.setFloat(1, size.height);
      shader!.setFloat(2, sectionSize.toDouble());
      shader!.setFloat(3, section.toDouble());
    }
    // canvas.drawCircle(const Offset(0, 0), 300, Paint());
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(WheelPainter oldDelegate) {
    if (oldDelegate.section != section) {
      return true;
    }
    return false;
  }
}
