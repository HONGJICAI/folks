/// 统一的人物模型。
///
/// 家族成员和圈子朋友共用这一个模型，区别只在展示方式（[group]）：
/// - [PersonGroup.family] 在「家族」Tab 以树状呈现，依赖 [fatherId]/[motherId]/[spouseId]
///   这几个结构性关系字段。
/// - [PersonGroup.circle] 在「圈子」Tab 以平面列表呈现，靠 [tags] 聚类，不建人与人的边。
///
/// 设计说明：血缘关系是固定基数的（最多一父一母一配偶），因此直接内嵌 ID，
/// 而不是单独建一张关系表 —— 树构建和「加父亲/加孩子自动反推」都更简单。
library;

// 显示用文案见 lib/l10n/l10n.dart 的本地化扩展（保持模型不依赖 Flutter / i18n）。
enum Gender { male, female, unknown }

enum PersonGroup {
  family, // 家族（树状）
  circle, // 圈子（平面 + 标签）
}

/// 出生日期精度：只知年 / 知年月 / 完整。年龄永远能算；只有 full 才进生日提醒。
enum BirthPrecision { year, yearMonth, full }

/// 按年循环的纪念日（结婚纪念日 / 相识 / 忌日…）。挂在 [Person] 上，用于年度提醒。
class Anniversary {
  const Anniversary({required this.label, required this.date});

  final String label;
  final DateTime date;

  Anniversary copyWith({String? label, DateTime? date}) =>
      Anniversary(label: label ?? this.label, date: date ?? this.date);

  /// 序列化为单串（与 person 的列表字段一起存）：`label|isoDate`。
  String encode() => '$label|${date.toIso8601String()}';

  static Anniversary? decode(String s) {
    final i = s.indexOf('|');
    if (i < 0) return null;
    final d = DateTime.tryParse(s.substring(i + 1));
    if (d == null) return null;
    return Anniversary(label: s.substring(0, i), date: d);
  }
}

class Person {
  /// copyWith 哨兵：区分"参数省略"与"显式传 null"。
  static const Object _unset = Object();

  final int id;

  /// 显示名（必填）：列表/树/搜索都用它。填你最习惯怎么叫——真名、小名、"大伯"都行。
  final String name;

  /// 真名 / 全名（选填）：正式场合或 vCard 导出用；隐私或图省事可不填。
  final String? realName;
  final Gender gender;
  final DateTime? birthDate;

  /// 出生日期精度（只知年 / 年月 / 完整）。算年龄不受影响；只有 full 进生日提醒。
  final BirthPrecision birthPrecision;

  /// 是否在生日当天提醒。出生日期始终用于算年龄；关掉它只是不进"近期提醒"。
  final bool remindBirthday;

  /// 该人的纪念日列表（每年循环），用于提醒。
  final List<Anniversary> anniversaries;

  /// 用户自定义的口头称呼，如「大表姐」「表外甥」。MVP 阶段由用户手填，
  /// P1 的称呼反向解析会基于此做半自动建议。
  final String? customAppellation;

  /// Markdown 格式的备注 / 手记 / 聊天避讳 / 喜好。
  final String? memo;

  final PersonGroup group;

  // --- 家族结构关系（仅 group == family 时有意义） ---
  final int? fatherId;
  final int? motherId;
  final int? spouseId;

  /// 是否"姻亲"（嫁娶进来的）。用于家族树里决定一对夫妻谁显示为主：
  /// 血亲（marriedIn=false）为主、姻亲为副。引导式录入时「加配偶」默认置 true。
  final bool marriedIn;

  /// 是否为"我"（自己）。全局应仅一人为 true，作为家族树的锚点（居中点）。
  final bool isSelf;

  /// 头像图片路径（本地副本 / 远程 URL），空则用首字头像。
  final String? photoPath;

  // --- 联系方式（可选，单值从简）---
  /// 注意：电话**不是唯一标识**，多个 person 可共用同一号码（如爷爷奶奶共用老人机），
  /// 导入通讯录时也不按号码去重。主键始终是 [id]。
  final String? phone;
  final String? email;

  // --- 圈子聚类（仅 group == circle 时常用） ---
  /// 复合标签，如 ['大学室友', '骑行搭子']。同一标签下的人天然表达「一个圈子」。
  final List<String> tags;

  const Person({
    required this.id,
    required this.name,
    this.realName,
    this.gender = Gender.unknown,
    this.birthDate,
    this.birthPrecision = BirthPrecision.full,
    this.remindBirthday = true,
    this.anniversaries = const [],
    this.customAppellation,
    this.memo,
    this.group = PersonGroup.family,
    this.fatherId,
    this.motherId,
    this.spouseId,
    this.marriedIn = false,
    this.isSelf = false,
    this.photoPath,
    this.phone,
    this.email,
    this.tags = const [],
  });

  /// 显示用名称：有小名时「真名(小名)」，否则真名。
  /// 显示用名称：就是 [name]。保留这个 getter 让调用方语义清晰、未来可扩展。
  String get displayName => name;

