import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Folks'**
  String get appTitle;

  /// No description provided for @tabFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tabFamily;

  /// No description provided for @tabCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get tabCircle;

  /// No description provided for @tabMemory.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get tabMemory;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @optionSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get optionSystem;

  /// No description provided for @optionLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get optionLight;

  /// No description provided for @optionDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get optionDark;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// No description provided for @themeClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get themeClean;

  /// No description provided for @settingAppearance.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingAppearance;

  /// No description provided for @settingAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingAppLock;

  /// No description provided for @settingBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & export'**
  String get settingBackup;

  /// No description provided for @settingImport.
  ///
  /// In en, this message translates to:
  /// **'Import from contacts'**
  String get settingImport;

  /// No description provided for @settingAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingAbout;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @meNoSelf.
  ///
  /// In en, this message translates to:
  /// **'No \"Me\" set yet. Open a family member and mark them as you.'**
  String get meNoSelf;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search people & memories'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get searchNoResults;

  /// No description provided for @searchSectionPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get searchSectionPeople;

  /// No description provided for @eventTagsHint.
  ///
  /// In en, this message translates to:
  /// **'Spring Festival  Trip'**
  String get eventTagsHint;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @familyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No family members yet.\nTap + to start from \"Me\".'**
  String get familyEmpty;

  /// No description provided for @addFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Add family member'**
  String get addFamilyMember;

  /// No description provided for @swapPrimary.
  ///
  /// In en, this message translates to:
  /// **'Swap main / partner'**
  String get swapPrimary;

  /// No description provided for @viewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get viewList;

  /// No description provided for @viewTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get viewTree;

  /// No description provided for @circleEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.\nTap + to add and tag them.'**
  String get circleEmpty;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @ungrouped.
  ///
  /// In en, this message translates to:
  /// **'Ungrouped'**
  String get ungrouped;

  /// No description provided for @memoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memories yet.\nRecord a gift, a gathering or a milestone.'**
  String get memoryEmpty;

  /// No description provided for @recordEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get recordEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked ({count})'**
  String filterUnlinked(int count);

  /// No description provided for @monthHeader.
  ///
  /// In en, this message translates to:
  /// **'{month}/{year}'**
  String monthHeader(int year, int month);

  /// No description provided for @personGone.
  ///
  /// In en, this message translates to:
  /// **'This member no longer exists.'**
  String get personGone;

  /// No description provided for @relationFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get relationFather;

  /// No description provided for @relationMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get relationMother;

  /// No description provided for @relationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationSpouse;

  /// No description provided for @sectionChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get sectionChildren;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @addFather.
  ///
  /// In en, this message translates to:
  /// **'Add father'**
  String get addFather;

  /// No description provided for @addMother.
  ///
  /// In en, this message translates to:
  /// **'Add mother'**
  String get addMother;

  /// No description provided for @addSpouse.
  ///
  /// In en, this message translates to:
  /// **'Add spouse'**
  String get addSpouse;

  /// No description provided for @removeLink.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLink;

  /// No description provided for @chooseParentRole.
  ///
  /// In en, this message translates to:
  /// **'Is this parent the father or mother?'**
  String get chooseParentRole;

  /// No description provided for @exchangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchanges'**
  String get exchangesTitle;

  /// No description provided for @youGave.
  ///
  /// In en, this message translates to:
  /// **'You gave'**
  String get youGave;

  /// No description provided for @youReceived.
  ///
  /// In en, this message translates to:
  /// **'You received'**
  String get youReceived;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchanges & memories'**
  String get timelineTitle;

  /// No description provided for @noRecordsWith.
  ///
  /// In en, this message translates to:
  /// **'No records with {name} yet.'**
  String noRecordsWith(String name);

  /// No description provided for @deleteMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete member'**
  String get deleteMemberTitle;

  /// No description provided for @deleteMemberBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Their family / spouse links will be removed, and they\'ll be unlinked from memories.'**
  String deleteMemberBody(String name);

  /// No description provided for @markAsSelf.
  ///
  /// In en, this message translates to:
  /// **'This is me'**
  String get markAsSelf;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @fieldDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name *'**
  String get fieldDisplayName;

  /// No description provided for @fieldRealName.
  ///
  /// In en, this message translates to:
  /// **'Real name (optional)'**
  String get fieldRealName;

  /// No description provided for @validateName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get validateName;

  /// No description provided for @fieldNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get fieldNickname;

  /// No description provided for @fieldAppellation.
  ///
  /// In en, this message translates to:
  /// **'Custom appellation (e.g. Big Cousin)'**
  String get fieldAppellation;

  /// No description provided for @fieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get fieldPhone;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get fieldBirthday;

  /// No description provided for @labelYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get labelYear;

  /// No description provided for @labelMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get labelMonth;

  /// No description provided for @labelDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get labelDay;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (space or comma separated)'**
  String get fieldTags;

  /// No description provided for @fieldTagsHint.
  ///
  /// In en, this message translates to:
  /// **'college roommate  cycling buddy'**
  String get fieldTagsHint;

  /// No description provided for @fieldMemo.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldMemo;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get genderUnknown;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'{age} yo'**
  String ageYears(int age);

  /// No description provided for @fieldEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get fieldEventTitle;

  /// No description provided for @fieldEventTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Big Cousin\'s wedding gift'**
  String get fieldEventTitleHint;

  /// No description provided for @validateTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get validateTitle;

  /// No description provided for @fieldOccurDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldOccurDate;

  /// No description provided for @dirExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dirExpense;

  /// No description provided for @dirIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dirIncome;

  /// No description provided for @giftGiven.
  ///
  /// In en, this message translates to:
  /// **'Gift given'**
  String get giftGiven;

  /// No description provided for @giftReceived.
  ///
  /// In en, this message translates to:
  /// **'Gift received'**
  String get giftReceived;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @relatedPeople.
  ///
  /// In en, this message translates to:
  /// **'Linked people'**
  String get relatedPeople;

  /// No description provided for @relatedPeopleReq.
  ///
  /// In en, this message translates to:
  /// **'Linked people *'**
  String get relatedPeopleReq;

  /// No description provided for @relatedPeopleHint.
  ///
  /// In en, this message translates to:
  /// **'Multi-select; the entry appears on each person\'s timeline.'**
  String get relatedPeopleHint;

  /// No description provided for @atLeastOnePerson.
  ///
  /// In en, this message translates to:
  /// **'Please link at least one person.'**
  String get atLeastOnePerson;

  /// No description provided for @sectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get sectionPhotos;

  /// No description provided for @fieldJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get fieldJournal;

  /// No description provided for @noLinkedMembers.
  ///
  /// In en, this message translates to:
  /// **'No linked members'**
  String get noLinkedMembers;

  /// No description provided for @eventGone.
  ///
  /// In en, this message translates to:
  /// **'This entry no longer exists.'**
  String get eventGone;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get deleteEntryTitle;

  /// No description provided for @deleteEntryBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteEntryBody(String title);

  /// No description provided for @typeMaterial.
  ///
  /// In en, this message translates to:
  /// **'Gift / money'**
  String get typeMaterial;

  /// No description provided for @typeExperience.
  ///
  /// In en, this message translates to:
  /// **'Shared experience'**
  String get typeExperience;

  /// No description provided for @typeMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get typeMilestone;

  /// No description provided for @cantOpenImage.
  ///
  /// In en, this message translates to:
  /// **'Can\'t open this image'**
  String get cantOpenImage;

  /// No description provided for @pageIndicator.
  ///
  /// In en, this message translates to:
  /// **'{index} / {total}'**
  String pageIndicator(int index, int total);

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String daysAgo(int n);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}mo ago'**
  String monthsAgo(int n);

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{n}y ago'**
  String yearsAgo(int n);

  /// No description provided for @sectionReminders.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get sectionReminders;

  /// No description provided for @labelBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get labelBirthday;

  /// No description provided for @anniversaryYears.
  ///
  /// In en, this message translates to:
  /// **'{n} yr'**
  String anniversaryYears(int n);

  /// No description provided for @remindBirthday.
  ///
  /// In en, this message translates to:
  /// **'Remind on birthday'**
  String get remindBirthday;

  /// No description provided for @sectionAnniversaries.
  ///
  /// In en, this message translates to:
  /// **'Anniversaries'**
  String get sectionAnniversaries;

  /// No description provided for @addAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Add anniversary'**
  String get addAnniversary;

  /// No description provided for @anniversaryLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Wedding anniversary'**
  String get anniversaryLabelHint;

  /// No description provided for @sectionUpcomingBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Upcoming birthdays'**
  String get sectionUpcomingBirthdays;

  /// No description provided for @birthdayToday.
  ///
  /// In en, this message translates to:
  /// **'Birthday today!'**
  String get birthdayToday;

  /// No description provided for @birthdayInDays.
  ///
  /// In en, this message translates to:
  /// **'in {n} days'**
  String birthdayInDays(int n);

  /// No description provided for @turnsAge.
  ///
  /// In en, this message translates to:
  /// **'turns {age}'**
  String turnsAge(int age);

  /// No description provided for @toastSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get toastSaved;

  /// No description provided for @toastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get toastDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
