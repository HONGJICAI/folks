import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../locale_controller.dart';
import '../models/person.dart';
import '../settings_controller.dart';
import '../theme/app_theme.dart';
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
  late Future<Person?> _self;

  @override
  void initState() {
    super.initState();
    _repo = context.read<FolksRepository>();
    _self = _loadSelf();
    _repo.changes.addListener(_reload);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_reload);
    super.dispose();
  }

  Future<Person?> _loadSelf() async {
    final all = await _repo.getAllPersons();
    for (final p in all) {
      if (p.isSelf) return p;
    }
    return null;
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _self = _loadSelf();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.tabMe)),
      body: ListView(
        children: [
          FutureBuilder<Person?>(
            future: _self,
            builder: (context, snap) => _SelfCard(person: snap.data),
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
        ],
      ),
    );
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
      leading: Avatar(name: p.realName, radius: 28),
      title: Text(p.displayName, style: theme.textTheme.titleLarge),
      subtitle: meta.isEmpty ? null : Text(meta),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PersonDetailPage(personId: p.id)),
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
