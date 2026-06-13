import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../models/event.dart';
import '../models/person.dart';
import '../theme/app_theme.dart';
import '../widgets/local_image.dart';
import 'event_form.dart';
import 'person_detail.dart';
import 'photo_viewer.dart';

/// 事件详情页：完整展示一条回忆 / 人情往来，并提供编辑、删除。
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  late final FolksRepository _repo;
  late Future<(Event?, Map<int, Person>)> _future;
  Event? _loaded;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _future = _load();
  }

  Future<(Event?, Map<int, Person>)> _load() async {
    final event = await _repo.getEvent(widget.eventId);
    final all = await _repo.getAllPersons();
    return (event, {for (final p in all) p.id: p});
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _edit() async {
    final e = _loaded;
    if (e == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventFormPage(existing: e)),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete() async {
    final e = _loaded;
    if (e == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteEntryTitle),
        content: Text(context.l10n.deleteEntryBody(e.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.actionDelete)),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteEvent(e.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: context.l10n.actionEdit,
              onPressed: _edit),
          IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.l10n.actionDelete,
              onPressed: _delete),
        ],
      ),
      body: FutureBuilder<(Event?, Map<int, Person>)>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final (event, byId) = snap.data!;
          _loaded = event;
          if (event == null) {
            return Center(child: Text(context.l10n.eventGone));
          }
          return ListView(
            padding: const EdgeInsets.all(Dim.pad),
            children: [
              Row(
                children: [
                  Text(event.type.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(event.title,
                        style: theme.textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${event.type.label(context.l10n)} · ${_date(event.occurDate)}',
                  style: theme.textTheme.bodySmall),
              if (event.isMoney) ...[
                const SizedBox(height: Dim.gap),
                _MoneyLine(event: event),
              ],
              const SizedBox(height: 20),
              // 关联的人
              Text(context.l10n.relatedPeople, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (event.boundPersonIds.isEmpty)
                Row(
                  children: [
                    Icon(Icons.person_off_outlined,
                        size: 16, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(context.l10n.noLinkedMembers,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.tertiary)),
                  ],
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in event.boundPersonIds)
                      ActionChip(
                        label: Text(byId[id]?.displayName ?? '#$id'),
                        onPressed: byId[id] == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          PersonDetailPage(personId: id)),
                                ),
                      ),
                  ],
                ),
              if (event.photoPaths.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(context.l10n.sectionPhotos,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < event.photoPaths.length; i++)
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PhotoViewerPage(
                              paths: event.photoPaths,
                              initialIndex: i,
                            ),
                          ),
                        ),
                        child: LocalImage(event.photoPaths[i], size: 110),
                      ),
                  ],
                ),
              ],
              if (event.detail != null && event.detail!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(context.l10n.fieldJournal,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(event.detail!, style: theme.textTheme.bodyMedium),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isExpense = event.direction == MoneyDirection.expense;
    final color = isExpense ? scheme.error : Colors.green.shade600;
    final dirLabel = event.direction?.label(context.l10n) ?? '';
    return Row(
      children: [
        Text('$dirLabel  ', style: TextStyle(color: color)),
        Text('¥${event.amount?.toStringAsFixed(0) ?? '0'}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 20)),
      ],
    );
  }
}
