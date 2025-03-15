import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:puppet/config/config.dart';

class ItemIcon extends StatelessWidget {
  ItemIcon({required String this.icon, required this.size, this.color, super.key}) {
    if (iconDatas.containsKey(icon)) {
      iconData = iconDatas[icon];
    } else {
      iconData = getIconData(icon);
      iconDatas[icon] = iconData;
    }
  }

  late final dynamic iconData;
  final String icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return switch (iconData) {
      (MemoryImage()) => icon.endsWith('.svg') ? SvgPicture.memory((iconData as MemoryImage).bytes) : Image(image: iconData, width: size, height: size),
      (IconData()) => Icon(iconData, size: size, color: color),
      _ => SizedBox.shrink(),
    };
  }
}
