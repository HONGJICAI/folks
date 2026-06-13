import 'package:flutter/material.dart';

// 条件导入：默认（移动/桌面）用 dart:io 的 Image.file；web 换成 Image.network（blob URL）。
// 这样 dart:io 不会进入 web 构建。
import 'local_image_io.dart' if (dart.library.html) 'local_image_web.dart'
    as impl;

/// 缩略图：固定尺寸、圆角裁剪。跨 web / 移动端。
class LocalImage extends StatelessWidget {
  const LocalImage(this.path, {super.key, this.size = 72});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: impl.buildLocalImage(path, size),
    );
  }
}

/// 全屏查看用：完整显示，不裁剪。
class FullImage extends StatelessWidget {
  const FullImage(this.path, {super.key});

  final String path;

  @override
  Widget build(BuildContext context) => impl.buildLocalImageFill(path);
}
