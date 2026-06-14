import 'package:flutter/material.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/event_card.dart';
import 'event_detail.dart';
import 'person_detail.dart';

/// 全局搜索：覆盖所有人 + 所有回忆（按姓名/小名/标签、标题/手记/标签匹配）。
/// 结果分「人物 / 回忆」两段。与在哪个 Tab、是否打标签无关。
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

  Future<(List<Person>, List<Event>, Map<int, Person>)> _load() async {
    final people = await repo.searchPersons(query);
    final events = await repo.searchEvents(query);
    final all = await repo.getAllPersons();
    return (people, events, {for (final p in all) p.id: p});
  }

  Widget _results(BuildContext context) {
    final t = context.l10n;
    return FutureBuilder<(List<Person>, List<Event>, Map<int, Person>)>(
      future: _load(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final (people, events, byId) = snap.data!;
        if (people.isEmpty && events.isEmpty) {
          return Center(
            child: Text(t.searchNoResults,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (people.isNotEmpty) ...[
              _SectionHeader(t.searchSectionPeople),
              for (final p in people) _PersonTile(person: p),
            ],
            if (events.isNotEmpty) ...[
              _SectionHeader(t.tabMemory),
              for (final e in events)
                Padding(
                  padding: const EdgeInsets.fromLTRB(Dim.pad, 4, Dim.pad, 4),
                  child: EventCard(
                    event: e,
                    byId: byId,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => EventDetailPage(eventId: e.id)),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dim.pad, 12, Dim.pad, 6),
      child: Text(title,
          style: TextStyle(
              color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});
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
