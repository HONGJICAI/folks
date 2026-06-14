// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Folks';

  @override
  String get tabFamily => 'Family';

  @override
  String get tabCircle => 'Circle';

  @override
  String get tabMemory => 'Memories';

  @override
  String get searchHint => 'Search people & memories';

  @override
  String get searchNoResults => 'No matches';

  @override
  String get searchSectionPeople => 'People';

  @override
  String get eventTagsHint => 'Spring Festival  Trip';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionExport => 'Export';

  @override
  String get familyEmpty =>
      'No family members yet.\nTap + to start from \"Me\".';

  @override
  String get addFamilyMember => 'Add family member';

  @override
  String get swapPrimary => 'Swap main / partner';

  @override
  String get viewList => 'List';

  @override
  String get viewTree => 'Tree';

  @override
  String get circleEmpty => 'No friends yet.\nTap + to add and tag them.';

  @override
  String get addFriend => 'Add friend';

  @override
  String get ungrouped => 'Ungrouped';

  @override
  String get memoryEmpty =>
      'No memories yet.\nRecord a gift, a gathering or a milestone.';

  @override
  String get recordEntry => 'New entry';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get filterAll => 'All';

  @override
  String filterUnlinked(int count) {
    return 'Unlinked ($count)';
  }

  @override
  String monthHeader(int year, int month) {
    return '$month/$year';
  }

  @override
  String get personGone => 'This member no longer exists.';

  @override
  String get relationFather => 'Father';

  @override
  String get relationMother => 'Mother';

  @override
  String get relationSpouse => 'Spouse';

  @override
  String get relationNone => 'None';

  @override
  String get exchangesTitle => 'Exchanges';

  @override
  String get youGave => 'You gave';

  @override
  String get youReceived => 'You received';

  @override
  String get timelineTitle => 'Exchanges & memories';

  @override
  String noRecordsWith(String name) {
    return 'No records with $name yet.';
  }

  @override
  String get deleteMemberTitle => 'Delete member';

  @override
  String deleteMemberBody(String name) {
    return 'Delete \"$name\"? Their family / spouse links will be removed, and they\'ll be unlinked from memories.';
  }

  @override
  String get editProfile => 'Edit profile';

  @override
  String get fieldRealName => 'Full name *';

  @override
  String get validateName => 'Please enter a name';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String get fieldAppellation => 'Custom appellation (e.g. Big Cousin)';

  @override
  String get fieldPhone => 'Phone';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldBirthday => 'Birthday';

  @override
  String get valueNotSet => 'Not set';

  @override
  String get fieldTags => 'Tags (space or comma separated)';

  @override
  String get fieldTagsHint => 'college roommate  cycling buddy';

  @override
  String get fieldMemo => 'Notes';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderUnknown => 'Unknown';

  @override
  String ageYears(int age) {
    return '$age yo';
  }

  @override
  String get fieldEventTitle => 'Title *';

  @override
  String get fieldEventTitleHint => 'e.g. Big Cousin\'s wedding gift';

  @override
  String get validateTitle => 'Please enter a title';

  @override
  String get fieldOccurDate => 'Date';

  @override
  String get dirExpense => 'Expense';

  @override
  String get dirIncome => 'Income';

  @override
  String get giftGiven => 'Gift given';

  @override
  String get giftReceived => 'Gift received';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get relatedPeople => 'Linked people';

  @override
  String get relatedPeopleReq => 'Linked people *';

  @override
  String get relatedPeopleHint =>
      'Multi-select; the entry appears on each person\'s timeline.';

  @override
  String get atLeastOnePerson => 'Please link at least one person.';

  @override
  String get sectionPhotos => 'Photos';

  @override
  String get fieldJournal => 'Journal';

  @override
  String get noLinkedMembers => 'No linked members';

  @override
  String get eventGone => 'This entry no longer exists.';

  @override
  String get deleteEntryTitle => 'Delete entry';

  @override
  String deleteEntryBody(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get typeMaterial => 'Gift / money';

  @override
  String get typeExperience => 'Shared experience';

  @override
  String get typeMilestone => 'Milestone';

  @override
  String get cantOpenImage => 'Can\'t open this image';

  @override
  String pageIndicator(int index, int total) {
    return '$index / $total';
  }
}
