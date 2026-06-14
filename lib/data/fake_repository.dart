/// 内存版假数据实现 —— 给 UI 先行开发用。
///
/// 数据写死在内存里，App 重启即重置；不依赖 SQLite / 任何 IO。
/// 替换为真实数据库时，只需另写一个 implements [FolksRepository] 的类。
library;

import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/event.dart';
import '../models/person.dart';
import 'repository.dart';

/// 暴露 notifyListeners 的小通知器（ChangeNotifier 的该方法是 protected）。
class _ChangeBus extends ChangeNotifier {
  void ping() => notifyListeners();
}

class FakeRepository implements FolksRepository {
  FakeRepository() {
    _seed();
  }

  final _ChangeBus _bus = _ChangeBus();
  final Map<int, Person> _persons = {};
  final Map<int, Event> _events = {};
  int _personSeq = 0;
  int _eventSeq = 0;

  @override
  Listenable get changes => _bus;

  int get _nextPersonId => ++_personSeq;
  int get _nextEventId => ++_eventSeq;

  // ---- 样例数据：一个有树结构的家族 + 几个圈子朋友 + 回忆/账目 ----
  void _seed() {
    // 家族：我 - 父母 - 大表姐(姑姑的女儿) - 表侄
    final me = _put(Person(
      id: _nextPersonId,
      realName: '我',
      gender: Gender.male,
      birthDate: DateTime(1995, 6, 1),
      group: PersonGroup.family,
      isSelf: true, // 锚点：家族树以"我"为水平中点
    ));
    final dad = _put(Person(
      id: _nextPersonId,
      realName: '张建国',
      nickname: '老爸',
      gender: Gender.male,
      birthDate: DateTime(1968),
      birthPrecision: BirthPrecision.year, // 只知年份：算年龄、不进生日提醒
      customAppellation: '爸爸',
      group: PersonGroup.family,
      phone: '13800138000', // 与妈妈共用一台老人机：同号可重复，不去重
    ));
    final mom = _put(Person(
      id: _nextPersonId,
      realName: '李秀兰',
      gender: Gender.female,
      birthDate: DateTime(1970, 9, 20),
      customAppellation: '妈妈',
      group: PersonGroup.family,
      phone: '13800138000', // 同上：和爸爸同一个号
    ));
    _persons[me.id] = me.copyWith(fatherId: dad.id, motherId: mom.id);
    _link(dad.id, mom.id); // 父母互为配偶

    // 结婚纪念日设为"约十天后"（相对当前日期，保证「近期提醒」能演示纪念日）。
    final wed = DateTime.now().add(const Duration(days: 10));
    final cousin = _put(Person(
      id: _nextPersonId,
      realName: '王丽',
      gender: Gender.female,
      birthDate: DateTime(1992, 11, 5),
      customAppellation: '大表姐',
      group: PersonGroup.family,
      photoPath: 'https://picsum.photos/seed/folks-wangli/200/200',
      anniversaries: [
        Anniversary(label: '结婚纪念日', date: DateTime(2021, wed.month, wed.day)),
      ],
    ));
    final cousinHusband = _put(Person(
      id: _nextPersonId,
      realName: '赵强',
      gender: Gender.male,
      birthDate: DateTime(1990, 1, 8),
      customAppellation: '表姐夫',
      group: PersonGroup.family,
      marriedIn: true, // 姻亲（嫁娶进来的）：大表姐才是血亲，故表姐夫为副位
    ));
    _link(cousin.id, cousinHusband.id);

    final grandNephew = _put(Person(
      id: _nextPersonId,
      realName: '赵狗蛋',
      nickname: '狗蛋',
      gender: Gender.male,
      birthDate: DateTime(2018, 4, 18),
      customAppellation: '表侄',
      group: PersonGroup.family,
      fatherId: cousinHusband.id,
      motherId: cousin.id,
    ));

    // 圈子：朋友（平面 + 标签）
    _put(Person(
      id: _nextPersonId,
      realName: '陈晓明',
      nickname: '老陈',
      gender: Gender.male,
      birthDate: DateTime(1995, 2, 14),
      group: PersonGroup.circle,
      phone: '13912345678',
      email: 'laochen@example.com',
      photoPath: 'https://picsum.photos/seed/folks-laochen/200/200',
      tags: ['大学室友', '骑行搭子'],
    ));
    // 生日设为"约一周后"（相对当前日期，保证「近期生日」区始终有可演示项）。
    final soon = DateTime.now().add(const Duration(days: 6));
    _put(Person(
      id: _nextPersonId,
      realName: '林婷',
      gender: Gender.female,
      birthDate: DateTime(1996, soon.month, soon.day),
      group: PersonGroup.circle,
      tags: ['前公司同事'],
    ));

    // 回忆 / 人情往来：与大表姐(id=cousin.id)的金钱往来 + 一次共同经历
    _put2(Event(
      id: _nextEventId,
      type: EventType.material,
      title: '大表姐结婚随礼',
      occurDate: DateTime(2021, 10, 2),
      direction: MoneyDirection.expense,
      amount: 5000,
      boundPersonIds: [cousin.id, cousinHusband.id],
      detail: '婚礼在老家办的，随了 5000。',
      tags: const ['婚礼'],
      photoPaths: ['https://picsum.photos/seed/folks-wedding/400/400'],
    ));
    _put2(Event(
      id: _nextEventId,
      type: EventType.material,
      title: '我生日表姐回礼',
      occurDate: DateTime(2022, 6, 1),
      direction: MoneyDirection.income,
      amount: 3000,
      boundPersonIds: [cousin.id],
    ));
    _put2(Event(
      id: _nextEventId,
      type: EventType.experience,
      title: '两家自驾去迪士尼',
      occurDate: DateTime(2023, 5, 1),
      boundPersonIds: [cousin.id, cousinHusband.id],
      detail: '小辈狗蛋很喜欢，玩了一整天。',
      tags: const ['旅行', '迪士尼'],
      photoPaths: const [
        'https://picsum.photos/seed/folks-trip1/400/400',
        'https://picsum.photos/seed/folks-trip2/400/400',
        'https://picsum.photos/seed/folks-trip3/400/400',
      ],
    ));
    _put2(Event(
      id: _nextEventId,
      type: EventType.milestone,
      title: '狗蛋今天上小学',
      occurDate: DateTime(2024, 9, 1),
      boundPersonIds: [grandNephew.id], // 绑到狗蛋
    ));
    // 实物礼物（物质往来但不填金额）：只记送/收，不计入金钱差额。
    _put2(Event(
      id: _nextEventId,
      type: EventType.material,
      title: '给狗蛋买的乐高',
      occurDate: DateTime(2023, 4, 18),
      direction: MoneyDirection.expense,
      boundPersonIds: [grandNephew.id],
      detail: '生日礼物，他很喜欢。',
      tags: const ['生日'],
    ));
    _put2(Event(
      id: _nextEventId,
      type: EventType.material,
      title: '表姐回赠的土特产',
      occurDate: DateTime(2023, 2, 10),
      direction: MoneyDirection.income,
      boundPersonIds: [cousin.id],
    ));
  }

