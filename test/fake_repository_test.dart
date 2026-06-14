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

    test('任意变更会触发 changes 通知', () async {
      final repo = FakeRepository();
      var fired = 0;
      repo.changes.addListener(() => fired++);
      await repo.addPerson(const Person(id: 0, name: 'X'));
      expect(fired, greaterThan(0));
    });
  });
}
