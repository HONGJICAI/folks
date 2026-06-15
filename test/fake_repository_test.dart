import 'package:flutter_test/flutter_test.dart';
import 'package:folks/data/fake_repository.dart';
import 'package:folks/models/event.dart';
import 'package:folks/models/person.dart';

void main() {
  group('FakeRepository 关系一致性', () {
    test('setSpouse 双向建立配偶', () async {
      final repo = FakeRepository();
      final a = await repo.addPerson(const Person(id: 0, name: 'A'));
      final b = await repo.addPerson(const Person(id: 0, name: 'B'));
      await repo.setSpouse(a.id, b.id);
      expect((await repo.getPerson(a.id))!.spouseId, b.id);
      expect((await repo.getPerson(b.id))!.spouseId, a.id);
    });

    test('改配偶时旧配偶双向断开（修复 #1）', () async {
      final repo = FakeRepository();
      final a = await repo.addPerson(const Person(id: 0, name: 'A'));
      final b = await repo.addPerson(const Person(id: 0, name: 'B'));
      final c = await repo.addPerson(const Person(id: 0, name: 'C'));
      await repo.setSpouse(a.id, b.id);
      await repo.setSpouse(a.id, c.id); // A 改娶 C
      expect((await repo.getPerson(a.id))!.spouseId, c.id);
      expect((await repo.getPerson(c.id))!.spouseId, a.id);
      expect((await repo.getPerson(b.id))!.spouseId, isNull); // 旧配偶 B 已断开
    });

    test('clearSpouse 双向清除', () async {
      final repo = FakeRepository();
      final a = await repo.addPerson(const Person(id: 0, name: 'A'));
      final b = await repo.addPerson(const Person(id: 0, name: 'B'));
      await repo.setSpouse(a.id, b.id);
      await repo.clearSpouse(a.id);
      expect((await repo.getPerson(a.id))!.spouseId, isNull);
      expect((await repo.getPerson(b.id))!.spouseId, isNull);
    });

    test('删除成员后清除父母/配偶引用与事件绑定', () async {
      final repo = FakeRepository();
      final parent = await repo.addPerson(const Person(id: 0, name: 'P'));
      final child = await repo
          .addPerson(Person(id: 0, name: 'C', fatherId: parent.id));
      final spouse = await repo.addPerson(const Person(id: 0, name: 'S'));
      await repo.setSpouse(parent.id, spouse.id);
      final ev = await repo.addEvent(Event(
        id: 0,
        type: EventType.experience,
        title: '聚餐',
        occurDate: DateTime(2020, 1, 1),
        boundPersonIds: [parent.id, child.id],
      ));

      await repo.deletePerson(parent.id);

      expect((await repo.getPerson(child.id))!.fatherId, isNull);
      expect((await repo.getPerson(spouse.id))!.spouseId, isNull);
      expect((await repo.getEvent(ev.id))!.boundPersonIds,
          isNot(contains(parent.id)));
    });

    test('删除人物只解绑、不删除 event（即使变成空绑定）', () async {
      final repo = FakeRepository();
      final solo = await repo.addPerson(const Person(id: 0, name: '狗蛋'));
      final ev = await repo.addEvent(Event(
        id: 0,
        type: EventType.milestone,
        title: '上小学',
        occurDate: DateTime(2024, 9, 1),
        boundPersonIds: [solo.id],
      ));

      await repo.deletePerson(solo.id);

      final after = await repo.getEvent(ev.id);
      expect(after, isNotNull); // event 仍在（留住回忆）
      expect(after!.boundPersonIds, isEmpty); // 仅解绑
    });

    test('setSelf 全局唯一：旧的"我"被清除', () async {
      final repo = FakeRepository();
      final a = await repo.addPerson(const Person(id: 0, name: 'A'));
      final b = await repo.addPerson(const Person(id: 0, name: 'B'));
      await repo.setSelf(a.id);
      await repo.setSelf(b.id);
      expect((await repo.getPerson(a.id))!.isSelf, isFalse);
      expect((await repo.getPerson(b.id))!.isSelf, isTrue);
    });

    test('"我"（isSelf）不可删除', () async {
      final repo = FakeRepository();
      final me = await repo.addPerson(const Person(id: 0, name: '我'));
      await repo.setSelf(me.id);
      await repo.deletePerson(me.id);
      expect(await repo.getPerson(me.id), isNotNull); // 仍在
    });

    test('clearAll 清空所有人/回忆，只留一张空白的"我"', () async {
      final repo = FakeRepository();
      await repo.addEvent(Event(
          id: 0,
          type: EventType.experience,
          title: 'x',
          occurDate: DateTime(2020)));
      await repo.clearAll(selfName: '我');
      final people = await repo.getAllPersons();
      expect(people.length, 1);
      expect(people.single.isSelf, isTrue);
      expect(people.single.name, '我');
      expect(await repo.getAllEvents(), isEmpty);
    });

    test('被设为父/母者性别强制收敛：父=男、母=女', () async {
      final repo = FakeRepository();
      final dad = await repo.addPerson(const Person(id: 0, name: 'D'));
      final mom =
          await repo.addPerson(const Person(id: 0, name: 'M', gender: Gender.male));
      final kid = await repo.addPerson(const Person(id: 0, name: 'K'));
      await repo.updatePerson(
          (await repo.getPerson(kid.id))!.copyWith(fatherId: dad.id, motherId: mom.id));
      expect((await repo.getPerson(dad.id))!.gender, Gender.male); // 未知→男
      expect((await repo.getPerson(mom.id))!.gender, Gender.female); // 男→女(覆盖)
    });

    test('给已有成员加父亲：fatherId 应持久化（复现"爷爷没 link"）', () async {
      final repo = FakeRepository();
      final dad = await repo.addPerson(const Person(id: 0, name: 'dad'));
      // 模拟详情页 _addParent：先建爷爷，再把 dad.fatherId 指过去。
      final grandpa = await repo.addPerson(const Person(id: 0, name: '爷爷'));
      await repo.updatePerson(
          (await repo.getPerson(dad.id))!.copyWith(fatherId: grandpa.id));
      expect((await repo.getPerson(dad.id))!.fatherId, grandpa.id);
      // 反查：爷爷应能在 getChildren 里看到 dad。
      final kids = await repo.getChildren(grandpa.id);
      expect(kids.map((p) => p.id), contains(dad.id));
    });

    test('linkCoParentsIfUnset：父母双全且都未婚配 → 自动成对', () async {
      final repo = FakeRepository();
      final kid = await repo.addPerson(const Person(id: 0, name: 'K'));
      final f = await repo.addPerson(const Person(id: 0, name: 'F'));
      final m = await repo.addPerson(const Person(id: 0, name: 'M'));
      await repo.updatePerson(
          (await repo.getPerson(kid.id))!.copyWith(fatherId: f.id, motherId: m.id));
      await repo.linkCoParentsIfUnset(kid.id);
      expect((await repo.getPerson(f.id))!.spouseId, m.id);
      expect((await repo.getPerson(m.id))!.spouseId, f.id);
    });

    test('linkCoParentsIfUnset：一方已有配偶 → 不动（尊重再婚等）', () async {
      final repo = FakeRepository();
      final kid = await repo.addPerson(const Person(id: 0, name: 'K'));
      final f = await repo.addPerson(const Person(id: 0, name: 'F'));
      final m = await repo.addPerson(const Person(id: 0, name: 'M'));
      final other = await repo.addPerson(const Person(id: 0, name: 'StepMom'));
      await repo.setSpouse(f.id, other.id); // 父亲已与继母结婚
      await repo.updatePerson(
          (await repo.getPerson(kid.id))!.copyWith(fatherId: f.id, motherId: m.id));
      await repo.linkCoParentsIfUnset(kid.id);
      expect((await repo.getPerson(f.id))!.spouseId, other.id); // 仍是继母
      expect((await repo.getPerson(m.id))!.spouseId, isNull); // 生母未被强连
    });

    test('任意变更会触发 changes 通知', () async {
      final repo = FakeRepository();
      var fired = 0;
      repo.changes.addListener(() => fired++);
      await repo.addPerson(const Person(id: 0, name: 'X'));
      expect(fired, greaterThan(0));
    });
  });
}
