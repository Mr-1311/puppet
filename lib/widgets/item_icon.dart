import 'package:flutter/material.dart';

class ItemIcon extends StatelessWidget {
  const ItemIcon({required dynamic this.iconData, required this.size, super.key});

  final dynamic iconData;
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