  /// 周岁。无生日时返回 null。注意：这里用注入的 [now] 以便测试，
  /// 调用方传 DateTime.now() 即可。
  int? ageAt(DateTime now) {
    final b = birthDate;
    if (b == null) return null;
    var age = now.year - b.year;
    switch (birthPrecision) {
      case BirthPrecision.year:
        break; // 只知年，不按月日修正
      case BirthPrecision.yearMonth:
        if (now.month < b.month) age--;
      case BirthPrecision.full:
        if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
          age--;
        }
    }
    return age;
  }

  /// 出生日期的精度感知显示：1992 / 1992-11 / 1992-11-05。无生日返回 null。
  String? get birthDisplay {
    final b = birthDate;
    if (b == null) return null;
    final y = b.year.toString();
    final m = b.month.toString().padLeft(2, '0');
    final d = b.day.toString().padLeft(2, '0');
    return switch (birthPrecision) {
      BirthPrecision.year => y,
      BirthPrecision.yearMonth => '$y-$m',
      BirthPrecision.full => '$y-$m-$d',
    };
  }

  /// 是否可在生日当天提醒（需要完整日期）。
  bool get canRemindBirthday =>
      birthDate != null && birthPrecision == BirthPrecision.full;

  /// 关系字段（[fatherId]/[motherId]/[spouseId]）用哨兵区分"不改"与"清空"：
  /// 省略 = 保持原值；显式传 `null` = 真正清空。普通 `?? this.x` 写法做不到后者。
  Person copyWith({
    int? id,
    String? name,
    String? realName,
    Gender? gender,
    DateTime? birthDate,
    BirthPrecision? birthPrecision,
    bool? remindBirthday,
    List<Anniversary>? anniversaries,
    String? customAppellation,
    String? memo,
    PersonGroup? group,
    Object? fatherId = _unset,
    Object? motherId = _unset,
    Object? spouseId = _unset,
    bool? marriedIn,
    bool? isSelf,
    String? photoPath,
    String? phone,
    String? email,
    List<String>? tags,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      realName: realName ?? this.realName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      birthPrecision: birthPrecision ?? this.birthPrecision,
      remindBirthday: remindBirthday ?? this.remindBirthday,
      anniversaries: anniversaries ?? this.anniversaries,
      customAppellation: customAppellation ?? this.customAppellation,
      memo: memo ?? this.memo,
      group: group ?? this.group,
      fatherId: identical(fatherId, _unset) ? this.fatherId : fatherId as int?,
      motherId: identical(motherId, _unset) ? this.motherId : motherId as int?,
      spouseId: identical(spouseId, _unset) ? this.spouseId : spouseId as int?,
      marriedIn: marriedIn ?? this.marriedIn,
      isSelf: isSelf ?? this.isSelf,
      photoPath: photoPath ?? this.photoPath,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tags: tags ?? this.tags,
    );
  }

  /// 供未来 SQLite 持久化使用。列表字段用分号拼接（与 README CSV 导出规范一致）。
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'real_name': realName,
        'gender': gender.name,
        'birth_date': birthDate?.toIso8601String(),
        'birth_precision': birthPrecision.name,
        'remind_birthday': remindBirthday ? 1 : 0,
        'anniversaries': anniversaries.map((a) => a.encode()).join(';;'),
        'custom_appellation': customAppellation,
        'memo': memo,
        'group': group.name,
        'father_id': fatherId,
        'mother_id': motherId,
        'spouse_id': spouseId,
        'married_in': marriedIn ? 1 : 0,
        'is_self': isSelf ? 1 : 0,
        'photo_path': photoPath,
        'phone': phone,
        'email': email,
        'tags': tags.join(';'),
      };

  factory Person.fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as int,
        name: m['name'] as String,
        realName: m['real_name'] as String?,
        gender: Gender.values.byName((m['gender'] as String?) ?? 'unknown'),
        birthDate: m['birth_date'] == null
            ? null
            : DateTime.parse(m['birth_date'] as String),
        birthPrecision: BirthPrecision.values
            .byName((m['birth_precision'] as String?) ?? 'full'),
        remindBirthday: (m['remind_birthday'] as int?) != 0,
        anniversaries: ((m['anniversaries'] as String?) ?? '')
            .split(';;')
            .where((s) => s.isNotEmpty)
            .map(Anniversary.decode)
            .whereType<Anniversary>()
            .toList(),
        customAppellation: m['custom_appellation'] as String?,
        memo: m['memo'] as String?,
        group: PersonGroup.values.byName((m['group'] as String?) ?? 'family'),
        fatherId: m['father_id'] as int?,
        motherId: m['mother_id'] as int?,
        spouseId: m['spouse_id'] as int?,
        marriedIn: (m['married_in'] as int?) == 1,
        isSelf: (m['is_self'] as int?) == 1,
        photoPath: m['photo_path'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        tags: ((m['tags'] as String?) ?? '')
            .split(';')
            .where((t) => t.isNotEmpty)
            .toList(),
      );
}
