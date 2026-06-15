import 'dart:math' as math;

import '../models/person.dart';

/// 家谱的一个「单元」：一对夫妻（或单人）。
///
/// 与 [buildFamilyForest] 的树不同，这里是**有向图**：一个夫妻单元可以同时挂在
/// **双方各自的父辈单元**下面（dad 的爷爷 + mom 的外公），从而支持"拆分夫妻节点"
/// 的呈现——而树结构每个节点只有一个父槽，做不到。
class FamilyUnit {
  FamilyUnit(this.primary, this.secondary);

  /// 主位（血亲优先），渲染时在左格。
  final Person primary;

  /// 副位（配偶/姻亲），单人时为 null，渲染时在右格。
  final Person? secondary;

  /// 父辈单元（0..2）：primary 的父母所在单元、secondary 的父母所在单元。
  final List<FamilyUnit> parents = [];
  final List<FamilyUnit> children = [];

  int gen = 0; // 第几代（0 = 最顶层祖辈）
  double x = 0; // 布局左上角
  double y = 0;

  bool get isCouple => secondary != null;
  bool get hasSelf => primary.isSelf || (secondary?.isSelf ?? false);

  /// 该单元是否含此人。
  bool contains(int? id) =>
      id != null && (primary.id == id || secondary?.id == id);

  /// 该父辈单元是落在 primary 一侧（true）还是 secondary 一侧（false/null）。
  /// 用于决定连线接到夫妻框的左格还是右格。
  bool? sideForParent(FamilyUnit parent) {
    if (parent.contains(primary.fatherId) || parent.contains(primary.motherId)) {
      return true;
    }
    if (secondary != null &&
        (parent.contains(secondary!.fatherId) ||
            parent.contains(secondary!.motherId))) {
      return false;
    }
    return null;
  }
}

int _genderRank(Gender g) => switch (g) {
      Gender.male => 0,
      Gender.female => 1,
      Gender.unknown => 2,
    };

/// 家族树「左右」排序：先按出生日期升序（早的在左），**无生日靠后**；
/// 再「男左女右」（未知性别再靠后）；最后按 id 稳定兜底。
/// 用于：兄弟姐妹横向次序、以及夫妻血亲状态相同时的左右 tie-break。
int compareSiblings(Person a, Person b) {
  final ba = a.birthDate;
  final bb = b.birthDate;
  if (ba != null && bb != null) {
    final c = ba.compareTo(bb);
    if (c != 0) return c;
  } else if (ba != null) {
    return -1; // 有生日的在前（左），无生日的靠后（右）
  } else if (bb != null) {
    return 1;
  }
  final r = _genderRank(a.gender) - _genderRank(b.gender);
  if (r != 0) return r; // 男左女右
  return a.id.compareTo(b.id);
}

/// 把平面成员构建成家谱「单元图」：配偶成对、按血亲定主副、双方父辈各自连边、定代。
List<FamilyUnit> buildFamilyGraph(List<Person> people) {
  final byId = {for (final p in people) p.id: p};

  List<Person> childrenOf(int id) =>
      people.where((p) => p.fatherId == id || p.motherId == id).toList();

  // 伴侣：配偶优先；否则取"共同父母"（同一孩子的另一位家长）。
  Person? partnerOf(Person p) {
    if (p.spouseId != null) return byId[p.spouseId];
    for (final c in childrenOf(p.id)) {
      final otherId = c.fatherId == p.id ? c.motherId : c.fatherId;
      if (otherId != null && byId.containsKey(otherId)) return byId[otherId];
    }
    return null;
  }

  // 1) 组单元：每人恰好属于一个单元。
  final unitOf = <int, FamilyUnit>{};
  final units = <FamilyUnit>[];
  final seen = <int>{};
  for (final p in people) {
    if (seen.contains(p.id)) continue;
    final spouse = partnerOf(p);
    seen.add(p.id);
    var primary = p;
    var secondary = spouse;
    if (spouse != null) {
      seen.add(spouse.id);
      final pBlood = !p.marriedIn;
      final sBlood = !spouse.marriedIn;
      // 血亲优先做主位(左)；血亲状态相同时，按出生→男左女右决定左右。
      final bool spouseFirst;
      if (sBlood != pBlood) {
        spouseFirst = sBlood; // 配偶是血亲、p 是姻亲 → 配偶在左
      } else {
        spouseFirst = compareSiblings(spouse, p) < 0;
      }
      if (spouseFirst) {
        primary = spouse;
        secondary = p;
      }
    }
    final u = FamilyUnit(primary, secondary);
    units.add(u);
    unitOf[primary.id] = u;
    if (secondary != null) unitOf[secondary.id] = u;
  }

  // 2) 连父子边（双方父母各自的单元都算父辈，去重）。
  void linkParent(FamilyUnit child, int? parentId) {
    if (parentId == null) return;
    final pu = unitOf[parentId];
    if (pu == null || identical(pu, child)) return;
    if (!child.parents.contains(pu)) child.parents.add(pu);
    if (!pu.children.contains(child)) pu.children.add(child);
  }

  for (final u in units) {
    linkParent(u, u.primary.fatherId);
    linkParent(u, u.primary.motherId);
    if (u.secondary != null) {
      linkParent(u, u.secondary!.fatherId);
      linkParent(u, u.secondary!.motherId);
    }
  }

  // 3) 定代：gen = 无父辈则 0，否则 max(父辈) + 1（含环兜底）。
  final memo = <FamilyUnit, int>{};
  final inProgress = <FamilyUnit>{};
  int genOf(FamilyUnit u) {
    final cached = memo[u];
    if (cached != null) return cached;
    if (u.parents.isEmpty || inProgress.contains(u)) return memo[u] = 0;
    inProgress.add(u);
    var g = 0;
    for (final pa in u.parents) {
      g = math.max(g, genOf(pa) + 1);
    }
    inProgress.remove(u);
    return memo[u] = g;
  }

  for (final u in units) {
    u.gen = genOf(u);
  }

  // 兄弟姐妹按"出生→男左女右"排序（比较各单元的主位＝血亲那一方）。
  for (final u in units) {
    u.children.sort((x, y) => compareSiblings(x.primary, y.primary));
  }
  return units;
}

