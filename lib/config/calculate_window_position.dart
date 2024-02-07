import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';

Future<Offset> calculateWindowPosition(
    {required Size windowSize,
    Alignment? alignment,
    Offset? offset,
// display names are wrong in the plugin so we use index,
// can be changed to display names if https://github.com/leanflutter/screen_retriever/issues/19 is fixed.
    String display = '1'}) async {
  Offset cursorScreenPoint = await screenRetriever.getCursorScreenPoint();
  if (alignment == null) {
    return Offset(cursorScreenPoint.dx - windowSize.width * 0.5, cursorScreenPoint.dy - windowSize.height * 0.5);
  }

  Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
  List<Display> allDisplays = await screenRetriever.getAllDisplays();

  Display currentDisplay;

  int? displayIndex = int.tryParse(display);

  if (displayIndex == null) {
    currentDisplay = allDisplays.firstWhere(
      (display) => Rect.fromLTWH(
        display.visiblePosition!.dx,
        display.visiblePosition!.dy,
        display.size.width,
        display.size.height,
      ).contains(cursorScreenPoint),
      orElse: () => primaryDisplay,
    );
  } else {
    currentDisplay = allDisplays.length >= displayIndex ? allDisplays[displayIndex - 1] : primaryDisplay;
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

  //adjust offset
  if (offset != null) {
    visibleStartX += offset.dx;
    visibleStartY += offset.dy;
    visibleWidth -= (offset.dx + visibleStartX);
    visibleHeight -= (offset.dy + visibleStartY);
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
  return position;
}
