import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';

/// 地球人常服双排同级滑动胶囊联动筛选栏
/// 第一排：服装与配饰子类目（上衣/下装/连衣裙/鞋/袜/帽子/包/伞等）
/// 第二排：季节标签（春/夏/秋/冬/四季通用）
/// 支持两排交集联动，并提供一键重置小缎带微标
class EarthFilterBar extends StatelessWidget {
  final String selectedSubCategory;
  final String selectedSeason;
  final ValueChanged<String> onSubCategoryChanged;
  final ValueChanged<String> onSeasonChanged;
  final VoidCallback onReset;

  const EarthFilterBar({
    super.key,
    required this.selectedSubCategory,
    required this.selectedSeason,
    required this.onSubCategoryChanged,
    required this.onSeasonChanged,
    required this.onReset,
  });

  bool get isFiltered =>
      selectedSubCategory != '全部' || selectedSeason != '全部季节';

  @override
  Widget build(BuildContext context) {
    final subCats = ['全部', ...AppConstants.earthSubCategories];
    final seasons = ['全部季节', ...AppConstants.seasons];

    return Column(
      children: [
        // 第一排：子类目胶囊栏 + 重置微标
        SizedBox(
          height: 38,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: subCats.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = subCats[index];
                    final isSel = selectedSubCategory == item;
                    return _buildChip(
                      label: item,
                      isSelected: isSel,
                      onTap: () => onSubCategoryChanged(item),
                    );
                  },
                ),
              ),
              // 若开启过滤，显示一键重置小缎带按钮
              if (isFiltered)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: onReset,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: FuwaColors.apricotCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FuwaColors.balletPink.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            FuwaColors.ribbonSymbol,
                            style: TextStyle(color: FuwaColors.balletPink, fontSize: 10),
                          ),
                          SizedBox(width: 3),
                          Text(
                            '重置',
                            style: TextStyle(
                              color: FuwaColors.chocolateDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 第二排：季节标签胶囊栏
        SizedBox(
          height: 34,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final s = seasons[index];
              final isSel = selectedSeason == s;
              return _buildChip(
                label: s,
                isSelected: isSel,
                onTap: () => onSeasonChanged(s),
                isSecondary: true,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    final activeColor = isSecondary ? FuwaColors.sugarCandyGold : FuwaColors.balletPink;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : FuwaColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? activeColor : FuwaColors.subtleBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FuwaColors.chocolateDark,
            fontSize: isSecondary ? 11 : 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
