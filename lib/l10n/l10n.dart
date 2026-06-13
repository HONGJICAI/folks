import 'package:flutter/widgets.dart';

import '../models/event.dart';
import '../models/person.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// 便捷取本地化：`context.l10n.xxx`。
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// 枚举的本地化文案（保持 model 不依赖 i18n）。
extension GenderL10n on Gender {
  String label(AppLocalizations t) => switch (this) {
        Gender.male => t.genderMale,
        Gender.female => t.genderFemale,
        Gender.unknown => t.genderUnknown,
      };
}

extension PersonGroupL10n on PersonGroup {
  String label(AppLocalizations t) => switch (this) {
        PersonGroup.family => t.tabFamily,
        PersonGroup.circle => t.tabCircle,
      };
}

extension EventTypeL10n on EventType {
  String label(AppLocalizations t) => switch (this) {
        EventType.material => t.typeMaterial,
        EventType.experience => t.typeExperience,
        EventType.milestone => t.typeMilestone,
      };
}

extension MoneyDirectionL10n on MoneyDirection {
  String label(AppLocalizations t) => switch (this) {
        MoneyDirection.income => t.dirIncome,
        MoneyDirection.expense => t.dirExpense,
      };
}
