import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

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

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                    _names.isEmpty
                        ? _date(event.occurDate)
                        : '${_date(event.occurDate)} · $_names',
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
                        Text('无关联成员',
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
    // 支出红、收入绿。红走主题语义色，避免硬编码。
    final color = isExpense ? scheme.error : Colors.green.shade600;
    final sign = isExpense ? '-' : '+';
    return Text(
      '$sign${event.amount?.toStringAsFixed(0) ?? '0'}',
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
    );
  }
}
