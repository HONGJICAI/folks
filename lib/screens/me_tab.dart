import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../locale_controller.dart';
import '../models/person.dart';
import '../settings_controller.dart';
import '../theme/app_theme.dart';
import '../util/dates.dart';
import '../widgets/avatar.dart';
import 'person_detail.dart';

/// 「我」Tab：自我资料卡 + 设置。
class MeTab extends StatefulWidget {
  const MeTab({super.key});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  late final FolksRepository _repo;
  late Future<List<Person>> _all;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _all = _repo.getAllPersons();
    _repo.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _all = _repo.getAllPersons();
    });
  }

  /// 未来 30 天内的提醒：生日（若开启）+ 各纪念日，按天数升序。
  List<_Reminder> _upcomingReminders(List<Person> people) {
    final now = DateTime.now();
    final list = <_Reminder>[];
    for (final p in people) {
      if (p.canRemindBirthday && p.remindBirthday) {
        final b = p.birthDate!;
        final d = daysUntilNextBirthday(b, now);
        if (d <= 30) {
          list.add(_Reminder(
              person: p,
              days: d,
              isBirthday: true,
              count: nextBirthdayAge(b, now)));
        }
      }
      for (final a in p.anniversaries) {
        final d = daysUntilNextBirthday(a.date, now);
        if (d <= 30) {
          list.add(_Reminder(
              person: p,
              days: d,
              isBirthday: false,
              anniLabel: a.label,
              count: nextBirthdayAge(a.date, now)));
        }
      }
    }
    list.sort((a, b) => a.days.compareTo(b.days));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.tabMe)),
      body: ListView(
        children: [
          FutureBuilder<List<Person>>(
            future: _all,
            builder: (context, snap) {
              final people = snap.data ?? const <Person>[];
              Person? self;
              for (final p in people) {
                if (p.isSelf) self = p;
              }
              final reminders = _upcomingReminders(people);
              return Column(
                children: [
                  _SelfCard(person: self),
                  if (reminders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionLabel(t.sectionReminders),
                    for (final r in reminders) _ReminderTile(item: r),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _SectionLabel(t.settingsSection),
          const _LanguageSetting(),
          const _ThemeSetting(),
          const _DarkModeSetting(),
          const Divider(height: 24),
          _ComingSoonTile(icon: Icons.lock_outline, label: t.settingAppLock),
          _ComingSoonTile(
              icon: Icons.backup_outlined, label: t.settingBackup),
          _ComingSoonTile(
              icon: Icons.contacts_outlined, label: t.settingImport),
          _ComingSoonTile(icon: Icons.info_outline, label: t.settingAbout),
          const Divider(height: 24),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error),
            title: Text(t.clearData,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }

  Future<void> _clearData() async {
    final t = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.clearData),
        content: Text(t.clearDataConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.actionCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.actionClear)),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.clearAll(selfName: t.tabMe);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.clearDataDone)),
      );
    }
  }
}

class _SelfCard extends StatelessWidget {
  const _SelfCard({this.person});
  final Person? person;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    if (person == null) {
      return Padding(
        padding: const EdgeInsets.all(Dim.pad),
        child: Text(t.meNoSelf,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      );
    }
    final p = person!;
    final age = p.ageAt(DateTime.now());
    final meta = [
      if (p.customAppellation != null) p.customAppellation!,
      if (age != null) t.ageYears(age),
    ].join(' · ');
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Dim.pad, vertical: 8),
      leading: Avatar(name: p.name, photoPath: p.photoPath, radius: 28),
      title: Text(p.displayName, style: theme.textTheme.titleLarge),
      subtitle: meta.isEmpty ? null : Text(meta),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PersonDetailPage(personId: p.id)),
      ),
    );
  }
}

class _Reminder {
  _Reminder({
    required this.person,
    required this.days,
    required this.isBirthday,
    required this.count,
    this.anniLabel,
  });
  final Person person;
  final int days; // 距离还有几天（0 = 今天）
  final bool isBirthday;
  final int count; // 生日：将满岁数；纪念日：周年数
  final String? anniLabel;
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.item});
  final _Reminder item;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final today = item.days == 0;
    final when = today
        ? (item.isBirthday ? t.birthdayToday : t.dateToday)
        : t.birthdayInDays(item.days);
    final subtitle = item.isBirthday
        ? '${t.labelBirthday} · ${t.turnsAge(item.count)}'
        : '${item.anniLabel} · ${t.anniversaryYears(item.count)}';
    return ListTile(
      leading: Avatar(
          name: item.person.name,
          photoPath: item.person.photoPath,
          radius: 18),
      title: Text(item.person.displayName),
      subtitle: Text(subtitle),
      trailing: Text(
        when,
        style: TextStyle(
          color: today ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: today ? FontWeight.w700 : FontWeight.normal,
        ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => PersonDetailPage(personId: item.person.id)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dim.pad, 8, Dim.pad, 4),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13)),
    );
  }
}

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final ctrl = context.watch<LocaleController>();
    final code = ctrl.locale?.languageCode; // null = system
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(t.settingLanguage),
      trailing: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: 'system', label: Text(t.optionSystem)),
          const ButtonSegment(value: 'zh', label: Text('中文')),
          const ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {code ?? 'system'},
        onSelectionChanged: (s) {
          final v = s.first;
          context.read<LocaleController>().setLocale(
              v == 'system' ? null : Locale(v));
        },
      ),
    );
  }
}

class _ThemeSetting extends StatelessWidget {
  const _ThemeSetting();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsController>();
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(t.settingTheme),
      trailing: SegmentedButton<AppStyle>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: AppStyle.clean, label: Text(t.themeClean)),
          const ButtonSegment(
              value: AppStyle.play, label: Text('Material You')),
        ],
        selected: {settings.style},
        onSelectionChanged: (s) =>
            context.read<SettingsController>().setStyle(s.first),
      ),
    );
  }
}

class _DarkModeSetting extends StatelessWidget {
  const _DarkModeSetting();

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final settings = context.watch<SettingsController>();
    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: Text(t.settingAppearance),
      trailing: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(t.optionSystem)),
          ButtonSegment(value: ThemeMode.light, label: Text(t.optionLight)),
          ButtonSegment(value: ThemeMode.dark, label: Text(t.optionDark)),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (s) =>
            context.read<SettingsController>().setThemeMode(s.first),
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(context.l10n.comingSoon,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label · ${context.l10n.comingSoon}')),
      ),
    );
  }
}
