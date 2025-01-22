import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/widgets/item_icon.dart';
import 'package:puppet/config/theme.dart' as t;
import 'dart:math' as math;

// Default sizes
const double kDefaultIconSize = 24;
const double kDefaultItemNameFontSize = 16;
const double kDefaultDescriptionFontSize = 12;
const double kShortcutLabelFontSize = 10;

// Spacing and padding
const double kItemVerticalPadding = 8;
const double kItemHorizontalPadding = 12;
const double kIconTextSpacing = 12;
const double kTextLineSpacing = 2;
const double kShortcutLabelHorizontalPadding = 8;
const double kShortcutLabelVerticalPadding = 4;

// Container properties
const double kContainerBorderRadius = 8;
const double kItemBorderRadius = 4;
const double kDefaultBorderWidth = 1;

// Colors
const Color kDarkShortcutLabelColor = Color.fromARGB(128, 0, 0, 0);
const Color kLightShortcutLabelColor = Color.fromARGB(128, 255, 255, 255);

final hoveredItemProvider = StateProvider<int>((ref) => -1);

class ListMenu extends ConsumerWidget {
  const ListMenu({
    required this.maxElement,
    required this.menuName,
    required this.height,
    super.key,
  });

  final int maxElement;
  final String menuName;
  final String height;

  double _calculateIconSize(t.Theme? theme) {
    return switch (theme?.iconSize) {
      t.AONAuto() => kDefaultIconSize,
      t.AONInt(:final value) => value.toDouble(),
      _ => kDefaultIconSize,
    };
  }

  double _calculateTextHeight(BuildContext context, t.Theme theme) {
    final itemNameStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: theme.itemNameFont.value,
      fontSize: switch (theme.itemNameFontSize) {
        t.AONAuto() => kDefaultItemNameFontSize,
        t.AONInt(:final value) => value.toDouble(),
      },
    );

    final descriptionStyle = TextStyle(
      decoration: TextDecoration.none,
      fontFamily: theme.descriptionFont.value,
      fontSize: switch (theme.descriptionFontSize) {
        t.AONAuto() => kDefaultDescriptionFontSize,
        t.AONInt(:final value) => value.toDouble(),
      },
    );

    final itemNameSize = (TextPainter(
            text: TextSpan(text: 'L', style: itemNameStyle),
            maxLines: 1,
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    final descriptionSize = (TextPainter(
            text: TextSpan(text: 'L', style: descriptionStyle),
            maxLines: 1,
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: TextDirection.ltr)
          ..layout())
        .size;

    return itemNameSize.height + descriptionSize.height + kTextLineSpacing;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final theme = ref.watch(currentThemeProvider);

    final textHeight = _calculateTextHeight(context, theme);
    final iconSize = _calculateIconSize(theme);
    final containerHeight =
        math.max(iconSize, textHeight) + (kItemVerticalPadding * 2);

    return _ListContainer(
      items: items,
      theme: theme,
      menuName: menuName,
      maxElement: maxElement,
      containerHeight: containerHeight,
    );
  }
}

class _ListContainer extends ConsumerWidget {
  const _ListContainer({
    required this.items,
    required this.theme,
    required this.menuName,
    required this.maxElement,
    required this.containerHeight,
  });

  final List<PluginItem> items;
  final t.Theme? theme;
  final String menuName;
  final int maxElement;
  final double containerHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoveredIndex = ref.watch(hoveredItemProvider);