  Person _put(Person p) {
    _persons[p.id] = p;
    return p;
  }

  Event _put2(Event e) {
    _events[e.id] = e;
    return e;
  }

  // ============ 人物 ============

  @override
  Future<List<Person>> getAllPersons() async => _persons.values.toList();

  @override
  Future<Person?> getPerson(int id) async => _persons[id];

  @override
  Future<List<Person>> getPersonsByGroup(PersonGroup group) async =>
      _persons.values.where((p) => p.group == group).toList();

  @override
  Future<List<Person>> searchPersons(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAllPersons();
    return _persons.values.where((p) {
      return p.realName.toLowerCase().contains(q) ||
          (p.nickname?.toLowerCase().contains(q) ?? false) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Future<Person> addPerson(Person person) async {
    final created = person.copyWith(id: _nextPersonId);
    _persons[created.id] = created;
    _bus.ping();
    return created;
  }

  @override
  Future<void> updatePerson(Person person) async {
    _persons[person.id] = person;
    _bus.ping();
  }

  @override
  Future<void> deletePerson(int id) async {
    if (_persons[id]?.isSelf ?? false) return; // "我"是固定成员，不可删除
    _persons.remove(id);
    // 清理引用：子女的父母指向、配偶指向。
    for (final p in _persons.values.toList()) {
      _persons[p.id] = p.copyWith(
        fatherId: p.fatherId == id ? null : p.fatherId,
        motherId: p.motherId == id ? null : p.motherId,
        spouseId: p.spouseId == id ? null : p.spouseId,
      );
    }
    // 从事件绑定中移除（按设计：解绑，不删除 event —— 留住共同回忆）。
    for (final e in _events.values.toList()) {
      if (e.boundPersonIds.contains(id)) {
        _events[e.id] = e.copyWith(
          boundPersonIds: e.boundPersonIds.where((x) => x != id).toList(),
        );
      }
    }
    _bus.ping();
  }

  // ============ 家族 ============

  @override
  Future<List<Person>> getChildren(int parentId) async => _persons.values
      .where((p) => p.fatherId == parentId || p.motherId == parentId)
      .toList();

  @override
  Future<Person> addFather(int childId, Person father) async {
    final created = await addPerson(father.copyWith(group: PersonGroup.family));
    final child = _persons[childId];
    if (child != null) {
      _persons[childId] = child.copyWith(fatherId: created.id);
    }
    _bus.ping();
    return created;
  }

  @override
  Future<Person> addMother(int childId, Person mother) async {
    final created = await addPerson(mother.copyWith(group: PersonGroup.family));
    final child = _persons[childId];
    if (child != null) {
      _persons[childId] = child.copyWith(motherId: created.id);
    }
    _bus.ping();
    return created;
  }

  @override
  Future<Person> addChild(int parentId, Person child,
      {bool throughFather = true}) async {
    final created = await addPerson(child.copyWith(
      group: PersonGroup.family,
      fatherId: throughFather ? parentId : null,
      motherId: throughFather ? null : parentId,
    ));
    return created;
  }

  @override
  Future<void> setSpouse(int aId, int bId) async {
    if (_persons[aId] == null || _persons[bId] == null) return;
    // 先解除双方各自的旧配偶（若不是对方），避免留下单向悬挂指针。
    _unlinkSpouse(aId, keep: bId);
    _unlinkSpouse(bId, keep: aId);
    _persons[aId] = _persons[aId]!.copyWith(spouseId: bId);
    _persons[bId] = _persons[bId]!.copyWith(spouseId: aId);
    _bus.ping();
  }

  @override
  Future<void> clearSpouse(int personId) async {
    _unlinkSpouse(personId);
    _bus.ping();
  }

  /// 解除 [personId] 的配偶关系（双向清干净）。
  /// [keep]：若其当前配偶正是 keep，则跳过（用于"改成同一个人"的幂等场景）。
  void _unlinkSpouse(int personId, {int? keep}) {
    final p = _persons[personId];
    if (p == null) return;
    final old = p.spouseId;
    if (old == null || old == keep) return;
    final partner = _persons[old];
    if (partner != null && partner.spouseId == personId) {
      _persons[old] = partner.copyWith(spouseId: null); // 清对方回指
    }
    _persons[personId] = p.copyWith(spouseId: null);
  }

  @override
  Future<void> setBloodPrimary(int personId) async {
    final p = _persons[personId];
    if (p == null) return;
    _persons[personId] = p.copyWith(marriedIn: false);
    final spouseId = p.spouseId;
    if (spouseId != null && _persons[spouseId] != null) {
      _persons[spouseId] = _persons[spouseId]!.copyWith(marriedIn: true);
    }
    _bus.ping();
  }

  @override
  Future<void> setSelf(int personId) async {
    if (_persons[personId] == null) return;
    for (final p in _persons.values.toList()) {
      final shouldBe = p.id == personId;
      if (p.isSelf != shouldBe) {
        _persons[p.id] = p.copyWith(isSelf: shouldBe);
      }
    }
    _bus.ping();
  }

  void _link(int aId, int bId) {
    final a = _persons[aId];
    final b = _persons[bId];
    if (a != null) _persons[aId] = a.copyWith(spouseId: bId);
    if (b != null) _persons[bId] = b.copyWith(spouseId: aId);
  }

  // ============ 圈子 ============

  @override
  Future<List<String>> getAllTags() async {
    final set = <String>{};
    for (final p in _persons.values) {
      set.addAll(p.tags);
    }
    return set.toList()..sort();
  }

  @override
  Future<List<Person>> getPersonsByTag(String tag) async =>
      _persons.values.where((p) => p.tags.contains(tag)).toList();

  // ============ 事件 ============

  @override
  Future<List<Event>> getAllEvents() async =>
      _events.values.toList()..sort((a, b) => b.occurDate.compareTo(a.occurDate));

  @override
  Future<Event?> getEvent(int id) async => _events[id];

  @override
  Future<List<Event>> searchEvents(String query) async {
    final q = query.trim().toLowerCase();
    final all = _events.values.toList()
      ..sort((a, b) => b.occurDate.compareTo(a.occurDate));
    if (q.isEmpty) return all;
    return all.where((e) {
      return e.title.toLowerCase().contains(q) ||
          (e.detail?.toLowerCase().contains(q) ?? false) ||
          e.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Future<List<Event>> getEventsByPerson(int personId) async => _events.values
      .where((e) => e.boundPersonIds.contains(personId))
      .toList()
    ..sort((a, b) => b.occurDate.compareTo(a.occurDate));

  @override
  Future<Event> addEvent(Event event) async {
    final created = event.copyWith(id: _nextEventId);
    _events[created.id] = created;
    _bus.ping();
    return created;
  }

  @override
  Future<void> updateEvent(Event event) async {
    _events[event.id] = event;
    _bus.ping();
  }

  @override
  Future<void> deleteEvent(int id) async {
    _events.remove(id);
    _bus.ping();
  }

  // ============ 差额清算 ============

  @override
  Future<PersonBalance> getBalanceWith(int personId) async {
    var income = 0.0;
    var expense = 0.0;
    for (final e in _events.values) {
      if (!e.isMoney || !e.boundPersonIds.contains(personId)) continue;
      if (e.direction == MoneyDirection.income) {
        income += e.amount ?? 0;
      } else if (e.direction == MoneyDirection.expense) {
        expense += e.amount ?? 0;
      }
    }
    return PersonBalance(totalIncome: income, totalExpense: expense);
  }
}
