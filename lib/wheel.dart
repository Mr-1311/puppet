import 'dart:math';
import 'dart:ui' as ui;

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:puppet/config/config.dart';
import 'package:puppet/config_providers.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:puppet/config/theme.dart' as t;
import 'package:system_fonts/system_fonts.dart';

final hoveredSectionProvider = StateProvider<int>((ref) => 0);

final currentItemsProvider =
    NotifierProvider.family<CurrentItemsNotifier, List<Items>, int>(() => CurrentItemsNotifier());

class CurrentItemsNotifier extends FamilyNotifier<List<Items>, int> {
  int _index = 0;
  @override
  List<Items> build(int maxElement) {
    final items = ref.watch(itemsProvider);
    if (items.length > maxElement) {
      return items.sublist(0, maxElement);
    }
    return items;
  }

  void next(int maxElement) {
    final allItems = ref.read(itemsProvider);
    if (allItems.length > _index + maxElement) {
      int to = (_index + maxElement * 2) > allItems.length ? allItems.length : (_index + maxElement * 2);
      _index += maxElement;
      state = allItems.sublist(_index, to);
      ref.read(currentPageProvider.notifier).state += 1;
    }
  }

  void prev(int maxElement) {
    final allItems = ref.read(itemsProvider);
    if (_index - maxElement >= 0) {
      _index -= maxElement;
      state = allItems.sublist(_index, _index + maxElement);
      ref.read(currentPageProvider.notifier).state -= 1;
    } else {
      _index = 0;
      if (allItems.length > maxElement) {
        state = allItems.sublist(_index, maxElement);
      } else {
        state = [...allItems];
      }

      ref.read(currentPageProvider.notifier).state = max(ref.read(currentPageProvider) - 1, 0);
    }
  }
}

final currentPageProvider = StateProvider<int>((ref) => 0);

class Wheel extends ConsumerWidget {
  Wheel({required this.maxElement, required this.menuName, super.key});

  final int maxElement;
  final String menuName;

