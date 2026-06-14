import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/person.dart';
import '../widgets/empty_hint.dart';
import '../widgets/family_list_view.dart';
import '../widgets/family_tree_chart.dart';
import '../widgets/search_button.dart';
import 'person_detail.dart';
import 'person_form.dart';

/// 家族 Tab：横向族谱图（节点框 + 连线，可平移/缩放）。
///
/// 夫妻主副规则：**血亲为主、姻亲为副**（按 [Person.marriedIn]），
/// 两边都是血亲（如父母）时按 id 稳定兜底；长按节点可手动「主副对调」。
class FamilyTab extends StatefulWidget {
  const FamilyTab({super.key});

  @override
  State<FamilyTab> createState() => _FamilyTabState();
}

class _FamilyTabState extends State<FamilyTab> {
  late final FolksRepository _repo;
  late Future<List<Person>> _future;
  bool _treeView = true; // 默认族谱图，可切到列表

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _repo.getPersonsByGroup(PersonGroup.family);
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

  Future<void> _addMember() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => const PersonFormPage(group: PersonGroup.family)),
    );
    if (added == true) _reload();
  }

  /// 打开详情页，返回后刷新（详情里可能编辑/删除/调换关系）。
  Future<void> _openPerson(int personId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PersonDetailPage(personId: personId)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabFamily),
        actions: [
          const SearchButton(),
          IconButton(
            icon: Icon(_treeView ? Icons.list : Icons.account_tree_outlined),
            tooltip: _treeView ? context.l10n.viewList : context.l10n.viewTree,
            onPressed: () => setState(() => _treeView = !_treeView),
          ),
        ],
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
          return _treeView
              ? FamilyTreeChart(
                  people: people,
                  onOpen: _openPerson,
                  onSwap: _promote,
                )
              : FamilyListView(
                  people: people,
                  onOpen: _openPerson,
                  onSwap: _promote,
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
}
