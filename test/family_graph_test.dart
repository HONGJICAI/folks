import 'package:flutter_test/flutter_test.dart';
import 'package:folks/models/person.dart';
import 'package:folks/widgets/family_graph.dart';

void main() {
  group('buildFamilyGraph', () {
    test('夫妻双方都有祖辈：夫妻单元挂在两个父辈单元下（拆分夫妻）', () {
      // 我(1)←dad(2)+mom(5)；dad←爷爷(3)；mom←外公(6)；dad♥mom 互为配偶。
      final people = [
        const Person(id: 1, name: '我', isSelf: true, fatherId: 2, motherId: 5),
        const Person(id: 2, name: 'dad', fatherId: 3, spouseId: 5),
        const Person(id: 5, name: 'mom', fatherId: 6, spouseId: 2),
        const Person(id: 3, name: '爷爷'),
        const Person(id: 6, name: '外公'),
      ];

      final units = buildFamilyGraph(people);

      FamilyUnit unitWith(int id) => units.firstWhere((u) => u.contains(id));
      final dadMom = unitWith(2);
      final grandpa = unitWith(3);
      final waigong = unitWith(6);
      final me = unitWith(1);

      // dad♥mom 是一个夫妻单元，且有两个父辈单元（爷爷 + 外公）——不再有人落单。
      expect(dadMom.contains(5), isTrue);
      expect(dadMom.parents.length, 2);
      expect(dadMom.parents, containsAll([grandpa, waigong]));

      // 代际：祖辈 0、父母 1、我 2。
      expect(grandpa.gen, 0);
      expect(waigong.gen, 0);
      expect(dadMom.gen, 1);
      expect(me.gen, 2);

      // 连线侧：爷爷接 primary(dad) 侧、外公接 secondary(mom) 侧。
      expect(dadMom.sideForParent(grandpa), isTrue);
      expect(dadMom.sideForParent(waigong), isFalse);
    });

    test('单侧祖辈：普通合并夫妻只有一个父辈', () {
      final people = [
        const Person(id: 1, name: '我', fatherId: 2, motherId: 5),
        const Person(id: 2, name: 'dad', fatherId: 3, spouseId: 5),
        const Person(id: 5, name: 'mom', spouseId: 2, marriedIn: true),
        const Person(id: 3, name: '爷爷'),
      ];
      final units = buildFamilyGraph(people);
      final dadMom = units.firstWhere((u) => u.contains(2));
      expect(dadMom.parents.length, 1); // 只有爷爷一侧
    });
  });

  group('compareSiblings 左右排序', () {
    test('出生早的在左、无生日靠后、相同男左女右', () {
      const older = Person(id: 1, name: 'A', birthDate: null, gender: Gender.female);
      const younger = Person(id: 2, name: 'B', gender: Gender.male); // 无生日
      const e1 = Person(id: 3, name: 'C', birthDate: null);

      const bornEarly = Person(id: 4, name: 'D', gender: Gender.female);
      // 用真实日期对象比较
      final p1980 = bornEarly.copyWith(birthDate: DateTime(1980));
      final p1990 = older.copyWith(birthDate: DateTime(1990));
      expect(compareSiblings(p1980, p1990) < 0, isTrue); // 1980 在左

      final hasDate = younger.copyWith(birthDate: DateTime(1995));
      expect(compareSiblings(hasDate, e1) < 0, isTrue); // 有生日 < 无生日（靠后）

      // 同日期 → 男左女右
      final m = Person(id: 5, name: 'M', gender: Gender.male, birthDate: DateTime(2000));
      final f = Person(id: 6, name: 'F', gender: Gender.female, birthDate: DateTime(2000));
      expect(compareSiblings(m, f) < 0, isTrue);
    });

    test('子女按出生→男左女右排序，无生日的在最后', () {
      final people = [
        const Person(id: 1, name: 'dad', spouseId: 2),
        const Person(id: 2, name: 'mom', spouseId: 1),
        Person(id: 3, name: '老三', fatherId: 1, motherId: 2), // 无生日 → 最后
        Person(id: 4, name: '老大', fatherId: 1, motherId: 2, birthDate: DateTime(2010)),
        Person(id: 5, name: '老二', fatherId: 1, motherId: 2, birthDate: DateTime(2015)),
      ];
      final units = buildFamilyGraph(people);
      final parent = units.firstWhere((u) => u.contains(1));
      final names = parent.children.map((c) => c.primary.name).toList();
      expect(names, ['老大', '老二', '老三']);
    });
  });

  group('layoutFamilyGraph', () {
    test('行内不重叠', () {
      final people = [
        const Person(id: 1, name: '我', isSelf: true, fatherId: 2, motherId: 5),
        const Person(id: 2, name: 'dad', fatherId: 3, spouseId: 5),
        const Person(id: 5, name: 'mom', fatherId: 6, spouseId: 2),
        const Person(id: 3, name: '爷爷'),
        const Person(id: 6, name: '外公'),
      ];
      final units = buildFamilyGraph(people);
      layoutFamilyGraph(units,
          widthOf: (u) => u.isCouple ? 250 : 150,
          rowHeight: 116,
          nodeHeight: 64,
          hGap: 20);

      // 同一代内，按 x 排序后相邻单元不重叠。
      final maxGen = units.map((u) => u.gen).reduce((a, b) => a > b ? a : b);
      for (var g = 0; g <= maxGen; g++) {
        final row = units.where((u) => u.gen == g).toList()
          ..sort((a, b) => a.x.compareTo(b.x));
        for (var i = 1; i < row.length; i++) {
          final prevRight = row[i - 1].x + (row[i - 1].isCouple ? 250 : 150);
          expect(row[i].x, greaterThanOrEqualTo(prevRight),
              reason: '第 $g 代有重叠');
        }
      }
    });
  });
}
