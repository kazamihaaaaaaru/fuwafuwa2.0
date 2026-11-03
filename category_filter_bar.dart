import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';

/// 顶部类目与滑动胶囊过滤栏（Category Filter Bar）
/// 严格遵循甘系（Sweet Lolita）视觉：
/// - 芭蕾舞鞋粉主高亮
/// - 奶霜杏辅助背景
/// - 巧克力深棕与灰粉棕文本
class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory; // 'all' | 'lolita' | 'earth'
  final String selectedSubCategory; // '全部' 或 具体子类目
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSubCategoryChanged;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.onCategoryChanged,
    required this.onSubCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. 主类目分段切换：全部 | Lolita | 地球人
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: FuwaColors.apricotCream,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                _buildMainTabItem('全部', 'all'),
                _buildMainTabItem('Lolita ୨୧', AppConstants.categoryLolita),
                _buildMainTabItem('地球人', AppConstants.categoryEarth),
              ],
            ),
          ),
        ),

        // 2. 滑动胶囊子类目过滤
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _currentSubCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final subCat = _currentSubCategories[index];
              final isSelected = selectedSubCategory == subCat;

              return GestureDetector(
                onTap: () => onSubCategoryChanged(subCat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? FuwaColors.balletPink : FuwaColors.pureWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? FuwaColors.balletPink : FuwaColors.subtleBorder,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: FuwaColors.balletPink.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    subCat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : FuwaColors.chocolateDark,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabItem(String label, String categoryKey) {
    final isSelected = selectedCategory == categoryKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          onCategoryChanged(categoryKey);
          onSubCategoryChanged('全部'); // 切换主分类时重置子分类为全部
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? FuwaColors.pureWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: FuwaColors.softGlowPink.withOpacity(0.6),
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
              color: isSelected ? FuwaColors.balletPink : FuwaColors.mutedRosyBrown,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<String> get _currentSubCategories {
    if (selectedCategory == AppConstants.categoryLolita) {
      return ['全部', ...AppConstants.lolitaSubCategories];
    } else if (selectedCategory == AppConstants.categoryEarth) {
      return ['全部', ...AppConstants.earthSubCategories];
    }
    // 全部模式下聚合所有子分类
    return ['全部', 'JSK', 'OP', 'SK', '连衣裙', '上衣', '外套', '其他'];
  }
}
