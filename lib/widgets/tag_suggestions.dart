import 'package:flutter/material.dart';

/// 标签建议：点已有标签直接追加到输入框（去重）。录入人/事件时复用。
class TagSuggestions extends StatelessWidget {
  const TagSuggestions(
      {super.key,
      required this.all,
      required this.controller,
      required this.onChanged});

  final List<String> all;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final current = controller.text
        .split(RegExp(r'[,，;；\s]+'))
        .where((e) => e.isNotEmpty)
        .toSet();
    final suggestions = all.where((t) => !current.contains(t)).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in suggestions)
            ActionChip(
              label: Text('#$tag'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onPressed: () {
                final txt = controller.text.trimRight();
                controller.text = txt.isEmpty ? tag : '$txt $tag';
                onChanged();
              },
            ),
        ],
      ),
    );
  }
}
