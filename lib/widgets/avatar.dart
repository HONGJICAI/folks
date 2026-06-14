import 'package:flutter/material.dart';

// 默认（移动/桌面）用 io 版，web 换成 web 版；两者都导出 localImageProvider。
import 'local_image_io.dart'
    if (dart.library.html) 'local_image_web.dart';

/// 圆形头像：有照片用照片，否则用首字。颜色走主题 primary，全 App 复用。
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.photoPath, this.radius = 20});

  final String name;
  final String? photoPath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary.withValues(alpha: 0.1),
      // 照片盖在首字之上；加载失败则吞掉错误、露出首字兜底。
      foregroundImage: hasPhoto ? localImageProvider(photoPath!) : null,
      onForegroundImageError: hasPhoto ? (_, _) {} : null,
      child: Text(
        name.characters.first,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
