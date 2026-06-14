import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/local_image.dart';

/// 记一笔回忆 / 人情往来：新增或编辑。传 [existing] 进入编辑模式。
/// 返回 true 表示已保存。
class EventFormPage extends StatefulWidget {
  const EventFormPage({super.key, this.existing});

  final Event? existing;
  bool get isEditing => existing != null;

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  late final FolksRepository _repo;
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _detail = TextEditingController();
  final _tags = TextEditingController();

  EventType _type = EventType.material;
  MoneyDirection _direction = MoneyDirection.expense;
  late DateTime _occurDate;
  final Set<int> _selected = {};
  final List<String> _photos = []; // 本地图片路径
  List<Person> _people = const [];

  bool get _isMoney => _type == EventType.material;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();

    final e = widget.existing;
    if (e != null) {
      _type = e.type;
      _title.text = e.title;
      _detail.text = e.detail ?? '';
      _direction = e.direction ?? MoneyDirection.expense;
      _amount.text = e.amount?.toStringAsFixed(0) ?? '';
      _occurDate = e.occurDate;
      _selected.addAll(e.boundPersonIds);
      _photos.addAll(e.photoPaths);
      _tags.text = e.tags.join(' ');
    } else {
      _occurDate = DateTime.now();
    }

    _repo.getAllPersons().then((list) {
      if (mounted) setState(() => _people = list);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _detail.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _photos.addAll(picked.map((x) => x.path)));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      helpText: context.l10n.fieldOccurDate,
    );
    if (picked != null) setState(() => _occurDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.atLeastOnePerson)),
      );
      return;
    }

    final draft = Event(
      id: widget.existing?.id ?? 0,
      type: _type,
      title: _title.text.trim(),
      detail: _detail.text.trim().isEmpty ? null : _detail.text.trim(),
      occurDate: _occurDate,
      boundPersonIds: _selected.toList(),
      photoPaths: List.of(_photos),
      tags: _tags.text
          .split(RegExp(r'[,，;；\s]+'))
          .where((e) => e.isNotEmpty)
          .toList(),
      direction: _isMoney ? _direction : null,
      amount: _isMoney ? double.tryParse(_amount.text.trim()) : null,
    );
    if (widget.isEditing) {
      await _repo.updateEvent(draft);
    } else {
      await _repo.addEvent(draft);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final dateText =
        '${_occurDate.year}-${_occurDate.month.toString().padLeft(2, '0')}-${_occurDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? t.editEntry : t.recordEntry),
        actions: [
          TextButton(onPressed: _save, child: Text(t.actionSave)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(Dim.pad),
          children: [
            SegmentedButton<EventType>(
              segments: [
                for (final type in EventType.values)
                  ButtonSegment(
                      value: type,
                      label: Text('${type.emoji}${type.label(t)}')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: t.fieldEventTitle,
                  hintText: t.fieldEventTitleHint,
                  border: const OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? t.validateTitle : null,
            ),
            const SizedBox(height: Dim.gap),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              leading: const Icon(Icons.event_outlined),
              title: Text(t.fieldOccurDate),
              subtitle: Text(dateText),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _pickDate,
            ),
            if (_isMoney) ...[
              const SizedBox(height: Dim.gap),
              SegmentedButton<MoneyDirection>(
                segments: [
                  ButtonSegment(
                      value: MoneyDirection.expense, label: Text(t.dirExpense)),
                  ButtonSegment(
                      value: MoneyDirection.income, label: Text(t.dirIncome)),
                ],
                selected: {_direction},
                onSelectionChanged: (s) =>
                    setState(() => _direction = s.first),
              ),
              const SizedBox(height: Dim.gap),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: t.fieldAmount,
                    prefixText: '¥ ',
                    border: const OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 20),
            Text(t.relatedPeopleReq,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(t.relatedPeopleHint,
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
            const SizedBox(height: 20),
            Row(
              children: [
                Text(t.sectionPhotos,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addPhotos,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: Text(t.actionAdd),
                ),
              ],
            ),
            if (_photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      LocalImage(_photos[i], size: 80),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _detail,
              maxLines: 3,
              decoration: InputDecoration(
                  labelText: t.fieldJournal,
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: Dim.gap),
            TextFormField(
              controller: _tags,
              decoration: InputDecoration(
                labelText: t.fieldTags,
                hintText: t.eventTagsHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
