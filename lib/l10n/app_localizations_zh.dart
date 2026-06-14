// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Folks 身边人';

  @override
  String get tabFamily => '家族';

  @override
  String get tabCircle => '圈子';

  @override
  String get tabMemory => '回忆';

  @override
  String get tabMe => '我';

  @override
  String get settingsSection => '设置';

  @override
  String get settingLanguage => '语言';

  @override
  String get optionSystem => '跟随系统';

  @override
  String get optionLight => '浅色';

  @override
  String get optionDark => '深色';

  @override
  String get settingTheme => '主题风格';

  @override
  String get themeClean => '清爽';

  @override
  String get settingAppearance => '深色模式';

  @override
  String get settingAppLock => '应用锁';

  @override
  String get settingBackup => '备份与导出';

  @override
  String get settingImport => '从通讯录导入';

  @override
  String get settingAbout => '关于';

  @override
  String get comingSoon => '待实现';

  @override
  String get meNoSelf => '还没设置\"我\"。打开某位家族成员，把 TA 标记为你自己。';

  @override
  String get searchHint => '搜索身边人与回忆';

  @override
  String get searchNoResults => '没有匹配项';

  @override
  String get searchSectionPeople => '人物';

  @override
  String get eventTagsHint => '春节 旅行';

  @override
  String get actionSave => '保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionDelete => '删除';

  @override
  String get actionEdit => '编辑';

  @override
  String get actionAdd => '添加';

  @override
  String get actionExport => '导出';

  @override
  String get familyEmpty => '还没有家族成员\n点右下角从\"我\"开始添加';

  @override
  String get addFamilyMember => '添加家族成员';

  @override
  String get swapPrimary => '主副对调';

  @override
  String get viewList => '列表';

  @override
  String get viewTree => '族谱';

  @override
  String get circleEmpty => '还没有朋友\n点右下角添加，并打上标签归类';

  @override
  String get addFriend => '添加朋友';

  @override
  String get ungrouped => '未分组';

  @override
  String get memoryEmpty => '还没有回忆\n记下一次随礼、一次聚会或一个里程碑';

  @override
  String get recordEntry => '记一笔';

  @override
  String get editEntry => '编辑记录';

  @override
  String get filterAll => '全部';

  @override
  String filterUnlinked(int count) {
    return '无关联 ($count)';
  }

  @override
  String monthHeader(int year, int month) {
    return '$year年$month月';
  }

  @override
  String get personGone => '该成员已不存在';

  @override
  String get relationFather => '父亲';

  @override
  String get relationMother => '母亲';

  @override
  String get relationSpouse => '配偶';

  @override
  String get relationNone => '无';

  @override
  String get exchangesTitle => '人情往来';

  @override
  String get youGave => '你支出';

  @override
  String get youReceived => '你收到';

  @override
  String get timelineTitle => '往来与回忆';

  @override
  String noRecordsWith(String name) {
    return '还没有与 $name 的往来记录';
  }

  @override
  String get deleteMemberTitle => '删除成员';

  @override
  String deleteMemberBody(String name) {
    return '确定删除「$name」吗？\n与 TA 的亲属/配偶关系会被解除，回忆记录里也会移除 TA。';
  }

  @override
  String get markAsSelf => '这是我自己';

  @override
  String get editProfile => '编辑资料';

  @override
  String get fieldDisplayName => '显示名 *';

  @override
  String get fieldRealName => '真名（选填）';

  @override
  String get validateName => '请填写名字';

  @override
  String get fieldNickname => '小名 / 乳名';

  @override
  String get fieldAppellation => '自定义称呼（如 大表姐）';

  @override
  String get fieldPhone => '电话';

  @override
  String get fieldEmail => '邮箱';

  @override
  String get fieldBirthday => '生日';

  @override
  String get labelYear => '年';

  @override
  String get labelMonth => '月';

  @override
  String get labelDay => '日';

  @override
  String get valueNotSet => '未填写';

  @override
  String get fieldTags => '标签（空格或逗号分隔）';

  @override
  String get fieldTagsHint => '大学室友 骑行搭子';

  @override
  String get fieldMemo => '备注';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderUnknown => '未知';

  @override
  String ageYears(int age) {
    return '$age 岁';
  }

  @override
  String get fieldEventTitle => '事件标题 *';

  @override
  String get fieldEventTitleHint => '如 大表姐结婚随礼';

  @override
  String get validateTitle => '请填写标题';

  @override
  String get fieldOccurDate => '发生日期';

  @override
  String get dirExpense => '支出';

  @override
  String get dirIncome => '收入';

  @override
  String get giftGiven => '送出';

  @override
  String get giftReceived => '收到';

  @override
  String get fieldAmount => '金额';

  @override
  String get relatedPeople => '关联的人';

  @override
  String get relatedPeopleReq => '关联的人 *';

  @override
  String get relatedPeopleHint => '可多选；记录会出现在每个人的时光轴里';

  @override
  String get atLeastOnePerson => '请至少关联一个人';

  @override
  String get sectionPhotos => '照片';

  @override
  String get fieldJournal => '手记';

  @override
  String get noLinkedMembers => '无关联成员';

  @override
  String get eventGone => '该记录已不存在';

  @override
  String get deleteEntryTitle => '删除记录';

  @override
  String deleteEntryBody(String title) {
    return '确定删除「$title」吗？';
  }

  @override
  String get typeMaterial => '物质往来';

  @override
  String get typeExperience => '共同经历';

  @override
  String get typeMilestone => '重要里程碑';

  @override
  String get cantOpenImage => '无法打开该图片';

  @override
  String pageIndicator(int index, int total) {
    return '$index / $total';
  }

  @override
  String get dateToday => '今天';

  @override
  String get dateYesterday => '昨天';

  @override
  String daysAgo(int n) {
    return '$n天前';
  }

  @override
  String monthsAgo(int n) {
    return '$n个月前';
  }

  @override
  String yearsAgo(int n) {
    return '$n年前';
  }

  @override
  String get sectionReminders => '近期提醒';

  @override
  String get labelBirthday => '生日';

  @override
  String anniversaryYears(int n) {
    return '$n 周年';
  }

  @override
  String get remindBirthday => '提醒生日';

  @override
  String get sectionAnniversaries => '纪念日';

  @override
  String get addAnniversary => '添加纪念日';

  @override
  String get anniversaryLabelHint => '如 结婚纪念日';

  @override
  String get sectionUpcomingBirthdays => '近期生日';

  @override
  String get birthdayToday => '今天生日！';

  @override
  String birthdayInDays(int n) {
    return '还有$n天';
  }

  @override
  String turnsAge(int age) {
    return '将满$age岁';
  }

  @override
  String get toastSaved => '已保存';

  @override
  String get toastDeleted => '已删除';
}
