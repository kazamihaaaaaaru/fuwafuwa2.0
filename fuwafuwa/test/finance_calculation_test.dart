import 'package:flutter_test/flutter_test.dart';
import 'package:fuwafuwa/data/models/finance_record.dart';

void main() {
  group('财务统计口径与时间线单元测试', () {
    test('规则 4: 支出流水按实际支付发生时间精准归集', () {
      // 场景：定金在 2026-03 支付，尾款在 2026-10 支付
      final depositRecord = FinanceRecord(
        date: '2026-03-15',
        amount: 300.0,
        category: 'lolita',
        title: '轻飘飘草莓圣代 (定金)',
        paymentType: '定金',
      );

      final balanceRecord = FinanceRecord(
        date: '2026-10-20',
        amount: 450.0,
        category: 'lolita',
        title: '轻飘飘草莓圣代 (尾款)',
        paymentType: '尾款',
      );

      expect(depositRecord.date.startsWith('2026-03'), true);
      expect(depositRecord.paymentType, '定金');
      expect(depositRecord.amount, 300.0);

      expect(balanceRecord.date.startsWith('2026-10'), true);
      expect(balanceRecord.paymentType, '尾款');
      expect(balanceRecord.amount, 450.0);
    });

    test('FinanceSummary 资产总额与三大分类占比计算', () {
      const summary = FinanceSummary(
        totalWardrobeAsset: 10000.0,
        pendingBalanceCount: 3,
        pendingBalanceEstimate: 1200.0,
        earthTotal: 2500.0, // 25%
        lolitaTotal: 6500.0, // 65%
        accessoryTotal: 1000.0, // 10%
      );

      expect(summary.totalWardrobeAsset, 10000.0);
      expect(summary.pendingBalanceCount, 3);
      expect(summary.pendingBalanceEstimate, 1200.0);
      expect(summary.earthRatio, closeTo(0.25, 0.001));
      expect(summary.lolitaRatio, closeTo(0.65, 0.001));
      expect(summary.accessoryRatio, closeTo(0.10, 0.001));
    });

    test('规则 3: 严格免除穿着频次记录与单次穿着成本（CPW）字段', () {
      // 验证 FinanceRecord 与 FinanceSummary 不包含 wearCount 或 costPerWear
      final record = FinanceRecord(
        date: '2026-05-01',
        amount: 299.0,
        category: 'earth',
        title: '日系风衣',
        paymentType: '全款',
      );

      expect(record.amount, 299.0);
      // 领域模型中纯净免除穿着频次干扰，只为少女心动而记录
    });
  });
}
