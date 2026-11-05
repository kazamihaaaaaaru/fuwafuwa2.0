import 'wardrobe_statistics_screen.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/fuwa_colors.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/item.dart';
import '../widgets/earth_filter_bar.dart';
import '../widgets/fuwa_animations.dart';
import '../widgets/polaroid_card.dart';
import 'item_detail_screen.dart';

/// Tab 2: 【地球人衣柜】(`EarthScreen`)
/// 严格遵循甘系（Sweet Lolita）视觉设计规范：
/// - 独立地球人常服展示
/// - 上下两排同级滑动胶囊（子类目 + 季节）交集联动筛选
/// - 包含帽子、包、伞、鞋、袜等完整常服分类
/// - 优雅拍立得相纸双列照片流
class EarthScreen extends StatefulWidget {
  final VoidCallback? onAddTap;
  final ValueChanged<Item>? onItemTap;

  const EarthScreen({
    super.key,
    this.onAddTap,
    this.onItemTap,
  });

  @override
  State<EarthScreen> createState() => _EarthScreenState();
}

class _EarthScreenState extends State<EarthScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Item> _items = [];
  String _selectedSubCat = '全部';
  String _selectedSeason = '全部季节';
  String _searchQuery = '';
  bool _isLoading = true;

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

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    final subCat = _selectedSubCat == '全部' ? null : _selectedSubCat;
    final season = _selectedSeason == '全部季节' ? null : _selectedSeason;

    final list = await _dbHelper.getAllItems(
      category: AppConstants.categoryEarth,
      subCategory: subCat,
      season: season,
      searchQuery: _searchQuery,
    );

    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedSubCat = '全部';
      _selectedSeason = '全部季节';
    });
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FuwaColors.creamWhite,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. 顶部标题与搜索栏
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '地球人衣柜 ୨୧',
                                style: TextStyle(
                                  color: FuwaColors.chocolateDark,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '在认清生活的本质后依旧热爱生活',
                                style: TextStyle(
                                  color: FuwaColors.mutedRosyBrown,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WardrobeStatisticsScreen(category: 'earth'),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: FuwaColors.pureWhite,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: FuwaColors.softCardShadow,
                                border: Border.all(color: FuwaColors.subtleBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.pie_chart_outline_rounded, size: 14, color: FuwaColors.balletPink),
                                  SizedBox(width: 4),
                                  Text(
                                    '常服统计',
                                    style: TextStyle(
                                      color: FuwaColors.chocolateDark,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                    ],
                  ),
                ),
              ),

              // 2. 双排交集滑动筛选栏（子类目 + 季节）
              SliverToBoxAdapter(
                child: EarthFilterBar(
                  selectedSubCategory: _selectedSubCat,
                  selectedSeason: _selectedSeason,
                  onSubCategoryChanged: (sub) {
                    setState(() => _selectedSubCat = sub);
                    _loadItems();
                  },
                  onSeasonChanged: (season) {
                    setState(() => _selectedSeason = season);
                    _loadItems();
                  },
                  onReset: _resetFilters,
                ),
              ),
            ];
          },
          body: RefreshIndicator(
            color: FuwaColors.balletPink,
            backgroundColor: FuwaColors.pureWhite,
            onRefresh: _loadItems,
            child: _buildBody(),
          ),
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

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
          const Icon(Icons.search_rounded, size: 20, color: FuwaColors.mutedRosyBrown),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: FuwaColors.balletPink,
              style: const TextStyle(color: FuwaColors.chocolateDark, fontSize: 13),
              decoration: const InputDecoration(
                hintText: '搜索常服名称...',
                hintStyle: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 13),
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
              child: const Icon(Icons.cancel_rounded, size: 18, color: FuwaColors.mutedRosyBrown),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FuwaColors.balletPink));
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              FuwaBreathingRibbon(
                child: Text(
                  FuwaColors.ribbonSymbol,
                  style: TextStyle(color: FuwaColors.balletPink, fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 14),
              Text('还没有录入常服', style: TextStyle(color: FuwaColors.chocolateDark, fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('点击右下角呼吸小缎带开始录入', style: TextStyle(color: FuwaColors.mutedRosyBrown, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return PolaroidCard(
          item: item,
          onTap: () {
            if (widget.onItemTap != null) {
              widget.onItemTap!(item);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(
                    itemId: item.id!,
                    onDataChanged: _loadItems,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildFab() {
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
