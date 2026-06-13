import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_hint.dart';

/// 回忆 Tab：人情时光机。所有事件按日期倒序展示，金钱往来带方向与金额。
class MemoryTab extends StatelessWidget {
  const MemoryTab({super.key});

  /// 一次取齐事件 + 人物索引（用于把绑定的 person id 还原成人名）。
  Future<(List<Event>, Map<int, Person>)> _load(FolksRepository repo) async {
    final events = await repo.getAllEvents();
    final persons = await repo.getAllPersons();
    return (events, {for (final p in persons) p.id: p});
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FolksRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('回忆')),
      body: FutureBuilder<(List<Event>, Map<int, Person>)>(
        future: _load(repo),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (events, byId) = snap.data!;
          if (events.isEmpty) {
            return const EmptyHint(
              icon: Icons.favorite_outline,
              text: '还没有回忆\n记下一次随礼、一次聚会或一个里程碑',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(Dim.pad),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: Dim.gap),
            itemBuilder: (_, i) => _EventCard(event: events[i], byId: byId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('「记一笔回忆/账目」待实现')),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.byId});
  final Event event;
  final Map<int, Person> byId;

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
                  Text('${_date(event.occurDate)} · $_names',
                      style: theme.textTheme.bodySmall),
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
