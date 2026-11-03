import 'package:flutter_test/flutter_test.dart';
import 'package:fuwafuwa/data/models/accessory.dart';
import 'package:fuwafuwa/data/models/item.dart';

void main() {
  group('Item 领域模型与业务逻辑单元测试', () {
    test('规则 1: 全款现货单品总支出应等于 fullPrice', () {
      const earthItem = Item(
        category: 'earth',
        subCategory: '连衣裙',
        name: '法式碎花裙',
        fullPrice: 299.0,
        isDepositType: false,
      );

      expect(earthItem.totalCost, 299.0);
      expect(earthItem.isPendingBalance, false);
      expect(earthItem.isCompletedBalance, false);
      expect(earthItem.durationBadgeText, isNull);
    });

    test('规则 1: 定金尾款制单品总支出应等于 depositPrice + balancePrice', () {
      const lolitaPending = Item(
        category: 'lolita',
        subCategory: 'JSK',
        name: '轻飘飘草莓圣代',
        isDepositType: true,
        depositPrice: 300.0,
        balancePrice: 0.0,
      );

      // 待补款状态下实付为定金 300
      expect(lolitaPending.totalCost, 300.0);
      expect(lolitaPending.isPendingBalance, true);
      expect(lolitaPending.isCompletedBalance, false);

      const lolitaCompleted = Item(
        category: 'lolita',
        subCategory: 'JSK',
        name: '轻飘飘草莓圣代',
        isDepositType: true,
        depositPrice: 300.0,
        balancePrice: 450.0,
        balanceDate: '2026-10-15',
      );

      // 已补款状态下总支出为 300 + 450 = 750
      expect(lolitaCompleted.totalCost, 750.0);
      expect(lolitaCompleted.isPendingBalance, false);
      expect(lolitaCompleted.isCompletedBalance, true);
    });

    test('规则 2: 待补尾款状态应正确计算等待天数并展示“已等 X 天”', () {
      // 假设 30 天前支付定金
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final dateStr = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';

      final item = Item(
        category: 'lolita',
        subCategory: 'OP',
        name: '古典蕾丝洋装',
        isDepositType: true,
        depositPrice: 200.0,
        depositDate: dateStr,
        expectedDate: '2026-12-01',
      );

      expect(item.isPendingBalance, true);
      expect(item.waitingDays, inInclusiveRange(29, 31));
      expect(item.durationBadgeText, contains('已等'));
      expect(item.durationBadgeText, contains('天'));
    });

    test('规则 2: 已补尾款状态应计算 balanceDate 与 depositDate 之差并展示“工期 X 天”', () {
      const item = Item(
        category: 'lolita',
        subCategory: 'JSK',
        name: '玩偶嘉年华',
        isDepositType: true,
        depositPrice: 300.0,
        depositDate: '2026-03-01',
        balancePrice: 500.0,
        balanceDate: '2026-05-30', // 差值 90 天
      );

      expect(item.isCompletedBalance, true);
      expect(item.waitingDays, 90);
      expect(item.durationBadgeText, '工期 90 天');
    });

    test('序列化与反序列化（toMap / fromMap）数据完整性', () {
      final item = Item(
        id: 1,
        category: 'lolita',
        subCategory: 'JSK',
        name: '小猫下午茶',
        shopName: 'Angelic Dream',
        isDepositType: true,
        depositPrice: 280.0,
        depositDate: '2026-04-10',
        balancePrice: 420.0,
        balanceDate: '2026-07-20',
        expectedDate: '2026-07-15',
        associatedAccessories: const [
          Accessory(id: 10, name: '猫耳边夹', accessoryType: '边夹', price: 68.0),
        ],
      );

      final map = item.toMap();
      expect(map['id'], 1);
      expect(map['category'], 'lolita');
      expect(map['isDepositType'], 1);
      expect(map['depositPrice'], 280.0);
      expect(map['balancePrice'], 420.0);

      final restored = Item.fromMap(map, accessories: item.associatedAccessories);
      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.totalCost, 700.0);
      expect(restored.associatedAccessories.length, 1);
      expect(restored.associatedAccessories.first.name, '猫耳边夹');
    });
  });
}
