import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

/// 成员表单：新增或编辑。
/// - 新增：传 [group]（家族 / 圈子）。
/// - 编辑：传 [existing]，分组取自该成员。
/// 返回 true 表示已保存（调用方据此刷新）。
class PersonFormPage extends StatefulWidget {
  const PersonFormPage({super.key, this.group, this.existing})
      : assert(group != null || existing != null, '新增需 group，编辑需 existing');

  final PersonGroup? group;
  final Person? existing;

  PersonGroup get effectiveGroup => existing?.group ?? group!;
  bool get isEditing => existing != null;

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  late final FolksRepository _repo;
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _appellation = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _tags = TextEditingController();
  final _memo = TextEditingController();

  Gender _gender = Gender.unknown;
  DateTime? _birthDate;

  // 家族关系（可选）
  int? _fatherId;
  int? _motherId;
  int? _spouseId;
  List<Person> _familyMembers = const [];

  bool get _isFamily => widget.effectiveGroup == PersonGroup.family;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();

    final e = widget.existing;
    if (e != null) {
      _name.text = e.realName;
      _nickname.text = e.nickname ?? '';
      _appellation.text = e.customAppellation ?? '';
      _phone.text = e.phone ?? '';
      _email.text = e.email ?? '';
      _tags.text = e.tags.join(' ');
      _memo.text = e.memo ?? '';
      _gender = e.gender;
      _birthDate = e.birthDate;
      _fatherId = e.fatherId;
      _motherId = e.motherId;
      _spouseId = e.spouseId;
    }

    if (_isFamily) {
      _repo.getPersonsByGroup(PersonGroup.family).then((list) {
        if (mounted) {
          // 编辑时把自己从关系候选里排除（不能做自己的父母/配偶）。
          setState(() => _familyMembers =
              list.where((p) => p.id != widget.existing?.id).toList());
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _nickname,
      _appellation,
      _phone,
      _email,
      _tags,
      _memo
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: '选择生日',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final tags = _tags.text
        .split(RegExp(r'[,，;；\s]+'))
        .where((e) => e.isNotEmpty)
        .toList();

    String? nn(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final oldSpouse = widget.existing?.spouseId;

    // 直接用构造器（而非 copyWith），以便把清空的关系字段真正置回 null。
    // 配偶字段先沿用旧值，改动统一交给 setSpouse/clearSpouse 双向处理（见下）。
    final person = Person(
      id: widget.existing?.id ?? 0, // 新增时 addPerson 赋真实 id
      realName: _name.text.trim(),
      nickname: nn(_nickname),
      gender: _gender,
      birthDate: _birthDate,
      customAppellation: nn(_appellation),
      memo: nn(_memo),
      group: widget.effectiveGroup,
      fatherId: _isFamily ? _fatherId : null,
      motherId: _isFamily ? _motherId : null,
      spouseId: _isFamily ? oldSpouse : null,
      marriedIn: widget.existing?.marriedIn ?? false,
      phone: nn(_phone),
      email: nn(_email),
      tags: _isFamily ? const [] : tags,
    );

    final int id;
    if (widget.isEditing) {
      await _repo.updatePerson(person);
      id = person.id;
    } else {
      id = (await _repo.addPerson(person)).id;
    }
    // 配偶有变更时才动它：设置（双向 + 解除旧配偶）或清空。
    if (_isFamily && _spouseId != oldSpouse) {
      if (_spouseId == null) {
        await _repo.clearSpouse(id);
      } else {
        await _repo.setSpouse(id, _spouseId!);
      }
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final birthdayText = _birthDate == null
        ? '未填写'
        : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? '编辑资料'
            : (_isFamily ? '添加家族成员' : '添加朋友')),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dim.pad),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: '真实姓名 *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写姓名' : null,
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _nickname,
              decoration: const InputDecoration(
                  labelText: '小名 / 乳名', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.male, label: Text('男')),
                ButtonSegment(value: Gender.female, label: Text('女')),
                ButtonSegment(value: Gender.unknown, label: Text('未知')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: Dim.gap),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              leading: const Icon(Icons.cake_outlined),
              title: const Text('生日'),
              subtitle: Text(birthdayText),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickBirthday,
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _appellation,
              decoration: const InputDecoration(
                  labelText: '自定义称呼（如 大表姐）',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: '电话', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: '邮箱', border: OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            if (_isFamily) ...[
              _RelationPicker(
                label: '父亲',
                members: _familyMembers,
                value: _fatherId,
                onChanged: (v) => setState(() => _fatherId = v),
              ),
              const SizedBox(height: Dim.gap),
              _RelationPicker(
                label: '母亲',
                members: _familyMembers,
                value: _motherId,
                onChanged: (v) => setState(() => _motherId = v),
              ),
              const SizedBox(height: Dim.gap),
              _RelationPicker(
                label: '配偶',
                members: _familyMembers,
                value: _spouseId,
                onChanged: (v) => setState(() => _spouseId = v),
              ),
              const SizedBox(height: Dim.gap),
            ] else ...[
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(
                  labelText: '标签（空格或逗号分隔）',
                  hintText: '大学室友 骑行搭子',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Dim.gap),
            ],
            TextFormField(
              controller: _memo,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: '备注', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}

/// 关系选择下拉：从已有家族成员里选，可留空。
class _RelationPicker extends StatelessWidget {
  const _RelationPicker({
    required this.label,
    required this.members,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Person> members;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('无')),
        for (final m in members)
          DropdownMenuItem<int?>(value: m.id, child: Text(m.displayName)),
      ],
      onChanged: onChanged,
    );
  }
}