  _updateHoverSection(PointerEvent event, Size size, double sectionAngle, double centerSize, WidgetRef ref) {
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
    if (distToCenter > radius || distToCenter < (centerSize / size.shortestSide)) {
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

  (double, double) _getMenuFontSize(double centerSize, t.Theme theme) {
    var menuFontSizeMax = (centerSize * .4).floorToDouble();
    var menuFontSizeMin = (centerSize * .2).floorToDouble();
    if (theme.menuNameFontSize case t.AONInt()) {
      menuFontSizeMax = (theme.menuNameFontSize as t.AONInt).value.toDouble();
      menuFontSizeMin = (theme.menuNameFontSize as t.AONInt).value.toDouble();
    }
    return (menuFontSizeMax, menuFontSizeMin);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final section = ref.watch(hoveredSectionProvider);
    final currentItems = ref.watch(currentItemsProvider(maxElement));
    final double sectionAngle = 2 * pi / currentItems.length;
    final centerSize = size.shortestSide * 0.15;
    final pageSize = (ref.watch(itemsProvider).length / maxElement).ceil();
    final currentPage = ref.watch(currentPageProvider);
    final theme = ref.watch(currentThemeProvider);

    final menuFontSize = _getMenuFontSize(centerSize, theme);

    return MouseRegion(
      onExit: (event) => ref.read(hoveredSectionProvider.notifier).state = 0,
      child: Listener(
        onPointerHover: (event) => _updateHoverSection(event, size, sectionAngle, centerSize, ref),
        onPointerUp: (event) {
          print(ref.read(hoveredSectionProvider));
          _updateHoverSection(event, size, sectionAngle, centerSize, ref);
        },
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            if (pointerSignal.scrollDelta.direction.isNegative)
              ref.read(currentItemsProvider(maxElement).notifier).prev(maxElement);
            else
              ref.read(currentItemsProvider(maxElement).notifier).next(maxElement);
          }
        },
        child: Stack(
          children: [
            SizedBox.expand(
              child: CustomPaint(
                painter: WheelPainter(
                  size: size,
                  sectionSize: currentItems.length,
                  section: section,
                  centerSize: centerSize,
                  backgroundColor: theme.backgroundColor,
                  separatorColor: theme.separatorColor,
                  outlineColor: theme.outlineColor,
                  centerColor: theme.centerColor,
                  hoveredBackgroundColor: theme.hoveredBackgroundColor,
                  separatorThickness: theme.separatorThickness,
                  outlineThickness: theme.outlineThickness,
                ),
              ),
            ),
            ...getMenuItems(currentItems, size, sectionAngle, theme),
            Center(
              child: Container(
                width: centerSize * 1.8,
                height: centerSize * 1.5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AutoSizeText(
                      '$menuName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      maxFontSize: menuFontSize.$1,
                      minFontSize: menuFontSize.$2,
                    ),
                    AnimatedSmoothIndicator(
                        count: pageSize,
                        activeIndex: currentPage,
                        effect: ScrollingDotsEffect(
                          maxVisibleDots: 5,
                          spacing: centerSize * .05,
                          dotHeight: centerSize * .1,
                          dotWidth: centerSize * .1,
                        )),
                  ],
                ),
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
    required this.centerSize,
    required this.backgroundColor,
    required this.separatorColor,
    required this.outlineColor,
    required this.centerColor,
    required this.hoveredBackgroundColor,
    required this.separatorThickness,
    required this.outlineThickness,
  });

  final Size size;
  final int sectionSize;
  final int section;
  final double centerSize;

  final t.ThemeColor backgroundColor;
  final t.ThemeColor separatorColor;
  final t.ThemeColor outlineColor;
  final t.ThemeColor centerColor;
  final t.ThemeColor hoveredBackgroundColor;
  final t.AutoOrNum separatorThickness;
  final t.AutoOrNum outlineThickness;

  @override
  void paint(Canvas canvas, Size size) {
    final shortSide = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);

    final sectionAngle = 2 * pi / sectionSize;

    // background
    final bg_paint = Paint();
    switch (backgroundColor) {
      case t.ThemeColorSolid():
        bg_paint.color = (backgroundColor as t.ThemeColorSolid).value;
      case t.ThemeColorGradient():
        bg_paint.shader = (backgroundColor as t.ThemeColorGradient)
            .value
            .createShader(Rect.fromCenter(center: center, width: shortSide, height: shortSide));
    }
    canvas.drawCircle(center, (shortSide / 2) - 1, bg_paint);

    // section
    final sc_paint = Paint()..blendMode = BlendMode.src;
    switch (hoveredBackgroundColor) {
      case t.ThemeColorSolid():
        sc_paint.color = (hoveredBackgroundColor as t.ThemeColorSolid).value;
      case t.ThemeColorGradient():
        sc_paint.shader = (hoveredBackgroundColor as t.ThemeColorGradient)
            .value
            .createShader(Rect.fromCenter(center: center, width: shortSide, height: shortSide));
    }
    if (section != 0) {
      canvas.drawArc(Rect.fromCenter(center: center, width: shortSide, height: shortSide), -section * sectionAngle,
          sectionAngle, true, sc_paint);
    }

    // separators
    final sp_paint = Paint()..blendMode = BlendMode.src;
    switch (separatorThickness) {
      case t.AONAuto():
        sp_paint.strokeWidth = shortSide * 0.002;
      case t.AONInt():
        sp_paint.strokeWidth = (separatorThickness as t.AONInt).value.toDouble();
    }
    switch (separatorColor) {
      case t.ThemeColorSolid():
        sp_paint.color = (separatorColor as t.ThemeColorSolid).value;
      case t.ThemeColorGradient():
        sp_paint.shader = (separatorColor as t.ThemeColorGradient).value.createShader(
            Rect.fromCenter(center: center.translate(shortSide / 4, 0), width: shortSide / 2, height: shortSide / 2));
    }

    var p1 = Offset(size.width / 2, size.height / 2);
    var p2 = Offset(size.width, size.height / 2);

    if (sectionSize > 1) {
      for (var i = 0; i < sectionSize; i++) {
        canvas.drawLine(p1, p2, sp_paint);
        canvas.translate(size.width / 2, size.height / 2);
        canvas.rotate(sectionAngle);
        canvas.translate(-size.width / 2, -size.height / 2);
      }
    }

    // center
    final ct_paint = Paint()..blendMode = BlendMode.src;
    switch (centerColor) {
      case t.ThemeColorSolid():
        ct_paint.color = (centerColor as t.ThemeColorSolid).value;
      case t.ThemeColorGradient():
        ct_paint.shader = (centerColor as t.ThemeColorGradient)
            .value
            .createShader(Rect.fromCenter(center: center, width: centerSize * 2, height: centerSize * 2));
    }
    canvas.drawCircle(center, centerSize, ct_paint);

    // outline
    final ol_paint = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.src;
    switch (outlineThickness) {
      case t.AONAuto():
        ol_paint.strokeWidth = shortSide * 0.002;
      case t.AONInt():
        ol_paint.strokeWidth = (outlineThickness as t.AONInt).value.toDouble();
    }
    switch (outlineColor) {
      case t.ThemeColorSolid():
        ol_paint.color = (outlineColor as t.ThemeColorSolid).value;
      case t.ThemeColorGradient():
        ol_paint.shader = (outlineColor as t.ThemeColorGradient)
            .value
            .createShader(Rect.fromCenter(center: center, width: shortSide, height: shortSide));
    }
    canvas.drawCircle(center, (shortSide / 2) - (ol_paint.strokeWidth / 2), ol_paint);
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

List<Positioned> getMenuItems(List<Items> items, Size size, double sectionAngle, t.Theme theme) {
  List<Positioned> menuItems = [];
  SystemFonts().loadFont(theme.itemNameFont.value ?? '');
  SystemFonts().loadFont(theme.descriptionFont.value ?? '');

  final radius = size.shortestSide * 0.5;
  // biggest square inside the circle is when angle is tau/5
  final squareLength = calculateMaxSquare(radius, min(sectionAngle * 0.5, pi / 5));
  final distance = (radius * 0.9) - (squareLength * 0.5);

  final pivot_x = size.width > size.height ? (size.width - size.height) / 2 : 0;
  final pivot_y = size.height > size.width ? (size.height - size.width) / 2 : 0;

  var itemFontSizeMax = (squareLength * 0.245).floor().toDouble();
  var itemFontSizeMin = (squareLength * 0.19).floor().toDouble();
  if (theme.itemNameFontSize case t.AONInt()) {
    itemFontSizeMax = (theme.itemNameFontSize as t.AONInt).value.toDouble();
    itemFontSizeMin = (theme.itemNameFontSize as t.AONInt).value.toDouble();
  }

  var descFontSizeMax = (squareLength * 0.135).floor().toDouble();
  var descFontSizeMin = (squareLength * 0.11).floor().toDouble();
  if (theme.descriptionFontSize case t.AONInt()) {
    descFontSizeMax = (theme.descriptionFontSize as t.AONInt).value.toDouble();
    descFontSizeMin = (theme.descriptionFontSize as t.AONInt).value.toDouble();
  }
  var iconSize = squareLength * 0.3;
  if (theme.iconSize case t.AONInt()) {
    iconSize = (theme.iconSize as t.AONInt).value.toDouble();
  }

  for (int i = 1; i <= items.length; i++) {
    final angle = items.length == 1 ? pi * 0.5 : sectionAngle * i - sectionAngle * 0.5;
    menuItems.add(Positioned(
      left: radius + cos(angle) * distance - squareLength / 2 + pivot_x,
      bottom: radius + sin(angle) * distance - squareLength / 2 + pivot_y,
      child: Container(
        width: squareLength,
        height: squareLength,
        child: Column(
          children: [
            Icon(
              FontAwesomeIcons.terminal,
              size: iconSize,
            ),
            AutoSizeText(
              items[i - 1].name,
              maxFontSize: itemFontSizeMax,
              minFontSize: itemFontSizeMin,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(decoration: TextDecoration.none, fontFamily: theme.itemNameFont.value),
              textAlign: TextAlign.center,
            ),
            AutoSizeText(
              items[i - 1].description,
              maxFontSize: descFontSizeMax,
              minFontSize: descFontSizeMin,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(decoration: TextDecoration.none, fontFamily: theme.descriptionFont.value),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ));
  }
  return menuItems;
}
