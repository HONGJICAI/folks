import 'package:flutter/material.dart';

/// web 端：image_picker 给的是 blob: URL、样例是 http URL，统一用 Image.network。
Widget buildLocalImage(String path, double size) {
  return Image.network(path,
      width: size, height: size, fit: BoxFit.cover, errorBuilder: _broken);
}

/// 全屏查看：完整显示（contain），不裁剪。
Widget buildLocalImageFill(String path) {
  return Image.network(path, fit: BoxFit.contain, errorBuilder: _broken);
}

Widget _broken(BuildContext _, Object _, StackTrace? _) => Container(
      width: 72,
      height: 72,
      color: const Color(0x11000000),
      child: const Icon(Icons.broken_image_outlined, size: 20),
    );
