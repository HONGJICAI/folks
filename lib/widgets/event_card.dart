import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../util/dates.dart';
import 'local_image.dart';

/// 回忆 / 人情往来事件卡片。回忆 Tab 和成员详情页的时光轴共用。
class EventCard extends StatelessWidget {
  const EventCard(
      {super.key, required this.event, required this.byId, this.onTap});

  final Event event;

  /// person id → Person，用于把绑定的人 id 还原成人名。
  final Map<int, Person> byId;

  /// 点击回调（如打开编辑）。为空则不可点。
  final VoidCallback? onTap;

  String get _names => event.boundPersonIds
      .map((id) => byId[id]?.displayName ?? '#$id')
      .join('、');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final when = relativePast(event.occurDate, DateTime.now(), context.l10n);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeBadge(type: event.type),
            const SizedBox(width: Dim.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(event.title,
                            style: theme.textTheme.titleMedium),
                      ),
                      if (event.isMoney) _AmountBadge(event: event),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _names.isEmpty ? when : '$when · $_names',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (event.boundPersonIds.isEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 13, color: scheme.tertiary),
                        const SizedBox(width: 4),
                        Text(context.l10n.noLinkedMembers,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.tertiary)),
                      ],
                    ),
                  ],
                  if (event.detail != null && event.detail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(event.detail!,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final tag in event.tags)
                          Chip(
                            label: Text('#$tag'),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ],
                  if (event.photoPaths.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: event.photoPaths.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => LocalImage(event.photoPaths[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

/// 事件类型的小方块图标（emoji + 淡色底）。
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final EventType type;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(type.emoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

class _AmountBadge extends StatelessWidget {
  const _AmountBadge({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExpense = event.direction == MoneyDirection.expense;

    // 无金额 = 实物礼物：不显示金钱，只标送出/收到。
    if (event.amount == null) {
      final label =
          isExpense ? context.l10n.giftGiven : context.l10n.giftReceived;
      return Text('🎁 $label',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12));
    }

    final color = isExpense ? scheme.error : Colors.green.shade600;
    final sign = isExpense ? '-' : '+';
    return Text(
      '$sign${event.amount!.toStringAsFixed(0)}',
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}
