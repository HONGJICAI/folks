/// 与某个人的人情往来差额清算结果 —— 详情页顶部「净人情往来」面板用。
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

  /// 净往来：正数表示你净收入（顺差），负数表示你净支出（逆差）。
  double get net => totalIncome - totalExpense;

  bool get isDeficit => net < 0; // 逆差（你给出更多）
  bool get isSurplus => net > 0; // 顺差（你收到更多）

  /// 一句话爽点文案，如「历史你支出 5,000 元，收到回礼 3,000 元。当前净人情往来：逆差 2,000 元」。
  String summaryText() {
    final dir = isDeficit ? '逆差' : (isSurplus ? '顺差' : '持平');
    final absNet = net.abs();
    return '历史你支出 ${_fmt(totalExpense)} 元，收到回礼 ${_fmt(totalIncome)} 元。'
        '当前净人情往来：$dir ${_fmt(absNet)} 元';
  }

  static String _fmt(double v) {
    // 千分位整数显示（金额一般为整数元）。
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
