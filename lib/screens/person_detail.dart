import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/balance.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/event_card.dart';
import 'event_detail.dart';
import 'person_form.dart';

/// 成员详情页：头部资料 + 差额清算面板 + 个人时光轴。
class PersonDetailPage extends StatefulWidget {
  const PersonDetailPage({super.key, required this.personId});

  final int personId;

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _DetailData {
  _DetailData(this.person, this.events, this.balance, this.byId);
  final Person? person;
  final List<Event> events;
  final PersonBalance balance;
  final Map<int, Person> byId;
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  late final FolksRepository _repo;
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _load();
  }

  Person? _loaded; // 最近一次加载到的成员，供编辑按钮使用

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _editPerson() async {
    final p = _loaded;
    if (p == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PersonFormPage(existing: p)),
    );
    if (saved == true) _reload();
  }

  Future<void> _openEvent(Event event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
    );
    _reload(); // 详情里可能编辑/删除
  }

  Future<void> _deletePerson() async {
    final p = _loaded;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除成员'),
        content: Text('确定删除「${p.displayName}」吗？\n与 TA 的亲属/配偶关系会被解除，回忆记录里也会移除 TA。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deletePerson(p.id);
      if (mounted) Navigator.of(context).pop(true); // 返回列表（调用方会刷新）
    }
  }

  Future<_DetailData> _load() async {
    final person = await _repo.getPerson(widget.personId);
    final events = await _repo.getEventsByPerson(widget.personId);
    final balance = await _repo.getBalanceWith(widget.personId);
    final all = await _repo.getAllPersons();
    return _DetailData(
      person,
      events,
      balance,
      {for (final p in all) p.id: p},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
            onPressed: _editPerson,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '删除',
            onPressed: _deletePerson,
          ),
        ],
      ),
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          final person = data.person;
          _loaded = person;
          if (person == null) {
            return const Center(child: Text('该成员已不存在'));
          }
          return ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              _Header(person: person),
              const SizedBox(height: Dim.gap),
              if (person.group == PersonGroup.family)
                _Relations(person: person, byId: data.byId, onTap: _open),
              _ContactInfo(person: person),
              if (data.balance.hasAny) ...[
                const SizedBox(height: Dim.gap),
                _BalancePanel(balance: data.balance),
              ],
              const SizedBox(height: 24),
              Text('往来与回忆',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Dim.gap),
              if (data.events.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('还没有与 ${person.realName} 的往来记录',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                )
              else
                for (final e in data.events) ...[
                  EventCard(
                    event: e,
                    byId: data.byId,
                    onTap: () => _openEvent(e),
                  ),
                  const SizedBox(height: Dim.gap),
                ],
            ],
          );
        },
      ),
    );
  }

  void _open(int personId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonDetailPage(personId: personId)),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = person.ageAt(DateTime.now());
    final meta = [
      if (person.customAppellation != null) person.customAppellation!,
      person.gender.label,
      if (age != null) '$age 岁',
    ].join(' · ');

    return Row(
      children: [
        Avatar(name: person.realName, radius: 32),
        const SizedBox(width: Dim.pad),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.displayName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(meta, style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
              if (person.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in person.tags)
                      Chip(
                        label: Text('#$t'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 家族关系行：父 / 母 / 配偶，点击可跳到对方详情。
class _Relations extends StatelessWidget {
  const _Relations(
      {required this.person, required this.byId, required this.onTap});
  final Person person;
  final Map<int, Person> byId;
  final void Function(int personId) onTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    void add(String label, int? id) {
      final p = id == null ? null : byId[id];
      if (p != null) {
        rows.add(ListTile(
          dense: true,
          leading: const Icon(Icons.link, size: 18),
          title: Text('$label：${p.displayName}'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => onTap(p.id),
        ));
      }
    }

    add('父亲', person.fatherId);
    add('母亲', person.motherId);
    add('配偶', person.spouseId);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  const _ContactInfo({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (person.phone != null) {
      rows.add(ListTile(
        dense: true,
        leading: const Icon(Icons.phone_outlined, size: 18),
        title: Text(person.phone!),
      ));
    }
    if (person.email != null) {
      rows.add(ListTile(
        dense: true,
        leading: const Icon(Icons.email_outlined, size: 18),
        title: Text(person.email!),
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Dim.gap),
      child: Card(clipBehavior: Clip.antiAlias, child: Column(children: rows)),
    );
  }
}

/// 人情往来面板：客观呈现你支出 / 收到的总额，不做顺差/逆差的金钱判断。
class _BalancePanel extends StatelessWidget {
  const _BalancePanel({required this.balance});
  final PersonBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      color: scheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('人情往来', style: theme.textTheme.bodySmall),
            const SizedBox(height: Dim.gap),
            Row(
              children: [
                _Stat(label: '你支出', value: balance.totalExpense),
                const SizedBox(width: 32),
                _Stat(label: '你收到', value: balance.totalIncome),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(0)} 元',
            style: theme.textTheme.titleMedium),
      ],
    );
  }
}
