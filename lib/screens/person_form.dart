import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar.dart';

/// 成员表单：新增或编辑。
/// - 新增：传 [group]（家族 / 圈子）。
/// - 编辑：传 [existing]，分组取自该成员。
/// 返回 true 表示已保存（调用方据此刷新）。
class PersonFormPage extends StatefulWidget {
  const PersonFormPage(
      {super.key,
      this.group,
      this.existing,
      this.parentOf,
      this.parentIsFather})
      : assert(group != null || existing != null || parentOf != null,
            '需 group / existing / parentOf 之一');

  final PersonGroup? group;
  final Person? existing;

  /// 从某人详情页「添加子女」时传入：新成员的家长，分组跟随 ta。
  final Person? parentOf;

  /// 家长是父(true)还是母(false)。省略则按家长性别推断（女=母，否则父）。
  final bool? parentIsFather;

  PersonGroup get effectiveGroup =>
      existing?.group ?? parentOf?.group ?? group ?? PersonGroup.family;
  bool get isEditing => existing != null;
  bool get isAddingChild => existing == null && parentOf != null;

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  late final FolksRepository _repo;
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController(); // 显示名（必填）
  final _realName = TextEditingController(); // 真名（选填）
  final _appellation = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _tags = TextEditingController();
  final _memo = TextEditingController();

