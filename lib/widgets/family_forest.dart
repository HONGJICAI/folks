import '../models/person.dart';

/// 一对夫妻（或单人）+ 其子女，构成族谱的一个节点。
/// 纯数据结构，不依赖 Flutter —— 供「家族树图」与「列表视图」共用，且可单测。
class FamilyForestNode {
  FamilyForestNode(this.primary, this.secondary, this.children);

  /// 主位（血亲优先）。
  final Person primary;

  /// 副位（配偶 / 姻亲），单人时为 null。
  final Person? secondary;
  final List<FamilyForestNode> children;
}

/// 把平面成员还原成节点森林：配偶成对、子女去重、按"血亲为主"定主副。
///
/// 关键规则：**一对夫妻是一个整体**。只要夫妻任一方在集合里有父母，这对就不是
/// 顶层根 —— 应挂到祖辈下面展开，而不是各自成根。否则"父亲有爹、母亲没爹"时，
/// 母亲会被当成根、抢先把整支建掉，真正的祖父反而落单（见回归测试）。
List<FamilyForestNode> buildFamilyForest(List<Person> people) {
  final byId = {for (final p in people) p.id: p};

  List<Person> childrenOf(int id) =>
      people.where((p) => p.fatherId == id || p.motherId == id).toList();

  bool hasParentInSet(Person p) =>
      (p.fatherId != null && byId.containsKey(p.fatherId)) ||
      (p.motherId != null && byId.containsKey(p.motherId));

  // 伴侣：配偶优先；否则取"共同父母"（同一孩子的另一位家长），
  // 这样未登记为配偶的爷爷+奶奶也成对，不会各自落单。
  Person? partnerOf(Person p) {
    if (p.spouseId != null) return byId[p.spouseId];
    for (final c in childrenOf(p.id)) {
      final otherId = c.fatherId == p.id ? c.motherId : c.fatherId;
      if (otherId != null && byId.containsKey(otherId)) return byId[otherId];
    }
    return null;
  }

  // 夫妻视为一个单元：任一方有父母在集合里，这对就不是顶层根。
  bool coupleHasParentInSet(Person p) {
    if (hasParentInSet(p)) return true;
    final partner = partnerOf(p);
    return partner != null && hasParentInSet(partner);
  }

  final visited = <int>{};

  FamilyForestNode build(Person p) {
    visited.add(p.id);
    final spouse = partnerOf(p);
    if (spouse != null) visited.add(spouse.id);

    // 血亲为主、姻亲为副；同为血亲时按 id 稳定兜底。
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

    final kids = <int, Person>{};
    for (final k in childrenOf(p.id)) {
      kids[k.id] = k;
    }
    if (spouse != null) {
      for (final k in childrenOf(spouse.id)) {
        kids[k.id] = k;
      }
    }
    // 防重：已在别处出现过的子节点不再展开。
    final children = [
      for (final k in kids.values)
        if (!visited.contains(k.id)) build(k),
    ];
    return FamilyForestNode(primary, secondary, children);
  }

  final roots = <FamilyForestNode>[];
  for (final r in people.where((p) => !coupleHasParentInSet(p))) {
    if (!visited.contains(r.id)) roots.add(build(r));
  }
  // 兜底：环或孤立数据，避免漏画。
  for (final p in people) {
    if (!visited.contains(p.id)) roots.add(build(p));
  }
  return roots;
}
