import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/person.dart';
import 'avatar.dart';
import 'family_graph.dart';

// 节点与间距尺寸。
const double _nodeW = 150; // 单人节点宽
const double _coupleW = 250; // 夫妻节点更宽（左右两人并排）
const double _nodeH = 64;
const double _hGap = 20;
const double _vGap = 52;

double _widthOf(FamilyUnit u) => u.isCouple ? _coupleW : _nodeW;
double _centerX(FamilyUnit u) => u.x + _widthOf(u) / 2;

/// 横向家谱图：分层有向图布局，支持夫妻双方各自挂到不同祖辈下（拆分夫妻节点）。
/// 整体可平移/缩放，首帧自动适配并以"我"为水平中点。
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
    final units = buildFamilyGraph(widget.people);
    layoutFamilyGraph(
      units,
      widthOf: _widthOf,
      rowHeight: _nodeH + _vGap,
      nodeHeight: _nodeH,
      hGap: _hGap,
    );

    final width = units.isEmpty
        ? _nodeW
        : units.map((u) => u.x + _widthOf(u)).reduce(math.max);
    final maxGen = units.isEmpty
        ? 0
        : units.map((u) => u.gen).reduce(math.max);
    final height = maxGen * (_nodeH + _vGap) + _nodeH;
    final scheme = Theme.of(context).colorScheme;

    // 水平锚点：以"我"所在单元的中心为中点（找不到则用整体中点）。
    final selfUnit = units.cast<FamilyUnit?>().firstWhere(
          (u) => u!.hasSelf,
          orElse: () => null,
        );
    final anchorX = selfUnit != null ? _centerX(selfUnit) : width / 2;

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
                  painter: _ConnectorPainter(units, scheme.outlineVariant),
                ),
                for (final u in units)
                  Positioned(
                    left: u.x,
                    top: u.y,
                    child: _UnitBox(
                      unit: u,
                      onOpenPerson: widget.onOpen,
                      onSwap: u.secondary == null
                          ? null
                          : () => widget.onSwap(u.secondary!.id),
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
}

/// 父→子折线连接。夫妻有双方祖辈时，两条线分别接到左格(primary)/右格(secondary)。
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter(this.units, this.color);
  final List<FamilyUnit> units;
  final Color color;

  // 夫妻框左右格中心的近似比例（左格 ~1/4 处、右格 ~3/4 处）。
  double _childAnchorX(FamilyUnit u, FamilyUnit parent) {
    if (!u.isCouple || u.parents.length == 1) return _centerX(u);
    final side = u.sideForParent(parent);
    if (side == true) return u.x + _widthOf(u) * 0.25;
    if (side == false) return u.x + _widthOf(u) * 0.75;
    return _centerX(u);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final u in units) {
      for (final pa in u.parents) {
        final px = _centerX(pa);
        final py = pa.y + _nodeH; // 父辈底部
        final cx = _childAnchorX(u, pa);
        final cy = u.y; // 子代顶部
        final midY = cy - _vGap / 2;
        canvas.drawLine(Offset(px, py), Offset(px, midY), paint);
        canvas.drawLine(Offset(px, midY), Offset(cx, midY), paint);
        canvas.drawLine(Offset(cx, midY), Offset(cx, cy), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.units != units || old.color != color;
}

class _UnitBox extends StatelessWidget {
  const _UnitBox(
      {required this.unit, required this.onOpenPerson, this.onSwap});

  final FamilyUnit unit;
  final void Function(int personId) onOpenPerson; // 点哪个名字进哪个详情
  final VoidCallback? onSwap; // 长按对调主副

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelf = unit.hasSelf;
    final couple = unit.secondary != null;

    return SizedBox(
      width: _widthOf(unit),
      height: _nodeH,
      child: Material(
        color: isSelf ? scheme.primaryContainer : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelf ? scheme.primary : scheme.outlineVariant,
            width: isSelf ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: couple
            ? Row(
                children: [
                  Expanded(child: _cell(context, unit.primary, spouse: false)),
                  Icon(Icons.favorite, size: 13, color: scheme.primary),
                  Expanded(
                      child: _cell(context, unit.secondary!, spouse: true)),
                ],
              )
            : _cell(context, unit.primary, spouse: false, single: true),
      ),
    );
  }

  /// 一个可点的人格（点进详情、长按对调）。夫妻左右各一格，单人独占整格并显示称呼/年龄。
  Widget _cell(BuildContext context, Person p,
      {required bool spouse, bool single = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final age = p.ageAt(DateTime.now());
    final meta = single
        ? [
            if (p.customAppellation != null) p.customAppellation!,
            if (age != null) context.l10n.ageYears(age),
          ].join(' · ')
        : '';

    return InkWell(
      onTap: () => onOpenPerson(p.id),
      onLongPress: onSwap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Avatar(
                name: p.name,
                photoPath: p.photoPath,
                radius: single ? 14 : 12),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              spouse ? FontWeight.w400 : FontWeight.w600,
                          color: spouse ? scheme.onSurfaceVariant : null)),
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
    );
  }
}
