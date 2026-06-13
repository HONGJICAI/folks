import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_hint.dart';

/// 圈子 Tab：平面列表 + 标签聚类（不建人与人的边）。
class CircleTab extends StatelessWidget {
  const CircleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FolksRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('圈子')),
      body: FutureBuilder<List<Person>>(
        future: repo.getPersonsByGroup(PersonGroup.circle),
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
          return ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < people.length; i++) ...[
                      if (i > 0) const Divider(),
                      _FriendRow(person: people[i]),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('「添加朋友」待实现')),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = person.ageAt(DateTime.now());

    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('「朋友详情页」待实现')),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
