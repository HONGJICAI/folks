import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/repository.dart';
import '../models/balance.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../l10n/l10n.dart';
import '../widgets/avatar.dart';
import '../widgets/event_card.dart';
import 'event_detail.dart';
import 'event_form.dart';
import 'person_form.dart';

/// 成员详情页：头部资料 + 差额清算面板 + 个人时光轴。
class PersonDetailPage extends StatefulWidget {
  const PersonDetailPage({super.key, required this.personId});

  final int personId;

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _DetailData {
  _DetailData(this.person, this.events, this.balance, this.byId, this.children);
  final Person? person;
  final List<Event> events;
  final PersonBalance balance;
  final Map<int, Person> byId;
  final List<Person> children; // 父/母指向该人的成员
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

  /// 快捷「记一笔」：自动绑定当前这个人。
  Future<void> _addMemory(int personId) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => EventFormPage(presetPersonIds: [personId])),
    );
    if (saved == true) _reload();
  }

  Future<void> _deletePerson() async {
    final p = _loaded;
    if (p == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteMemberTitle),
        content: Text(context.l10n.deleteMemberBody(p.displayName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.actionDelete)),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deletePerson(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.toastDeleted)),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<_DetailData> _load() async {
    final person = await _repo.getPerson(widget.personId);
    final events = await _repo.getEventsByPerson(widget.personId);
    final balance = await _repo.getBalanceWith(widget.personId);
    final all = await _repo.getAllPersons();
    final children = all
        .where((p) =>
            p.fatherId == widget.personId || p.motherId == widget.personId)
        .toList();
    return _DetailData(
      person,
      events,
      balance,
      {for (final p in all) p.id: p},
      children,
    );
  }

  Future<void> _addChild(Person parent) async {
    bool? isFather;
    if (parent.gender == Gender.male) {
      isFather = true;
    } else if (parent.gender == Gender.female) {
      isFather = false;
    } else {
      // 性别未知：问一下父/母（用户可取消）。
      isFather = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.chooseParentRole),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(ctx.l10n.relationFather)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(ctx.l10n.relationMother)),
          ],
        ),
      );
      if (isFather == null) return; // 取消
    }
    if (!mounted) return;
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) =>
              PersonFormPage(parentOf: parent, parentIsFather: isFather)),
    );
    if (added == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (context, snap) {
        final person = snap.data?.person;
        _loaded = person;
        return Scaffold(
          appBar: AppBar(
            actions: [
              if (person != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: context.l10n.actionEdit,
                  onPressed: _editPerson,
                ),
              // "我"是固定成员，不提供删除。
              if (person != null && !person.isSelf)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.l10n.actionDelete,
                  onPressed: _deletePerson,
                ),
            ],
          ),
          body: _body(context, snap),
        );
      },
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<_DetailData> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    final data = snap.data!;
    final person = data.person;
    if (person == null) {
      return Center(child: Text(context.l10n.personGone));
    }
    return ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              _Header(person: person),
              const SizedBox(height: Dim.gap),
              if (person.group == PersonGroup.family)
                _Relations(person: person, byId: data.byId, onTap: _open),
              _ContactInfo(person: person),
              const SizedBox(height: Dim.gap),
              _ChildrenSection(
                children: data.children,
                // 年龄已知且未满 18 则不显示「添加子女」（数据合理性软门槛）；年龄未知照常显示。
                showAdd: (person.ageAt(DateTime.now()) ?? 99) >= 18,
                onOpen: _open,
                onAdd: () => _addChild(person),
              ),
              if (data.balance.hasAny) ...[
                const SizedBox(height: Dim.gap),
                _BalancePanel(balance: data.balance),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(context.l10n.timelineTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _addMemory(person.id),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.l10n.recordEntry),
                  ),
                ],
              ),
              const SizedBox(height: Dim.gap),
              if (data.events.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(context.l10n.noRecordsWith(person.displayName),
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
      person.gender.label(context.l10n),
      if (age != null) context.l10n.ageYears(age),
    ].join(' · ');

    return Row(
      children: [
        Avatar(name: person.name, photoPath: person.photoPath, radius: 32),
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
    final t = context.l10n;
    final rows = <Widget>[];
    void add(String label, int? id) {
      final p = id == null ? null : byId[id];
      if (p != null) {
        rows.add(ListTile(
          dense: true,
          leading: const Icon(Icons.link, size: 18),
          title: Text('$label: ${p.displayName}'),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => onTap(p.id),
        ));
      }
    }

    add(t.relationFather, person.fatherId);
    add(t.relationMother, person.motherId);
    add(t.relationSpouse, person.spouseId);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// 子女区：列出父/母指向该人的成员，并提供「添加子女」（家族/圈子通用）。
class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection(
      {required this.children,
      required this.showAdd,
      required this.onOpen,
      required this.onAdd});
  final List<Person> children;
  final bool showAdd;
  final void Function(int personId) onOpen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    // 既无子女、又不允许添加 → 整块不显示。
    if (children.isEmpty && !showAdd) return const SizedBox.shrink();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final c in children)
            ListTile(
              dense: true,
              leading: Avatar(name: c.name, photoPath: c.photoPath, radius: 16),
              title: Text(c.displayName),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => onOpen(c.id),
            ),
          if (showAdd)
            ListTile(
              dense: true,
              leading: const Icon(Icons.person_add_alt, size: 18),
              title: Text(t.addChild),
              onTap: onAdd,
            ),
        ],
      ),
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
        trailing: const Icon(Icons.call, size: 16),
        onTap: () => _launch(context, 'tel:${person.phone}'),
      ));
    }
    if (person.email != null) {
      rows.add(ListTile(
        dense: true,
        leading: const Icon(Icons.email_outlined, size: 18),
        title: Text(person.email!),
        trailing: const Icon(Icons.mail_outline, size: 16),
        onTap: () => _launch(context, 'mailto:${person.email}'),
      ));
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: Dim.gap),
      child: Card(clipBehavior: Clip.antiAlias, child: Column(children: rows)),
    );
  }

  Future<void> _launch(BuildContext context, String uri) async {
    final parsed = Uri.tryParse(uri);
    if (parsed != null) await launchUrl(parsed); // 失败静默（无可用拨号/邮件应用）
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
            Text(context.l10n.exchangesTitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: Dim.gap),
            Row(
              children: [
                _Stat(label: context.l10n.youGave, value: balance.totalExpense),
                const SizedBox(width: 32),
                _Stat(
                    label: context.l10n.youReceived,
                    value: balance.totalIncome),
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
        Text('¥${value.toStringAsFixed(0)}',
            style: theme.textTheme.titleMedium),
      ],
    );
  }
}
