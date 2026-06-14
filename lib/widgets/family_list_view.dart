import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import 'avatar.dart';

/// 家族「列表视图」：缩进表达层级，配偶成对、子女去重，与族谱图同一套主副规则。
class FamilyListView extends StatelessWidget {
  const FamilyListView({
    super.key,
    required this.people,
    required this.onOpen,
    required this.onSwap,
  });

  final List<Person> people;
  final void Function(int personId) onOpen;
  final void Function(int secondaryId) onSwap;

  @override
  Widget build(BuildContext context) {
    final rows = _buildForest(context);
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
  }

  List<Widget> _buildForest(BuildContext context) {
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

      var primary = p;
      var secondary = spouse;
      if (spouse != null) {
        final pBlood = !p.marriedIn;
        final sBlood = !spouse.marriedIn;
        if ((sBlood && !pBlood) || (pBlood == sBlood && spouse.id < p.id)) {
          primary = spouse;
          secondary = p;
        }
      }

      rows.add(_FamilyRow(
        primary: primary,
        secondary: secondary,
        depth: depth,
        onOpen: () => onOpen(primary.id),
        onSwapPersist: onSwap, // 行内乐观翻转 + 静默持久化
      ));

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
}

/// 有状态行：主副对调时**只刷新本行**（乐观就地翻转），持久化交给 [onSwapPersist]。
class _FamilyRow extends StatefulWidget {
  const _FamilyRow({
    required this.primary,
    this.secondary,
    required this.depth,
    required this.onOpen,
    this.onSwapPersist,
  });

  final Person primary;
  final Person? secondary;
  final int depth;
  final VoidCallback onOpen;
  final void Function(int newPrimaryId)? onSwapPersist;

  @override
  State<_FamilyRow> createState() => _FamilyRowState();
}

class _FamilyRowState extends State<_FamilyRow> {
  late Person _primary;
  Person? _secondary;

  @override
  void initState() {
    super.initState();
    _primary = widget.primary;
    _secondary = widget.secondary;
  }

  @override
  void didUpdateWidget(_FamilyRow old) {
    super.didUpdateWidget(old);
    // 父级用新数据重建（如新增成员）时，同步本地展示。
    if (old.primary.id != widget.primary.id ||
        old.secondary?.id != widget.secondary?.id) {
      _primary = widget.primary;
      _secondary = widget.secondary;
    }
  }

  void _swap() {
    final s = _secondary;
    if (s == null) return;
    setState(() {
      _secondary = _primary;
      _primary = s;
    });
    widget.onSwapPersist?.call(_primary.id); // 静默持久化，不触发整页刷新
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = _primary.ageAt(DateTime.now());
    final subtitle = [
      if (_primary.customAppellation != null) _primary.customAppellation!,
      if (age != null) context.l10n.ageYears(age),
    ].join(' · ');

    return InkWell(
      onTap: widget.onOpen,
      child: Padding(
        padding:
            EdgeInsets.fromLTRB(Dim.pad + widget.depth * 20.0, 12, Dim.pad, 12),
        child: Row(
          children: [
            Avatar(name: _primary.name, photoPath: _primary.photoPath),
            const SizedBox(width: Dim.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(_primary.displayName,
                            style: theme.textTheme.titleMedium),
                      ),
                      if (_secondary != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.favorite,
                              size: 12, color: scheme.primary),
                        ),
                        Flexible(
                          child: Text(_secondary!.displayName,
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
            if (_secondary != null)
              IconButton(
                icon: const Icon(Icons.swap_horiz, size: 18),
                color: scheme.outline,
                tooltip: context.l10n.swapPrimary,
                onPressed: _swap,
              ),
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
