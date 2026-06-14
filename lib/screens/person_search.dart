import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/person.dart';
import '../widgets/avatar.dart';
import 'person_detail.dart';

/// 全局人物搜索：覆盖所有人（家族 + 圈子），按姓名 / 小名 / 标签匹配。
/// 与"在哪个 Tab、是否打标签"无关 —— 找人就用它。
class PersonSearchDelegate extends SearchDelegate<void> {
  PersonSearchDelegate(this.repo, {required String hint})
      : super(searchFieldLabel: hint);

  final FolksRepository repo;

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    return FutureBuilder<List<Person>>(
      future: repo.searchPersons(query), // 空 query 返回全部
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data ?? const <Person>[];
        if (list.isEmpty) {
          return Center(
            child: Text(context.l10n.searchNoResults,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _ResultTile(person: list[i]),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.person});
  final Person person;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final subtitle = [
      person.group.label(t),
      if (person.customAppellation != null) person.customAppellation!,
      for (final tag in person.tags) '#$tag',
    ].join(' · ');

    return ListTile(
      leading: Avatar(name: person.realName, radius: 18),
      title: Text(person.displayName),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => PersonDetailPage(personId: person.id)),
      ),
    );
  }
}
