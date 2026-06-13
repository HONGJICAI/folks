import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_hint.dart';
import '../widgets/event_card.dart';
import 'event_form.dart';

/// 回忆 Tab：人情时光机。所有事件按日期倒序展示，金钱往来带方向与金额。
class MemoryTab extends StatefulWidget {
  const MemoryTab({super.key});

  @override
  State<MemoryTab> createState() => _MemoryTabState();
}

class _MemoryTabState extends State<MemoryTab> {
  late final FolksRepository _repo;
  late Future<(List<Event>, Map<int, Person>)> _future;
  bool _orphanOnly = false; // 仅看无关联回忆

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _load();
    _repo.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_reload);
    super.dispose();
  }

  /// 一次取齐事件 + 人物索引（用于把绑定的 person id 还原成人名）。
  Future<(List<Event>, Map<int, Person>)> _load() async {
    final events = await _repo.getAllEvents();
    final persons = await _repo.getAllPersons();
    return (events, {for (final p in persons) p.id: p});
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addEvent() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventFormPage()),
    );
    if (added == true) _reload();
  }

  Future<void> _editEvent(Event event) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventFormPage(existing: event)),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('回忆')),
      body: FutureBuilder<(List<Event>, Map<int, Person>)>(
        future: _future,
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
          final orphanCount =
              events.where((e) => e.boundPersonIds.isEmpty).length;
          final shown = _orphanOnly
              ? events.where((e) => e.boundPersonIds.isEmpty).toList()
              : events;
          return Column(
            children: [
              // 仅在存在游离回忆时显示筛选，避免无谓干扰。
              if (orphanCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Dim.pad, Dim.pad, Dim.pad, 0),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('全部'),
                        selected: !_orphanOnly,
                        onSelected: (_) => setState(() => _orphanOnly = false),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('无关联 ($orphanCount)'),
                        selected: _orphanOnly,
                        onSelected: (_) => setState(() => _orphanOnly = true),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(Dim.pad),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Dim.gap),
                  itemBuilder: (_, i) => EventCard(
                    event: shown[i],
                    byId: byId,
                    onTap: () => _editEvent(shown[i]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_memory',
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