    return Container(
      decoration: BoxDecoration(
        color: switch (theme?.backgroundColor) {
          t.ThemeColorSolid(:final value) => value,
          t.ThemeColorGradient() => null,
          _ => null,
        },
        gradient: switch (theme?.backgroundColor) {
          t.ThemeColorGradient(:final value) => value,
          _ => null,
        },
        borderRadius: BorderRadius.circular(kContainerBorderRadius),
        border: switch (theme?.outlineColor) {
          t.ThemeColorSolid(:final value) => Border.all(
              color: value,
              width: switch (theme?.outlineThickness) {
                t.AONAuto() => kDefaultBorderWidth,
                t.AONInt(:final value) => value.toDouble(),
                _ => kDefaultBorderWidth,
              },
            ),
          t.ThemeColorGradient(:final value) => GradientBoxBorder(
              gradient: value,
              width: switch (theme?.outlineThickness) {
                t.AONAuto() => kDefaultBorderWidth,
                t.AONInt(:final value) => value.toDouble(),
                _ => kDefaultBorderWidth,
              },
            ),
          _ => null,
        },
      ),
      child: ListView.separated(
        padding: EdgeInsets.all(kItemVerticalPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => _Separator(theme: theme),
        itemBuilder: (_, index) => _ListItem(
          item: items[index],
          index: index,
          isHovered: index == hoveredIndex,
          theme: theme,
          maxElement: maxElement,
          containerHeight: containerHeight,
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({
    required this.theme,
  });

  final t.Theme? theme;

  @override
  Widget build(BuildContext context) {
    final thickness = switch (theme?.separatorThickness) {
      t.AONAuto() => kDefaultBorderWidth,
      t.AONInt(:final value) => value.toDouble(),
      _ => kDefaultBorderWidth,
    };

    return SizedBox(
      height: thickness,
      child: Container(
        decoration: BoxDecoration(
          color: switch (theme?.separatorColor) {
            t.ThemeColorSolid(:final value) => value,
            _ => null,
          },
          gradient: switch (theme?.separatorColor) {
            t.ThemeColorGradient(:final value) => value,
            _ => null,
          },
        ),
      ),
    );
  }
}

class _ListItem extends ConsumerWidget {
  const _ListItem({
    required this.item,
    required this.index,
    required this.isHovered,
    required this.theme,
    required this.maxElement,
    required this.containerHeight,
  });

  final PluginItem item;
  final int index;
  final bool isHovered;
  final t.Theme? theme;
  final int maxElement;
  final double containerHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeBrightness = ref.watch(currentThemeBrightnessProvider);

    return MouseRegion(
      onEnter: (_) => ref.read(hoveredItemProvider.notifier).state = index,
      onExit: (_) => ref.read(hoveredItemProvider.notifier).state = -1,
      child: GestureDetector(
        onTap: () => ref.read(itemsProvider.notifier).onClick(item),
        child: Container(
          height: containerHeight,
          decoration: BoxDecoration(
            color: isHovered
                ? switch (theme?.hoveredBackgroundColor) {
                    t.ThemeColorSolid(:final value) => value,
                    _ => null,
                  }
                : null,
            gradient: isHovered
                ? switch (theme?.hoveredBackgroundColor) {
                    t.ThemeColorGradient(:final value) => value,
                    _ => null,
                  }
                : null,
            borderRadius: BorderRadius.circular(kItemBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: kItemVerticalPadding,
            horizontal: kItemHorizontalPadding,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ItemIcon(item: item, theme: theme),
              SizedBox(width: kIconTextSpacing),
              Expanded(
                child: _ItemContent(
                  item: item,
                  theme: theme,
                  maxElement: maxElement,
                ),
              ),
              _ShortcutLabel(
                item: item,
                index: index,
                theme: theme,
                themeBrightness: themeBrightness,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({
    required this.item,
    required this.theme,
  });

  final PluginItem item;
  final t.Theme? theme;

  @override
  Widget build(BuildContext context) {
    return ItemIcon(
      icon: item.icon,
      size: switch (theme?.iconSize) {
        t.AONAuto() => kDefaultIconSize,
        t.AONInt(:final value) => value.toDouble(),
        _ => kDefaultIconSize,
      },
    );
  }
}

class _ItemContent extends ConsumerWidget {
  const _ItemContent({
    required this.item,
    required this.theme,
    required this.maxElement,
  });

  final PluginItem item;
  final t.Theme? theme;
  final int maxElement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(menuProvider);
    if (menu case AsyncData(:final value)) {
      final menuSize = value.size;

      final item_paint = Paint()..blendMode = BlendMode.src;
      switch (theme?.itemFontColor) {
        case t.ThemeColorSolid(:final value):
          item_paint.color = value;
        case t.ThemeColorGradient(:final value):
          item_paint.shader = value.createShader(
            Rect.fromLTWH(0, 0, menuSize.width, menuSize.height / maxElement),
          );
        case null:
          item_paint.color = Colors.black;
      }

      final desc_paint = Paint()..blendMode = BlendMode.src;
      switch (theme?.descriptionFontColor) {
        case t.ThemeColorSolid(:final value):
          desc_paint.color = value;
        case t.ThemeColorGradient(:final value):
          desc_paint.shader = value.createShader(
            Rect.fromLTWH(0, 0, menuSize.width, menuSize.height),
          );
        case null:
          desc_paint.color = Colors.black;
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              decoration: TextDecoration.none,
              fontFamily: theme?.itemNameFont.value,
              foreground: item_paint,
              fontSize: switch (theme?.itemNameFontSize) {
                t.AONAuto() => kDefaultItemNameFontSize,
                t.AONInt(:final value) => value.toDouble(),
                _ => kDefaultItemNameFontSize,
              },
            ),
          ),
          if (item.description.isNotEmpty)
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: TextDecoration.none,
                fontFamily: theme?.descriptionFont.value,
                foreground: desc_paint,
                fontSize: switch (theme?.descriptionFontSize) {
                  t.AONAuto() => kDefaultDescriptionFontSize,
                  t.AONInt(:final value) => value.toDouble(),
                  _ => kDefaultDescriptionFontSize,
                },
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel({
    required this.item,
    required this.index,
    required this.theme,
    required this.themeBrightness,
  });

  final PluginItem item;
  final int index;
  final t.Theme? theme;
  final bool themeBrightness;

  @override
  Widget build(BuildContext context) {
    if (item.shortcut == null && index >= 9) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kShortcutLabelHorizontalPadding,
        vertical: kShortcutLabelVerticalPadding,
      ),
      child: Text(
        item.shortcut?.isNotEmpty == true
            ? '${item.shortcut}${index < 9 ? ' | ${index + 1}' : ''}'
            : '${index + 1}',
        style: TextStyle(
          color: themeBrightness
              ? kDarkShortcutLabelColor
              : kLightShortcutLabelColor,
          letterSpacing: 2,
          decoration: TextDecoration.none,
          fontSize: kShortcutLabelFontSize,
        ),
      ),
    );
  }
}
