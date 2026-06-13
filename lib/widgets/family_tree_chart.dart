import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/person.dart';
import 'avatar.dart';

// 节点与间距尺寸。
const double _nodeW = 158;
const double _nodeH = 72;
const double _hGap = 20;
const double _vGap = 52;

/// 一个族谱节点：一对夫妻（或单人）+ 其子女节点。
class _Node {
  _Node(this.primary, this.secondary, this.children);
  final Person primary;
  final Person? secondary; // 配偶（姻亲）
  final List<_Node> children;
  double x = 0;
  double y = 0;

  double get centerX => x + _nodeW / 2;
}

/// 横向家谱图：子树居中布局，父子用折线连接，整体可平移/缩放，首帧自动适配居中。
class FamilyTreeChart extends StatefulWidget {
  const FamilyTreeChart({
    super.key,
    required this.people,
    required this.onOpen,
    required this.onSwap,
  });

  final List<Person> people;
  final void Function(int personId) onOpen; // 点节点进详情
  final void Function(int secondaryId) onSwap; // 长按把副位提升为主位

  @override
  State<FamilyTreeChart> createState() => _FamilyTreeChartState();
}

class _FamilyTreeChartState extends State<FamilyTreeChart> {
  final TransformationController _tc = TransformationController();
  bool _fitted = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roots = _buildForest(widget.people);

    // 布局：叶子从左到右铺开，父节点居中于其子女跨度之上。
    var cursor = 0.0;
    var maxDepth = 0;
    void layout(_Node n, int depth) {
      if (depth > maxDepth) maxDepth = depth;
      n.y = depth * (_nodeH + _vGap);
      if (n.children.isEmpty) {
        n.x = cursor;
        cursor += _nodeW + _hGap;
      } else {
        for (final c in n.children) {
          layout(c, depth + 1);
        }
        n.x = (n.children.first.centerX + n.children.last.centerX) / 2 -
            _nodeW / 2;
      }
    }

    for (final r in roots) {
      layout(r, 0);
    }

    final all = <_Node>[];
    void collect(_Node n) {
      all.add(n);
      n.children.forEach(collect);
    }

    roots.forEach(collect);

    final width = (cursor - _hGap).clamp(_nodeW, double.infinity);
    final height = (maxDepth + 1) * _nodeH + maxDepth * _vGap;
    final scheme = Theme.of(context).colorScheme;

    // 水平锚点：以"我"所在节点的中心为中点（找不到则用整棵树中点）。
    final selfNode = all.cast<_Node?>().firstWhere(
          (n) => n!.primary.isSelf || (n.secondary?.isSelf ?? false),
          orElse: () => null,
        );
    final anchorX = selfNode?.centerX ?? width / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        _fitOnce(constraints.biggest, width, height, anchorX);
        return InteractiveViewer(
          transformationController: _tc,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(240),
          minScale: 0.3,
          maxScale: 2.5,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(width, height),
                  painter: _ConnectorPainter(all, scheme.outlineVariant),
                ),
                for (final n in all)
                  Positioned(
                    left: n.x,
                    top: n.y,
                    child: _NodeBox(
                      node: n,
                      onOpen: () => widget.onOpen(n.primary.id),
                      onSwap: n.secondary == null
                          ? null
                          : () => widget.onSwap(n.secondary!.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 首帧：缩放到不超过 1×、能整体放下；水平以 [anchorX]（"我"）为中点、垂直整体居中。
  /// 之后保留用户的平移/缩放。
  void _fitOnce(Size viewport, double w, double h, double anchorX) {
    if (_fitted || viewport.isEmpty || w <= 0 || h <= 0) return;
    _fitted = true;
    final scale =
        math.min(1.0, math.min(viewport.width / w, viewport.height / h));
    final tx = viewport.width / 2 - anchorX * scale; // 把"我"放到视口水平中央
    final ty = (viewport.height - h * scale) / 2;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tc.value = Matrix4.identity()
        ..translateByDouble(tx, ty, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    });
  }

  /// 把平面成员还原成节点森林，配偶成对、子女去重，并按"血亲为主"定主副。
  List<_Node> _buildForest(List<Person> people) {
    final byId = {for (final p in people) p.id: p};
    List<Person> childrenOf(int id) =>
        people.where((p) => p.fatherId == id || p.motherId == id).toList();
    bool hasParentInSet(Person p) =>
        (p.fatherId != null && byId.containsKey(p.fatherId)) ||
        (p.motherId != null && byId.containsKey(p.motherId));

    final visited = <int>{};

    _Node build(Person p) {
      visited.add(p.id);
      final spouse = p.spouseId != null ? byId[p.spouseId] : null;
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
      final childNodes = [for (final k in kids.values) build(k)];
      return _Node(primary, secondary, childNodes);
    }

    final roots = <_Node>[];
    for (final r in people.where((p) => !hasParentInSet(p))) {
      if (!visited.contains(r.id)) roots.add(build(r));
    }
    for (final p in people) {
      if (!visited.contains(p.id)) roots.add(build(p));
    }
    return roots;
  }
}

class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.nodes, this.color);
  final List<_Node> nodes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final n in nodes) {
      if (n.children.isEmpty) continue;
      final parentBottom = Offset(n.centerX, n.y + _nodeH);
      final midY = n.y + _nodeH + _vGap / 2;

      // 父节点向下的竖线
      canvas.drawLine(parentBottom, Offset(n.centerX, midY), paint);

      // 横向母线（覆盖所有子女中心）
      final firstCx = n.children.first.centerX;
      final lastCx = n.children.last.centerX;
      canvas.drawLine(Offset(firstCx, midY), Offset(lastCx, midY), paint);

      // 每个子女向上的竖线
      for (final c in n.children) {
        canvas.drawLine(
            Offset(c.centerX, midY), Offset(c.centerX, c.y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.nodes != nodes || old.color != color;
}

class _NodeBox extends StatelessWidget {
  const _NodeBox({required this.node, required this.onOpen, this.onSwap});

  final _Node node;
  final VoidCallback onOpen;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = node.primary;
    final age = p.ageAt(DateTime.now());
    final meta = [
      if (p.customAppellation != null) p.customAppellation!,
      if (age != null) context.l10n.ageYears(age),
    ].join(' · ');

    return SizedBox(
      width: _nodeW,
      height: _nodeH,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          onLongPress: onSwap, // 长按对调主副
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Avatar(name: p.realName, radius: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      if (node.secondary != null)
                        Row(
                          children: [
                            Icon(Icons.favorite, size: 10, color: scheme.primary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(node.secondary!.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: scheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      if (meta.isNotEmpty)
                        Text(meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
