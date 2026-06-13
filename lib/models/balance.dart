/// 与某个人的人情往来汇总 —— 详情页「人情往来」面板用。
///
/// 只呈现客观的"支出 / 收到"总额，不做顺差/逆差这类带金钱判断的措辞。
library;

class PersonBalance {
  /// 你收到的总额（对方给你的回礼 / 红包）。
  final double totalIncome;

  /// 你支出的总额（你随的礼 / 给出的）。
  final double totalExpense;

  const PersonBalance({
    this.totalIncome = 0,
    this.totalExpense = 0,
  });

  bool get hasAny => totalIncome > 0 || totalExpense > 0;
}
