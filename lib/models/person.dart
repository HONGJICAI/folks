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

enum Gender {
  male,
  female,
  unknown;

  String get label => switch (this) {
        Gender.male => '男',
        Gender.female => '女',
        Gender.unknown => '未知',
      };
}

enum PersonGroup {
  family, // 家族（树状）
  circle; // 圈子（平面 + 标签）

  String get label => switch (this) {
        PersonGroup.family => '家族',
        PersonGroup.circle => '圈子',
      };
}

class Person {
  /// copyWith 哨兵：区分"参数省略"与"显式传 null"。
  static const Object _unset = Object();

  final int id;
  final String realName;

  /// 小名 / 乳名，如「狗蛋」。
  final String? nickname;
  final Gender gender;
  final DateTime? birthDate;

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
    required this.realName,
    this.nickname,
    this.gender = Gender.unknown,
    this.birthDate,
    this.customAppellation,
    this.memo,
    this.group = PersonGroup.family,
    this.fatherId,
    this.motherId,
    this.spouseId,
    this.marriedIn = false,
    this.phone,
    this.email,
    this.tags = const [],
  });

  /// 显示用名称：有小名时「真名(小名)」，否则真名。
  String get displayName =>
      nickname == null || nickname!.isEmpty ? realName : '$realName($nickname)';

  /// 周岁。无生日时返回 null。注意：这里用注入的 [now] 以便测试，
  /// 调用方传 DateTime.now() 即可。
  int? ageAt(DateTime now) {
    final b = birthDate;
    if (b == null) return null;
    var age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  /// 关系字段（[fatherId]/[motherId]/[spouseId]）用哨兵区分"不改"与"清空"：
  /// 省略 = 保持原值；显式传 `null` = 真正清空。普通 `?? this.x` 写法做不到后者。
  Person copyWith({
    int? id,
    String? realName,
    String? nickname,
    Gender? gender,
    DateTime? birthDate,
    String? customAppellation,
    String? memo,
    PersonGroup? group,
    Object? fatherId = _unset,
    Object? motherId = _unset,
    Object? spouseId = _unset,
    bool? marriedIn,
    String? phone,
    String? email,
    List<String>? tags,
  }) {
    return Person(
      id: id ?? this.id,
      realName: realName ?? this.realName,
      nickname: nickname ?? this.nickname,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      customAppellation: customAppellation ?? this.customAppellation,
      memo: memo ?? this.memo,
      group: group ?? this.group,
      fatherId: identical(fatherId, _unset) ? this.fatherId : fatherId as int?,
      motherId: identical(motherId, _unset) ? this.motherId : motherId as int?,
      spouseId: identical(spouseId, _unset) ? this.spouseId : spouseId as int?,
      marriedIn: marriedIn ?? this.marriedIn,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      tags: tags ?? this.tags,
    );
  }

  /// 供未来 SQLite 持久化使用。列表字段用分号拼接（与 README CSV 导出规范一致）。
  Map<String, Object?> toMap() => {
        'id': id,
        'real_name': realName,
        'nickname': nickname,
        'gender': gender.name,
        'birth_date': birthDate?.toIso8601String(),
        'custom_appellation': customAppellation,
        'memo': memo,
        'group': group.name,
        'father_id': fatherId,
        'mother_id': motherId,
        'spouse_id': spouseId,
        'married_in': marriedIn ? 1 : 0,
        'phone': phone,
        'email': email,
        'tags': tags.join(';'),
      };

  factory Person.fromMap(Map<String, Object?> m) => Person(
        id: m['id'] as int,
        realName: m['real_name'] as String,
        nickname: m['nickname'] as String?,
        gender: Gender.values.byName((m['gender'] as String?) ?? 'unknown'),
        birthDate: m['birth_date'] == null
            ? null
            : DateTime.parse(m['birth_date'] as String),
        customAppellation: m['custom_appellation'] as String?,
        memo: m['memo'] as String?,
        group: PersonGroup.values.byName((m['group'] as String?) ?? 'family'),
        fatherId: m['father_id'] as int?,
        motherId: m['mother_id'] as int?,
        spouseId: m['spouse_id'] as int?,
        marriedIn: (m['married_in'] as int?) == 1,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        tags: ((m['tags'] as String?) ?? '')
            .split(';')
            .where((t) => t.isNotEmpty)
            .toList(),
      );
}
