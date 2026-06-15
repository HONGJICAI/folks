import 'package:flutter_test/flutter_test.dart';
import 'package:folks/models/person.dart';
import 'package:folks/widgets/family_forest.dart';

void main() {
  group('buildFamilyForest', () {
    test('父亲有爹、母亲没爹：爷爷应在顶层，夫妻整支挂其下（复现孤立爷爷）', () {
      // 我(1)←dad(2)+mom(5)；dad(2)←爷爷(3)；dad♥mom 互为配偶；mom 无父母。
      final people = [
        const Person(id: 1, name: '我', fatherId: 2, motherId: 5),
        const Person(id: 2, name: 'dad', fatherId: 3, spouseId: 5),
        const Person(id: 3, name: '爷爷'),
        const Person(id: 5, name: 'mom', spouseId: 2),
      ];

      final roots = buildFamilyForest(people);

      // 唯一顶层根是爷爷（修复前 mom 会抢先成根，爷爷落单变两根）。
      expect(roots.length, 1);
      expect(roots.single.primary.id, 3);

      // 爷爷下面挂着 dad♥mom 这一对。
      final couple = roots.single.children.single;
      expect({couple.primary.id, couple.secondary?.id}, {2, 5});

      // 这对夫妻下面是「我」。
      expect(couple.children.single.primary.id, 1);
    });

    test('未登记为配偶的共同父母成对、不重复整支', () {
      // 本人(1)←爸(2)；爸(2)←爷(3)+奶(4)，但爷奶未设为配偶。
      final people = [
        const Person(id: 1, name: '本人', fatherId: 2),
        const Person(id: 2, name: '爸', fatherId: 3, motherId: 4),
        const Person(id: 3, name: '爷'),
        const Person(id: 4, name: '奶'),
      ];

      final roots = buildFamilyForest(people);

      expect(roots.length, 1); // 爷♥奶 一个根
      expect({roots.single.primary.id, roots.single.secondary?.id}, {3, 4});
      expect(roots.single.children.single.primary.id, 2); // 爸只出现一次
      expect(roots.single.children.single.children.single.primary.id, 1);
    });

    test('普通无祖辈：夫妻自成一根', () {
      final people = [
        const Person(id: 1, name: '我', fatherId: 2, motherId: 3),
        const Person(id: 2, name: '爸', spouseId: 3),
        const Person(id: 3, name: '妈', spouseId: 2),
      ];
      final roots = buildFamilyForest(people);
      expect(roots.length, 1);
      expect({roots.single.primary.id, roots.single.secondary?.id}, {2, 3});
    });
  });
}