  Gender _gender = Gender.unknown;
  int? _birthYear;
  int? _birthMonth;
  int? _birthDay;
  bool _remindBirthday = true;
  List<Anniversary> _anniversaries = [];
  String? _photoPath;

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
      _name.text = e.name;
      _realName.text = e.realName ?? '';
      _appellation.text = e.customAppellation ?? '';
      _phone.text = e.phone ?? '';
      _email.text = e.email ?? '';
      _tags.text = e.tags.join(' ');
      _memo.text = e.memo ?? '';
      _gender = e.gender;
      if (e.birthDate != null) {
        _birthYear = e.birthDate!.year;
        if (e.birthPrecision != BirthPrecision.year) {
          _birthMonth = e.birthDate!.month;
        }
        if (e.birthPrecision == BirthPrecision.full) {
          _birthDay = e.birthDate!.day;
        }
      }
      _remindBirthday = e.remindBirthday;
      _anniversaries = List.of(e.anniversaries);
      _photoPath = e.photoPath;
      _fatherId = e.fatherId;
      _motherId = e.motherId;
      _spouseId = e.spouseId;
    }

    // 「添加子女」：预设父/母链接。显式 parentIsFather 优先，否则按家长性别推断。
    final parent = widget.parentOf;
    if (parent != null) {
      final isFather = widget.parentIsFather ?? (parent.gender != Gender.female);
      if (isFather) {
        _fatherId = parent.id;
      } else {
        _motherId = parent.id;
      }
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
      _realName,
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

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _addAnniversary() async {
    final labelCtrl = TextEditingController();
    DateTime? date;
    final result = await showDialog<Anniversary>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(ctx.l10n.addAnniversary),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration:
                    InputDecoration(hintText: ctx.l10n.anniversaryLabelHint),
              ),
              const SizedBox(height: Dim.gap),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 18),
                label: Text(date == null ? ctx.l10n.fieldOccurDate : _fmtDate(date!)),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: date ?? DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setLocal(() => date = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(ctx.l10n.actionCancel)),
            FilledButton(
              onPressed: () {
                if (labelCtrl.text.trim().isEmpty || date == null) return;
                Navigator.pop(ctx,
                    Anniversary(label: labelCtrl.text.trim(), date: date!));
              },
              child: Text(ctx.l10n.actionAdd),
            ),
          ],
        ),
      ),
    );
    labelCtrl.dispose();
    if (result != null) {
      setState(() => _anniversaries = [..._anniversaries, result]);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  static int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

  /// 生日：年(必填) + 月(可选) + 日(可选)。填到哪算到哪，精度自动判定。
  Widget _buildBirthday(AppLocalizations t) {
    final nowYear = DateTime.now().year;
    final maxDay = (_birthYear != null && _birthMonth != null)
        ? _daysIn(_birthYear!, _birthMonth!)
        : 31;
    final dayShown = (_birthDay != null && _birthDay! > maxDay) ? null : _birthDay;

    DropdownMenuItem<int?> none() =>
        const DropdownMenuItem<int?>(value: null, child: Text('—'));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int?>(
            initialValue: _birthYear,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: t.labelYear, border: const OutlineInputBorder()),
            items: [
              none(),
              for (var y = nowYear; y >= 1900; y--)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => setState(() {
              _birthYear = v;
              if (v == null) {
                _birthMonth = null;
                _birthDay = null;
              }
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int?>(
            initialValue: _birthMonth,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: t.labelMonth, border: const OutlineInputBorder()),
            items: [
              none(),
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text('$m')),
            ],
            onChanged: _birthYear == null
                ? null
                : (v) => setState(() {
                      _birthMonth = v;
                      if (v == null ||
                          (_birthDay != null &&
                              _birthDay! > _daysIn(_birthYear!, v))) {
                        _birthDay = null;
                      }
                    }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int?>(
            initialValue: dayShown,
            isExpanded: true,
            decoration: InputDecoration(
                labelText: t.labelDay, border: const OutlineInputBorder()),
            items: [
              none(),
              for (var d = 1; d <= maxDay; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: _birthMonth == null
                ? null
                : (v) => setState(() => _birthDay = v),
          ),
        ),
      ],
    );
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

    // 由 年/月/日 推出生日与精度（填到哪算到哪；无年=无生日）。
    DateTime? bd;
    var bp = BirthPrecision.full;
    if (_birthYear != null) {
      bd = DateTime(_birthYear!, _birthMonth ?? 1, _birthDay ?? 1);
      bp = _birthDay != null
          ? BirthPrecision.full
          : (_birthMonth != null
              ? BirthPrecision.yearMonth
              : BirthPrecision.year);
    }

    // 直接用构造器（而非 copyWith），以便把清空的关系字段真正置回 null。
    // 配偶字段先沿用旧值，改动统一交给 setSpouse/clearSpouse 双向处理（见下）。
    final person = Person(
      id: widget.existing?.id ?? 0, // 新增时 addPerson 赋真实 id
      name: _name.text.trim(),
      realName: nn(_realName),
      gender: _gender,
      birthDate: bd,
      birthPrecision: bp,
      remindBirthday: _remindBirthday,
      anniversaries: _anniversaries,
      customAppellation: nn(_appellation),
      memo: nn(_memo),
      group: widget.effectiveGroup,
      fatherId: _fatherId, // 圈子的孩子也可有家长链接（仅家族显示选择器）
      motherId: _motherId,
      spouseId: _isFamily ? oldSpouse : null,
      marriedIn: widget.existing?.marriedIn ?? false,
      isSelf: widget.existing?.isSelf ?? false, // "我"固定，新增的人都不是
      photoPath: _photoPath,
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.toastSaved)),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? t.editProfile
            : widget.isAddingChild
                ? t.addChild
                : (_isFamily ? t.addFamilyMember : t.addFriend)),
        actions: [
          TextButton(onPressed: _save, child: Text(t.actionSave)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dim.pad),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Avatar(
                      name: _name.text.isEmpty ? '?' : _name.text,
                      photoPath: _photoPath,
                      radius: 44,
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Dim.pad),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: t.fieldDisplayName,
                  border: const OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.validateName : null,
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _realName,
              decoration: InputDecoration(
                  labelText: t.fieldRealName,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            SegmentedButton<Gender>(
              segments: [
                ButtonSegment(value: Gender.male, label: Text(t.genderMale)),
                ButtonSegment(
                    value: Gender.female, label: Text(t.genderFemale)),
                ButtonSegment(
                    value: Gender.unknown, label: Text(t.genderUnknown)),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: Dim.gap),
            _buildBirthday(t),
            if (_birthYear != null &&
                _birthMonth != null &&
                _birthDay != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(t.remindBirthday),
                value: _remindBirthday,
                onChanged: (v) => setState(() => _remindBirthday = v),
              ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _appellation,
              decoration: InputDecoration(
                  labelText: t.fieldAppellation,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: t.fieldPhone, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: t.fieldEmail, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            if (_isFamily) ...[
              _RelationPicker(
                label: t.relationFather,
                members: _familyMembers,
                value: _fatherId,
                onChanged: (v) => setState(() => _fatherId = v),
              ),
              const SizedBox(height: Dim.gap),
              _RelationPicker(
                label: t.relationMother,
                members: _familyMembers,
                value: _motherId,
                onChanged: (v) => setState(() => _motherId = v),
              ),
              const SizedBox(height: Dim.gap),
              _RelationPicker(
                label: t.relationSpouse,
                members: _familyMembers,
                value: _spouseId,
                onChanged: (v) => setState(() => _spouseId = v),
              ),
              const SizedBox(height: Dim.gap),
            ] else ...[
              TextFormField(
                controller: _tags,
                decoration: InputDecoration(
                  labelText: t.fieldTags,
                  hintText: t.fieldTagsHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Dim.gap),
            ],
            Row(
              children: [
                Text(t.sectionAnniversaries,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addAnniversary,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(t.addAnniversary),
                ),
              ],
            ),
            for (var i = 0; i < _anniversaries.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.event_outlined, size: 18),
                title: Text(_anniversaries[i].label),
                subtitle: Text(_fmtDate(_anniversaries[i].date)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(
                      () => _anniversaries = [..._anniversaries]..removeAt(i)),
                ),
              ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _memo,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: t.fieldMemo, border: const OutlineInputBorder()),
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
        const DropdownMenuItem<int?>(value: null, child: Text('—')),
        for (final m in members)
          DropdownMenuItem<int?>(value: m.id, child: Text(m.displayName)),
      ],
      onChanged: onChanged,
    );
  }
}
