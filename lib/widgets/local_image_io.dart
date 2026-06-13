import 'dart:io';

import 'package:flutter/material.dart';

bool _remote(String p) => p.startsWith('http') || p.startsWith('blob:');

/// 缩略图：固定尺寸、裁剪填充。
Widget buildLocalImage(String path, double size) {
  if (_remote(path)) {
    return Image.network(path,
        width: size, height: size, fit: BoxFit.cover, errorBuilder: _broken);
  }
  return Image.file(File(path),
      width: size, height: size, fit: BoxFit.cover, errorBuilder: _broken);
}

/// 全屏查看：完整显示（contain），不裁剪。
Widget buildLocalImageFill(String path) {
  if (_remote(path)) {
    return Image.network(path, fit: BoxFit.contain, errorBuilder: _broken);
  }
  return Image.file(File(path), fit: BoxFit.contain, errorBuilder: _broken);
}

Widget _broken(BuildContext _, Object _, StackTrace? _) => Container(
      width: 72,
      height: 72,
      color: const Color(0x11000000),
      child: const Icon(Icons.broken_image_outlined, size: 20),
    );
