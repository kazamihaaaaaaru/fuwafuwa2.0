import 'package:flutter/material.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/item.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/fuwa_animations.dart';
import '../widgets/polaroid_card.dart';

/// Tab 1: 首页·衣柜照片墙 (`HomeScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 草莓奶霜白底色（#FDF8F9）
/// - 双列拍立得相纸卡片瀑布流（FuwaBounceCard 弹性按压）
/// - 顶部全部 / Lolita / 地球人与滑动胶囊子类目过滤
/// - 右上角悬浮工期/等待状态金平糖金微光呼吸徽章
/// - 芭蕾舞鞋粉蝴蝶结缎带悬浮操作按钮（FuwaBreathingRibbon 呼吸动效）
class HomeScreen extends StatefulWidget {
  final VoidCallback? onAddTap;
  final ValueChanged<Item>? onItemTap;

  const HomeScreen({
    super.key,
    this.onAddTap,
    this.onItemTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _selectedCategory = 'all'; // 'all' | 'lolita' | 'earth'
  String _selectedSubCategory = '全部';
  String _searchQuery = '';
  bool _isLoading = true;
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 从 SQLite 本地数据库加载单品列表
  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      final categoryFilter = _selectedCategory == 'all' ? null : _selectedCategory;
      final subCategoryFilter = _selectedSubCategory == '全部' ? null : _selectedSubCategory;

      final result = await _dbHelper.getAllItems(
        category: categoryFilter,
        subCategory: subCategoryFilter,
        searchQuery: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _items = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. 顶部艺术标题区与搜索栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题与轻飘飘标语
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ふわふわ ୨୧',
                                style: TextStyle(
                                  color: FuwaColors.chocolateDark,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '在廉价的生活里做着轻飘飘的少女梦',
                                style: TextStyle(
                                  color: FuwaColors.mutedRosyBrown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // 顶部右上角衣柜件数微标
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: FuwaColors.pureWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: FuwaColors.softCardShadow,
                              border: Border.all(color: FuwaColors.subtleBorder),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  FuwaColors.ribbonSymbol,
                                  style: TextStyle(
                                    color: FuwaColors.balletPink,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_items.length} 件',
                                  style: const TextStyle(
                                    color: FuwaColors.chocolateDark,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 搜索输入框
                      _buildSearchField(),
                    ],
                  ),
                ),
              ),

              // 2. 类别切换与滑动胶囊过滤栏（吸顶效果）
              SliverToBoxAdapter(
                child: CategoryFilterBar(
                  selectedCategory: _selectedCategory,
                  selectedSubCategory: _selectedSubCategory,
                  onCategoryChanged: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedSubCategory = '全部';
                    });
                    _loadItems();
                  },
                  onSubCategoryChanged: (subCat) {
                    setState(() => _selectedSubCategory = subCat);
                    _loadItems();
                  },
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            color: FuwaColors.balletPink,
            backgroundColor: FuwaColors.pureWhite,
            onRefresh: _loadItems,
            child: _buildBodyContent(),
          ),
        ),
      ),
      // 芭蕾舞鞋粉缎带蝴蝶结悬浮按钮 (FAB)，带有轻柔呼吸律动
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 搜索输入框构建
  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: FuwaColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: FuwaColors.softCardShadow,
        border: Border.all(color: FuwaColors.subtleBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: FuwaColors.mutedRosyBrown,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: FuwaColors.balletPink,
              style: const TextStyle(
                color: FuwaColors.chocolateDark,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: '搜索单品名称、Lolita 店铺...',
                hintStyle: TextStyle(
                  color: FuwaColors.mutedRosyBrown,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                _searchQuery = val;
                _loadItems();
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _searchQuery = '';
                _loadItems();
              },
              child: const Icon(
                Icons.cancel_rounded,
                size: 18,
                color: FuwaColors.mutedRosyBrown,
              ),
            ),
        ],
      ),
    );
  }

  /// 核心内容区：加载中、空状态、双列拍立得照片流
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: FuwaColors.balletPink,
        ),
      );
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    // 双列拍立得卡片网格照片流
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.63,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return PolaroidCard(
          item: item,
          onTap: () async {
            if (widget.onItemTap != null) {
              widget.onItemTap!(item);
            }
          },
        );
      },
    );
  }

  /// 甘系少女梦境空状态
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            decoration: BoxDecoration(
              color: FuwaColors.pureWhite,
              borderRadius: FuwaColors.roundedCardRadius,
              boxShadow: FuwaColors.softCardShadow,
              border: Border.all(color: FuwaColors.subtleBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  FuwaColors.ribbonSymbol,
                  style: TextStyle(
                    color: FuwaColors.balletPink,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '衣柜里空空如也 ୨୧',
                  style: TextStyle(
                    color: FuwaColors.chocolateDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '快去放入第一件轻飘飘的裙子吧～\n点击右下方粉色小缎带按钮开始录入',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: FuwaColors.mutedRosyBrown,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: widget.onAddTap,
                  icon: const Text(
                    FuwaColors.ribbonSymbol,
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  label: const Text(
                    '立即录入',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FuwaColors.balletPink,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 悬浮操作按钮（FAB）：芭蕾舞鞋粉 + 蝴蝶结小缎带呼吸微动效
  Widget _buildFloatingActionButton() {
    return FuwaBreathingRibbon(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: FuwaColors.balletPink.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: widget.onAddTap,
          backgroundColor: FuwaColors.balletPink,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Text(
            FuwaColors.ribbonSymbol,
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
