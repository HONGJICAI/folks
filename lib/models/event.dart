/// 回忆 / 人情往来事件 —— 「回忆」Tab（人情时光机）的核心模型。
///
/// 一条事件可同时绑定多个人（[boundPersonIds]），会自动分发渲染到每个人的时光轴。
library;

// 文字 label 见 lib/l10n/l10n.dart 的本地化扩展；emoji 不本地化，留在模型里。
enum EventType {
  material, // 💰 物质往来（金钱 / 人情账本）
  experience, // 🚗 共同经历（陪伴记录）
  milestone; // 🎯 重要里程碑（关注事件）

  String get emoji => switch (this) {
        EventType.material => '💰',
        EventType.experience => '🚗',
        EventType.milestone => '🎯',
      };
}

/// 资金流向。仅 [EventType.material] 有意义；其余类型为 null（无金钱交互）。
enum MoneyDirection { income, expense }

class Event {
  final int id;
  final EventType type;
  final String title;

  /// 深度手记，如「这次聚餐表姐夫请吃了大餐」。
  final String? detail;
  final DateTime occurDate;

  /// 绑定的人物 ID 列表（多人绑定）。
  final List<int> boundPersonIds;

  /// 本地照片副本的路径（已复制进 App 私有目录，而非相册 URI 引用）。
  final List<String> photoPaths;

  // --- 仅 type == material 时有意义 ---
  final MoneyDirection? direction;
  final double? amount;

  const Event({
    required this.id,
    required this.type,
    required this.title,
    this.detail,
    required this.occurDate,
    this.boundPersonIds = const [],
    this.photoPaths = const [],
    this.direction,
    this.amount,
  });

  bool get isMoney => type == EventType.material;

  /// 带符号的金额：支出为负、收入为正。非金钱事件返回 0。
  double get signedAmount {
    if (!isMoney || amount == null || direction == null) return 0;
    return direction == MoneyDirection.expense ? -amount! : amount!;
  }

  Event copyWith({
    int? id,
    EventType? type,
    String? title,
    String? detail,
    DateTime? occurDate,
    List<int>? boundPersonIds,
    List<String>? photoPaths,
    MoneyDirection? direction,
    double? amount,
  }) {
    return Event(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      occurDate: occurDate ?? this.occurDate,
      boundPersonIds: boundPersonIds ?? this.boundPersonIds,
      photoPaths: photoPaths ?? this.photoPaths,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'detail': detail,
        'occur_date': occurDate.toIso8601String(),
        'bound_person_ids': boundPersonIds.join(','),
        'photo_paths': photoPaths.join(';'),
        'direction': direction?.name,
        'amount': amount,
      };

  factory Event.fromMap(Map<String, Object?> m) => Event(
        id: m['id'] as int,
        type: EventType.values.byName(m['type'] as String),
        title: m['title'] as String,
        detail: m['detail'] as String?,
        occurDate: DateTime.parse(m['occur_date'] as String),
        boundPersonIds: ((m['bound_person_ids'] as String?) ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .map(int.parse)
            .toList(),
        photoPaths: ((m['photo_paths'] as String?) ?? '')
            .split(';')
            .where((s) => s.isNotEmpty)
            .toList(),
        direction: m['direction'] == null
            ? null
            : MoneyDirection.values.byName(m['direction'] as String),
        amount: (m['amount'] as num?)?.toDouble(),
      );
}
