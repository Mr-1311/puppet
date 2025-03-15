import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';

Future<(Offset, Size?)> calculateWindowPosition(
    {required Size windowSize,
    required Alignment? alignment,
    required List<Offset> offsets,
// display names are wrong in the plugin so we use index,
// can be changed to display names if https://github.com/leanflutter/screen_retriever/issues/19 is fixed.
    String display = '1'}) async {
  Offset cursorScreenPoint = await screenRetriever.getCursorScreenPoint();
  if (alignment == null) {
    return (Offset(cursorScreenPoint.dx - windowSize.width * 0.5,
        cursorScreenPoint.dy - windowSize.height * 0.5), null);
  }

  Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
  List<Display> allDisplays = await screenRetriever.getAllDisplays();

  Display currentDisplay;

  int? displayIndex = int.tryParse(display);

  if (displayIndex == null) {
    final currentDisplayIndex = allDisplays.indexWhere(
      (display) => Rect.fromLTWH(
        display.visiblePosition!.dx,
        display.visiblePosition!.dy,
        display.size.width,
        display.size.height,
      ).contains(cursorScreenPoint),
    );
    currentDisplay = currentDisplayIndex == -1
        ? primaryDisplay
        : allDisplays[currentDisplayIndex];
    displayIndex = currentDisplayIndex == -1 ? 1 : currentDisplayIndex + 1;
  } else {
    currentDisplay = allDisplays.length >= displayIndex
        ? allDisplays[displayIndex - 1]
        : primaryDisplay;
  }



  num visibleWidth = currentDisplay.size.width;
  num visibleHeight = currentDisplay.size.height;
  num visibleStartX = 0;
  num visibleStartY = 0;

  if (currentDisplay.visibleSize != null) {
    visibleWidth = currentDisplay.visibleSize!.width;
    visibleHeight = currentDisplay.visibleSize!.height;
  }
  if (currentDisplay.visiblePosition != null) {
    visibleStartX = currentDisplay.visiblePosition!.dx;
    visibleStartY = currentDisplay.visiblePosition!.dy;
  }

  Offset position = const Offset(0, 0);

  if (alignment == Alignment.topLeft) {
    position = Offset(
      visibleStartX + 0,
      visibleStartY + 0,
    );
  } else if (alignment == Alignment.topCenter) {
    position = Offset(
      visibleStartX + (visibleWidth / 2) - (windowSize.width / 2),
      visibleStartY + 0,
    );
  } else if (alignment == Alignment.topRight) {
    position = Offset(
      visibleStartX + visibleWidth - windowSize.width,
      visibleStartY + 0,
    );
  } else if (alignment == Alignment.centerLeft) {
    position = Offset(
      visibleStartX + 0,
      visibleStartY + ((visibleHeight / 2) - (windowSize.height / 2)),
    );
  } else if (alignment == Alignment.center) {
    position = Offset(
      visibleStartX + (visibleWidth / 2) - (windowSize.width / 2),
      visibleStartY + ((visibleHeight / 2) - (windowSize.height / 2)),
    );
  } else if (alignment == Alignment.centerRight) {
    position = Offset(
      visibleStartX + visibleWidth - windowSize.width,
      visibleStartY + ((visibleHeight / 2) - (windowSize.height / 2)),
    );
  } else if (alignment == Alignment.bottomLeft) {
    position = Offset(
      visibleStartX + 0,
      visibleStartY + (visibleHeight - windowSize.height),
    );
  } else if (alignment == Alignment.bottomCenter) {
    position = Offset(
      visibleStartX + (visibleWidth / 2) - (windowSize.width / 2),
      visibleStartY + (visibleHeight - windowSize.height),
    );
  } else if (alignment == Alignment.bottomRight) {
    position = Offset(
      visibleStartX + visibleWidth - windowSize.width,
      visibleStartY + (visibleHeight - windowSize.height),
    );
  }

  final off = offsets[displayIndex - 1];
  final x = switch (alignment.x) {
    -1.0 => position.dx + off.dx,
    1.0 => position.dx - off.dx,
    _ => position.dx,
  };
  final y = switch (alignment.y) {
    -1.0 => position.dy + off.dy,
    1.0 => position.dy - off.dy,
    _ => position.dy,
  };
  return (Offset(x, y), currentDisplay.size);
}

Future<Offset> getWindowOffsetOnMouse(Size windowSize) async {
  Offset cursorScreenPoint = await screenRetriever.getCursorScreenPoint();
  return Offset(cursorScreenPoint.dx - windowSize.width * 0.5,
      cursorScreenPoint.dy - windowSize.height * 0.5);
}

// waylandSetAnchors(Alignment? alignment) {
//   _waylandClearAnchors();
//   if (alignment == null || alignment == Alignment.center) {
//     return;
//   }
//   final wls = WaylandLayerShell();
//   if (alignment.x == -1) {
//     wls.setAnchor(ShellEdge.edgeLeft, true);
//   } else if (alignment.x == 1) {
//     wls.setAnchor(ShellEdge.edgeRight, true);
//   }
//   if (alignment.y == -1) {
//     wls.setAnchor(ShellEdge.edgeTop, true);
//   } else if (alignment.y == 1) {
//     wls.setAnchor(ShellEdge.edgeBottom, true);
//   }
// }

// _waylandClearAnchors() {
//   final wls = WaylandLayerShell();
//   wls.setAnchor(ShellEdge.edgeBottom, false);
//   wls.setAnchor(ShellEdge.edgeLeft, false);
//   wls.setAnchor(ShellEdge.edgeRight, false);
//   wls.setAnchor(ShellEdge.edgeTop, false);
// }