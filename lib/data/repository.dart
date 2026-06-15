/// 数据访问契约（Repository 接口）。
///
/// 这是 UI 与数据层之间的唯一边界：UI 全程只依赖这个抽象类。
/// MVP 早期用 [FakeRepository]（内存假数据）驱动 UI 开发；
/// 后端阶段换成 SqliteRepository 实现即可，**UI 一行都不用改**。
library;

import 'package:flutter/foundation.dart';

import '../models/balance.dart';
import '../models/event.dart';
import '../models/person.dart';

abstract class FolksRepository {
  /// 数据变更通知：任意增 / 删 / 改后触发，UI 据此刷新（跨 Tab 实时同步）。
  Listenable get changes;

  // ============ 人物（通用） ============

  Future<List<Person>> getAllPersons();
  Future<Person?> getPerson(int id);

  /// 按 Tab 分组取人：family 给家族树，circle 给圈子列表。
  Future<List<Person>> getPersonsByGroup(PersonGroup group);

  /// 按姓名 / 小名 / 标签模糊搜索。
  Future<List<Person>> searchPersons(String query);

  /// 新增人物，返回带有生成 id 的对象。
  Future<Person> addPerson(Person person);
  Future<void> updatePerson(Person person);

  /// 删除人物。需在实现中处理引用清理：
  /// 子女的 father/mother 置空、配偶的 spouse 置空、事件绑定中移除该 id。
  Future<void> deletePerson(int id);

  // ============ 家族（树状视图） ============

  /// 取某人的直接子女（fatherId 或 motherId 指向 [parentId]）。
  Future<List<Person>> getChildren(int parentId);

  /// 引导式录入：为 [childId] 添加父亲。会创建父亲并自动回填 child.fatherId。
  Future<Person> addFather(int childId, Person father);

  /// 引导式录入：为 [childId] 添加母亲。
  Future<Person> addMother(int childId, Person mother);

  /// 引导式录入：为 [parentId] 添加一个孩子（自动回填孩子的 father/mother）。
  /// [throughFather] 决定挂在父亲还是母亲名下。
  Future<Person> addChild(int parentId, Person child, {bool throughFather = true});

  /// 设置配偶关系（双向写入；并自动解除双方原有的旧配偶，避免悬挂指针）。
  Future<void> setSpouse(int aId, int bId);

  /// 解除某人的配偶关系（双向清除）。
  Future<void> clearSpouse(int personId);

  /// 保守地把某成员的「父母」关联为配偶：仅当父母双全、且双方当前都没有配偶时才连，
  /// 已有配偶（如再婚）一律不动。用于"加完父母后自动成对"的常见默认。
  Future<void> linkCoParentsIfUnset(int childId);

  /// 把某人指定为其夫妻里的"血亲主位"（marriedIn=false），配偶置为姻亲（marriedIn=true）。
  /// 家族树里"主副对调"即调用此方法把副位提升为主位。
  Future<void> setBloodPrimary(int personId);

  /// 指定"我自己"（全局唯一）：该人 isSelf=true，其余全部置 false。
  Future<void> setSelf(int personId);

  /// 清空所有人与回忆，仅保留一张空白的"我"（保住锚点）。不可撤销。
  Future<void> clearAll({required String selfName});

  // ============ 圈子（标签） ============

  /// 当前所有用过的标签（去重）。
  Future<List<String>> getAllTags();
  Future<List<Person>> getPersonsByTag(String tag);

  // ============ 回忆 / 人情往来事件 ============

  Future<List<Event>> getAllEvents();
  Future<Event?> getEvent(int id);

  /// 按标题 / 手记 / 标签模糊搜索事件（空 query 返回全部）。
  Future<List<Event>> searchEvents(String query);

  /// 所有事件用过的标签（去重排序），用于录入时的标签建议。
  Future<List<String>> getAllEventTags();

  /// 取绑定了某人的所有事件（按发生日期倒序）—— 个人时光轴。
  Future<List<Event>> getEventsByPerson(int personId);

  Future<Event> addEvent(Event event);
  Future<void> updateEvent(Event event);
  Future<void> deleteEvent(int id);

  // ============ 差额清算 ============

  /// 加总与某人的所有金钱往来，给出净人情面板数据。
  Future<PersonBalance> getBalanceWith(int personId);
}
