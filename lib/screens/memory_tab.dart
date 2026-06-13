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

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _load();
  }

  /// 一次取齐事件 + 人物索引（用于把绑定的 person id 还原成人名）。
  Future<(List<Event>, Map<int, Person>)> _load() async {
    final events = await _repo.getAllEvents();
    final persons = await _repo.getAllPersons();
    return (events, {for (final p in persons) p.id: p});
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _addEvent() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventFormPage()),
    );
    if (added == true) _reload();
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
          return ListView.separated(
            padding: const EdgeInsets.all(Dim.pad),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: Dim.gap),
            itemBuilder: (_, i) => EventCard(event: events[i], byId: byId),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
