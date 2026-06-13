import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';

/// 记一笔回忆 / 人情往来。返回 true 表示已新增。
class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  late final FolksRepository _repo;
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _detail = TextEditingController();

  EventType _type = EventType.material;
  MoneyDirection _direction = MoneyDirection.expense;
  late DateTime _occurDate;
  final Set<int> _selected = {};
  List<Person> _people = const [];

  bool get _isMoney => _type == EventType.material;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _occurDate = DateTime.now();
    _repo.getAllPersons().then((list) {
      if (mounted) setState(() => _people = list);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: '事件发生日期',
    );
    if (picked != null) setState(() => _occurDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少关联一个人')),
      );
      return;
    }

    final draft = Event(
      id: 0,
      type: _type,
      title: _title.text.trim(),
      detail: _detail.text.trim().isEmpty ? null : _detail.text.trim(),
      occurDate: _occurDate,
      boundPersonIds: _selected.toList(),
      direction: _isMoney ? _direction : null,
      amount: _isMoney ? double.tryParse(_amount.text.trim()) : null,
    );
    await _repo.addEvent(draft);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${_occurDate.year}-${_occurDate.month.toString().padLeft(2, '0')}-${_occurDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('记一笔'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dim.pad),
          children: [
            SegmentedButton<EventType>(
              segments: [
                for (final t in EventType.values)
                  ButtonSegment(value: t, label: Text('${t.emoji}${t.label}')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                  labelText: '事件标题 *',
                  hintText: '如 大表姐结婚随礼',
                  border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写标题' : null,
            ),
            const SizedBox(height: Dim.gap),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              leading: const Icon(Icons.event_outlined),
              title: const Text('发生日期'),
              subtitle: Text(dateText),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            if (_isMoney) ...[
              const SizedBox(height: Dim.gap),
              SegmentedButton<MoneyDirection>(
                segments: const [
                  ButtonSegment(
                      value: MoneyDirection.expense, label: Text('支出')),
                  ButtonSegment(
                      value: MoneyDirection.income, label: Text('收入')),
                ],
                selected: {_direction},
                onSelectionChanged: (s) =>
                    setState(() => _direction = s.first),
              ),
              const SizedBox(height: Dim.gap),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: '金额（元）',
                    prefixText: '¥ ',
                    border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 20),
            Text('关联的人 *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('可多选；记录会出现在每个人的时光轴里',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: Dim.gap),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _people)
                  FilterChip(
                    label: Text(p.displayName),
                    selected: _selected.contains(p.id),
                    onSelected: (on) => setState(
                        () => on ? _selected.add(p.id) : _selected.remove(p.id)),
                  ),
              ],
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _detail,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: '手记', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
