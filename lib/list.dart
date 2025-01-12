import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puppet/plugin/plugin_model.dart';
import 'package:puppet/providers.dart';
import 'package:puppet/widgets/item_icon.dart';
import 'package:puppet/config/theme.dart' as t;

final hoveredItemProvider = StateProvider<int>((ref) => -1);

class ListMenu extends ConsumerWidget {
  const ListMenu({
    required this.maxElement,
    required this.menuName,
    super.key,
  });

  final int maxElement;
  final String menuName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    final theme = ref.watch(currentThemeProvider);

    return switch (theme) {
      AsyncData(:final value) => _ListContainer(
          items: items,
          theme: value[menuName],
          menuName: menuName,
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _ListContainer extends ConsumerWidget {
  const _ListContainer({
    required this.items,
    required this.theme,
    required this.menuName,
  });

  final List<PluginItem> items;
  final t.Theme? theme;
  final String menuName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoveredIndex = ref.watch(hoveredItemProvider);

    return Container(
      decoration: BoxDecoration(
        color: switch (theme?.backgroundColor) {
          t.ThemeColorSolid(:final value) => value,
          t.ThemeColorGradient(:final value) => null,
          _ => null,
        },
        gradient: switch (theme?.backgroundColor) {
          t.ThemeColorGradient(:final value) => value,
          _ => null,
        },
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: switch (theme?.outlineColor) {
            t.ThemeColorSolid(:final value) => value,
            _ => Colors.transparent,
          },
          width: switch (theme?.outlineThickness) {
            t.AONAuto() => 1,
            t.AONInt(:final value) => value.toDouble(),
            _ => 1,
          },
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        separatorBuilder: (_, __) => _Separator(theme: theme),
        itemBuilder: (_, index) => _ListItem(
          item: items[index],
          index: index,
          isHovered: index == hoveredIndex,
          theme: theme,
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
    return Divider(
      color: switch (theme?.separatorColor) {
        t.ThemeColorSolid(:final value) => value,
        _ => Colors.transparent,
      },
      thickness: switch (theme?.separatorThickness) {
        t.AONAuto() => 1,
        t.AONInt(:final value) => value.toDouble(),
        _ => 1,
      },
    );
  }
}

class _ListItem extends ConsumerWidget {
  const _ListItem({
    required this.item,
    required this.index,
    required this.isHovered,
    required this.theme,
  });

  final PluginItem item;
  final int index;
  final bool isHovered;
  final t.Theme? theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      onEnter: (_) => ref.read(hoveredItemProvider.notifier).state = index,
      onExit: (_) => ref.read(hoveredItemProvider.notifier).state = -1,
      child: GestureDetector(
        onTap: () => ref.read(itemsProvider.notifier).onClick(item),
        child: Container(
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
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            children: [
              _ItemIcon(item: item, theme: theme),
              const SizedBox(width: 12),
              Expanded(
                child: _ItemContent(item: item, theme: theme),
              ),
              _ShortcutLabel(item: item, index: index, theme: theme),
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
        t.AONAuto() => 24,
        t.AONInt(:final value) => value.toDouble(),
        _ => 24,
      },
    );
  }
}

class _ItemContent extends StatelessWidget {
  const _ItemContent({
    required this.item,
    required this.theme,
  });

  final PluginItem item;
  final t.Theme? theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: theme?.itemNameFont.value,
            color: switch (theme?.itemFontColor) {
              t.ThemeColorSolid(:final value) => value,
              _ => null,
            },
            fontSize: switch (theme?.itemNameFontSize) {
              t.AONAuto() => 16,
              t.AONInt(:final value) => value.toDouble(),
              _ => 16,
            },
          ),
        ),
        if (item.description.isNotEmpty)
          AutoSizeText(
            item.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: theme?.descriptionFont.value,
              color: switch (theme?.descriptionFontColor) {
                t.ThemeColorSolid(:final value) => value,
                _ => null,
              },
              fontSize: switch (theme?.descriptionFontSize) {
                t.AONAuto() => 12,
                t.AONInt(:final value) => value.toDouble(),
                _ => 12,
              },
            ),
          ),
      ],
    );
  }
}

class _ShortcutLabel extends StatelessWidget {
  const _ShortcutLabel({
    required this.item,
    required this.index,
    required this.theme,
  });

  final PluginItem item;
  final int index;
  final t.Theme? theme;

  @override
  Widget build(BuildContext context) {
    if (item.shortcut == null && index >= 9) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        item.shortcut?.isNotEmpty == true
            ? '${item.shortcut}${index < 9 ? ' | ${index + 1}' : ''}'
            : '${index + 1}',
        style: TextStyle(
          color: switch (theme?.itemFontColor) {
            t.ThemeColorSolid(:final value) => value.withOpacity(0.5),
            _ => null,
          },
          fontSize: 12,
        ),
      ),
    );
  }
}
