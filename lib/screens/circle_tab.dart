import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_hint.dart';
import 'person_detail.dart';
import 'person_form.dart';

/// 圈子 Tab：按标签分组展示。一个人有多个标签时会出现在多个分组下（聚类，非互斥）。
class CircleTab extends StatefulWidget {
  const CircleTab({super.key});

  @override
  State<CircleTab> createState() => _CircleTabState();
}

class _CircleTabState extends State<CircleTab> {
  late final FolksRepository _repo;
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _repo.getPersonsByGroup(PersonGroup.circle);
    _repo.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _repo.getPersonsByGroup(PersonGroup.circle);
    });
  }

  Future<void> _addFriend() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const PersonFormPage(group: PersonGroup.circle)),
    );
    if (added == true) _reload();
  }

  /// 打开详情页，返回后刷新（详情页里可能编辑过资料）。
  Future<void> _openPerson(int personId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonDetailPage(personId: personId)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圈子')),
      body: FutureBuilder<List<Person>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final people = snap.data ?? const <Person>[];
          if (people.isEmpty) {
            return const EmptyHint(
              icon: Icons.groups_outlined,
              text: '还没有朋友\n点右下角添加，并打上标签归类',
            );
          }
          return _GroupedList(people: people, onOpen: _openPerson);
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_circle',
        onPressed: _addFriend,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.people, required this.onOpen});
  final List<Person> people;
  final void Function(int personId) onOpen;

  @override
  Widget build(BuildContext context) {
    // 按标签聚类；无标签的归到「未分组」。
    final tagToPeople = <String, List<Person>>{};
    final untagged = <Person>[];
    for (final p in people) {
      if (p.tags.isEmpty) {
        untagged.add(p);
      } else {
        for (final t in p.tags) {
          tagToPeople.putIfAbsent(t, () => []).add(p);
        }
      }
    }
    final tags = tagToPeople.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(Dim.pad),
      children: [
        for (final t in tags) ...[
          _SectionHeader(title: '#$t', count: tagToPeople[t]!.length),
          _PeopleCard(people: tagToPeople[t]!, onOpen: onOpen),
          const SizedBox(height: Dim.pad),
        ],
        if (untagged.isNotEmpty) ...[
          _SectionHeader(title: '未分组', count: untagged.length),
          _PeopleCard(people: untagged, onOpen: onOpen),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          Text(title,
              style: TextStyle(
                  color: scheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('$count',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.people, required this.onOpen});
  final List<Person> people;
  final void Function(int personId) onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < people.length; i++) ...[
            if (i > 0) const Divider(),
            _FriendRow(person: people[i], onOpen: onOpen),
          ],
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.person, required this.onOpen});
  final Person person;
  final void Function(int personId) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = person.ageAt(DateTime.now());

    return InkWell(
      onTap: () => onOpen(person.id),
      child: Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Row(
          children: [
            Avatar(name: person.realName),
            const SizedBox(width: Dim.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.displayName, style: theme.textTheme.titleMedium),
                  if (age != null)
                    Text('$age 岁', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
