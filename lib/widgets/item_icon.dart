import 'package:flutter/material.dart';
import 'package:puppet/config/config.dart';

class ItemIcon extends StatelessWidget {
  ItemIcon({required String icon, required this.size, this.color, super.key}) {
    if (iconDatas.containsKey(icon)) {
      iconData = iconDatas[icon];
    } else {
      iconData = getIconData(icon);
      iconDatas[icon] = iconData;
    }
  }

  late final dynamic iconData;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return switch (iconData) {
      (MemoryImage()) => Image(image: iconData, width: size, height: size),
      (IconData()) => Icon(iconData, size: size, color: color),
      _ => SizedBox.shrink(),
    };
  }
}
