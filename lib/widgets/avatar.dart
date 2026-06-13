import 'package:flutter/material.dart';

/// 圆形首字头像。颜色走主题 primary，全 App 复用。
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary.withValues(alpha: 0.1),
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
