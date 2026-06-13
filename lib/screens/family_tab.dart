import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/person.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';
import '../widgets/empty_hint.dart';
import '../widgets/language_toggle.dart';
import 'person_detail.dart';
import 'person_form.dart';

/// 家族 Tab：把内嵌的 父/母/配偶 关系还原成一棵（森林）树，缩进展示。
///
/// 夫妻主副规则：**血亲为主、姻亲为副**（按 [Person.marriedIn]）。
/// 两边都是血亲（如父母）时按 id 稳定兜底，并支持点击「主副对调」手动调整。
class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  late final FolksRepository _repo;
  late Future<List<Person>> _future;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _repo.getPersonsByGroup(PersonGroup.family); // 首帧直接赋值，不用 setState
    _repo.changes.addListener(_reload); // 任意数据变更后自动刷新
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _repo.getPersonsByGroup(PersonGroup.family);
    });
  }

  Future<void> _promote(int personId) async {
    await _repo.setBloodPrimary(personId); // 把副位提升为血亲主位
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabFamily),
        actions: const [LanguageToggle()],
      ),
      body: FutureBuilder<List<Person>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final people = snap.data ?? const <Person>[];
          if (people.isEmpty) {
            return EmptyHint(
              icon: Icons.account_tree_outlined,
              text: context.l10n.familyEmpty,
            );
          }
          final rows = _buildForest(people);
          return ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) const Divider(),
                      rows[i],
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_family',
        onPressed: _addMember,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// 将平面成员列表还原成缩进树。配偶成对显示，子女去重（一个孩子有父母两条边只渲染一次）。
  List<Widget> _buildForest(List<Person> people) {
    final byId = {for (final p in people) p.id: p};
    List<Person> childrenOf(int id) =>
        people.where((p) => p.fatherId == id || p.motherId == id).toList();
    bool hasParentInSet(Person p) =>
        (p.fatherId != null && byId.containsKey(p.fatherId)) ||
        (p.motherId != null && byId.containsKey(p.motherId));

    final visited = <int>{};
    final rows = <Widget>[];

    void walk(Person p, int depth) {
      if (visited.contains(p.id)) return;
      visited.add(p.id);
      final spouse = p.spouseId != null ? byId[p.spouseId] : null;
      if (spouse != null) visited.add(spouse.id);

      // 血亲为主、姻亲为副；两边同为血亲时按 id 稳定兜底。
      var primary = p;
      var secondary = spouse;
      if (spouse != null) {
        final pBlood = !p.marriedIn;
        final sBlood = !spouse.marriedIn;
        final spouseWins =
            (sBlood && !pBlood) || (pBlood == sBlood && spouse.id < p.id);
        if (spouseWins) {
          primary = spouse;
          secondary = p;
        }
      }

      final secId = secondary?.id;
      final primaryId = primary.id;
      rows.add(_FamilyRow(
        primary: primary,
        secondary: secondary,
        depth: depth,
        onOpen: () => _openPerson(primaryId),
        onSwap: secId == null ? null : () => _promote(secId),
      ));

      // 子女取自夫妻双方，合并去重（与主副无关）。
      final kids = <int, Person>{};
      for (final k in childrenOf(p.id)) {
        kids[k.id] = k;
      }
      if (spouse != null) {
        for (final k in childrenOf(spouse.id)) {
          kids[k.id] = k;
        }
      }
      for (final k in kids.values) {
        walk(k, depth + 1);
      }
    }

    for (final r in people.where((p) => !hasParentInSet(p))) {
      walk(r, 0);
    }
    for (final p in people) {
      if (!visited.contains(p.id)) walk(p, 0);
    }
    return rows;
  }

  Future<void> _addMember() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const PersonFormPage(group: PersonGroup.family)),
    );
    if (added == true) _reload();
  }

  /// 打开详情页，返回后刷新（详情页里可能编辑/调换了关系）。
  Future<void> _openPerson(int personId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonDetailPage(personId: personId)),
    );
    _reload();
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    required this.primary,
    this.secondary,
    required this.depth,
    this.onOpen,
    this.onSwap,
  });

  final Person primary;
  final Person? secondary;
  final int depth;
  final VoidCallback? onOpen;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = primary.ageAt(DateTime.now());
    final subtitle = [
      if (primary.customAppellation != null) primary.customAppellation!,
      if (age != null) context.l10n.ageYears(age),
    ].join(' · ');

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Dim.pad + depth * 20.0, 12, Dim.pad, 12),
        child: Row(
          children: [
            Avatar(name: primary.realName),
            const SizedBox(width: Dim.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(primary.displayName,
                            style: theme.textTheme.titleMedium),
                      ),
                      if (secondary != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.favorite,
                              size: 12, color: scheme.primary),
                        ),
                        Flexible(
                          child: Text(secondary!.displayName,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (secondary != null)
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 18),
                color: scheme.outline,
                tooltip: context.l10n.swapPrimary,
                onPressed: onSwap,
              ),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