/// 分层布局：按代分行，行内 x 用"父子重心 + 去重叠"迭代松弛。纯函数，写入各单元的 x/y。
void layoutFamilyGraph(
  List<FamilyUnit> units, {
  required double Function(FamilyUnit u) widthOf,
  required double rowHeight,
  required double nodeHeight,
  required double hGap,
  int iterations = 14,
}) {
  if (units.isEmpty) return;

  double centerOf(FamilyUnit u) => u.x + widthOf(u) / 2;
  void setCenter(FamilyUnit u, double c) => u.x = c - widthOf(u) / 2;

  // 按代分组。
  final maxGen = units.map((u) => u.gen).reduce(math.max);
  final rows = List.generate(maxGen + 1, (_) => <FamilyUnit>[]);
  for (final u in units) {
    u.y = u.gen * rowHeight;
    rows[u.gen].add(u);
  }

  // 初始排序：从顶层 DFS，按已排好序的子代聚拢，减少交叉。
  // 顶层根也按"出生→男左女右"排序，让最年长一支在左。
  final order = <FamilyUnit, int>{};
  var counter = 0;
  void dfs(FamilyUnit u) {
    if (order.containsKey(u)) return;
    order[u] = counter++;
    for (final c in u.children) {
      dfs(c);
    }
  }

  final roots = units.where((u) => u.parents.isEmpty).toList()
    ..sort((a, b) => compareSiblings(a.primary, b.primary));
  for (final r in roots) {
    dfs(r);
  }
  for (final u in units) {
    dfs(u); // 兜底：环/孤立
  }
  for (final row in rows) {
    row.sort((a, b) => order[a]!.compareTo(order[b]!));
  }

  // 初始 x：行内顺序铺开。
  for (final row in rows) {
    var cx = 0.0;
    for (final u in row) {
      u.x = cx;
      cx += widthOf(u) + hGap;
    }
  }

  double avgCenter(List<FamilyUnit> related) =>
      related.map(centerOf).reduce((a, b) => a + b) / related.length;

  // 按「目标中心」排布一行：先按目标排序、向右消重叠得到一组合法间距，
  // 再整行平移使「实际 - 目标」的平均位移为 0 —— 即围绕重心对称摆放，
  // 而不是一味左靠。这样两侧祖辈会均匀分布在夫妻两边，连线不再单侧funnel。
  void packRow(List<FamilyUnit> row, double Function(FamilyUnit) target) {
    if (row.isEmpty) return;
    // 目标重心相同（同胞共享父辈重心）时，用预排序 order 兜底，保住"出生→男左女右"次序。
    final sorted = [...row]..sort((a, b) {
        final t = target(a).compareTo(target(b));
        return t != 0 ? t : order[a]!.compareTo(order[b]!);
      });
    final centers = <double>[];
    for (var i = 0; i < sorted.length; i++) {
      var c = target(sorted[i]);
      if (i > 0) {
        final minC = centers[i - 1] +
            widthOf(sorted[i - 1]) / 2 +
            hGap +
            widthOf(sorted[i]) / 2;
        if (c < minC) c = minC;
      }
      centers.add(c);
    }
    var shift = 0.0;
    for (var i = 0; i < sorted.length; i++) {
      shift += target(sorted[i]) - centers[i];
    }
    shift /= sorted.length;
    for (var i = 0; i < sorted.length; i++) {
      setCenter(sorted[i], centers[i] + shift);
    }
  }

  void downPass() {
    for (var g = 1; g <= maxGen; g++) {
      packRow(rows[g],
          (u) => u.parents.isNotEmpty ? avgCenter(u.parents) : centerOf(u));
    }
  }

  void upPass() {
    for (var g = maxGen - 1; g >= 0; g--) {
      packRow(rows[g],
          (u) => u.children.isNotEmpty ? avgCenter(u.children) : centerOf(u));
    }
  }

  // 松弛：向下（按父辈重心）与向上（按子代重心）交替收敛。
  for (var it = 0; it < iterations; it++) {
    downPass();
    upPass();
  }
  // 收尾必须以向下结束：让每对夫妻落到「双方父辈的中点」正下方、子代落到夫妻正下方，
  // 否则会停在某一侧父辈下面、另一侧祖辈的连线横跨过来缠在一起。
  downPass();

  // 归零左边界。
  final minX = units.map((u) => u.x).reduce(math.min);
  if (minX != 0) {
    for (final u in units) {
      u.x -= minX;
    }
  }
}
