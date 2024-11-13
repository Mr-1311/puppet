import 'package:flutter/material.dart';
import 'package:puppet/config/config.dart';

class ItemIcon extends StatelessWidget {
  ItemIcon({required String icon, required this.size, super.key}) {
    iconData = iconDatas[icon];
  }

  late final dynamic iconData;
  final double size;

  @override
  Widget build(BuildContext context) {
    return switch (iconData) {
      (MemoryImage()) => Image(image: iconData, width: size, height: size),
      (IconData()) => Icon(iconData, size: size),
      _ => SizedBox.shrink(),
    };
  }
}
