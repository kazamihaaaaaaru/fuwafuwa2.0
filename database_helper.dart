import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/accessory.dart';
import '../models/finance_record.dart';
import '../models/item.dart';
import '../models/wishlist_item.dart';

/// 「ふわふわ（FuwaFuwa）」核心本地数据库辅助类
/// 基于 SQLite 纯本地运行，严格隔离外部网络
/// 版本 v4：支持尾款/全款最后付款日期降序排列（待补款置顶）、颜色标签、饰品品牌、完整备份导出与导入
class DatabaseHelper {
  static const String _dbName = 'fuwafuwa.db';
  static const int _dbVersion = 4; // 升级至 v4

  static const String tableItems = 'items';
  static const String tableAccessories = 'accessories';
  static const String tableItemAccessories = 'item_accessories';
  static const String tableWishlist = 'wishlist';

  DatabaseHelper._init();
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL CHECK(category IN ('earth', 'lolita')),
        subCategory TEXT NOT NULL,
        name TEXT NOT NULL,
        imagePath TEXT,
        color TEXT,
        size TEXT,
        season TEXT,
        shopName TEXT,
        isDepositType INTEGER NOT NULL DEFAULT 0,
        fullPrice REAL DEFAULT 0.0,
        depositPrice REAL DEFAULT 0.0,
        depositDate TEXT,
        balancePrice REAL DEFAULT 0.0,
        balanceDate TEXT,
        expectedDate TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE $tableAccessories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT,
        accessoryType TEXT NOT NULL,
        shopName TEXT,
        price REAL DEFAULT 0.0,
        purchaseDate TEXT,
        isDepositType INTEGER NOT NULL DEFAULT 0,
        fullPrice REAL DEFAULT 0.0,
        depositPrice REAL DEFAULT 0.0,
        depositDate TEXT,
        balancePrice REAL DEFAULT 0.0,
        balanceDate TEXT,
        expectedDate TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE $tableItemAccessories (
        itemId INTEGER NOT NULL,
        accessoryId INTEGER NOT NULL,
        PRIMARY KEY (itemId, accessoryId),
        FOREIGN KEY (itemId) REFERENCES $tableItems (id) ON DELETE CASCADE,
        FOREIGN KEY (accessoryId) REFERENCES $tableAccessories (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE $tableWishlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        imagePath TEXT,
        shopName TEXT,
        budgetPrice REAL DEFAULT 0.0,
        releaseDate TEXT,
        desireLevel TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'lolita',
        subCategory TEXT,
        note TEXT,
        createdDate TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_items_cat ON $tableItems(category);');
    await db.execute('CREATE INDEX idx_items_deposit ON $tableItems(isDepositType, balanceDate);');
    await db.execute('CREATE INDEX idx_acc_type ON $tableAccessories(accessoryType);');
    await db.execute('CREATE INDEX idx_wishlist_desire ON $tableWishlist(desireLevel);');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN isDepositType INTEGER NOT NULL DEFAULT 0;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN fullPrice REAL DEFAULT 0.0;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN depositPrice REAL DEFAULT 0.0;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN depositDate TEXT;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN balancePrice REAL DEFAULT 0.0;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN balanceDate TEXT;');
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN expectedDate TEXT;');

        await db.execute('''
          UPDATE $tableAccessories 
          SET fullPrice = price, depositDate = purchaseDate 
          WHERE isDepositType = 0 AND fullPrice = 0;
        ''');
      } catch (_) {}

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableWishlist (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          imagePath TEXT,
          shopName TEXT,
          budgetPrice REAL DEFAULT 0.0,
          releaseDate TEXT,
          desireLevel TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'lolita',
          subCategory TEXT,
          note TEXT,
          createdDate TEXT
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_wishlist_desire ON $tableWishlist(desireLevel);');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableItems ADD COLUMN size TEXT;');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      // v4 升级：衣服增加颜色字段（color），饰品增加店铺品牌字段（shopName）
      try {
        await db.execute('ALTER TABLE $tableItems ADD COLUMN color TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableAccessories ADD COLUMN shopName TEXT;');
      } catch (_) {}
    }
  }

  // ==========================================
  // 单品表 (Items) CRUD - 尾款/全款日期降序（待补款置顶）
  // ==========================================

  Future<int> insertItem(Item item, {List<int>? accessoryIds}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final itemId = await txn.insert(tableItems, item.toMap());
      if (accessoryIds != null && accessoryIds.isNotEmpty) {
        for (final accId in accessoryIds) {
          await txn.insert(
            tableItemAccessories,
            {'itemId': itemId, 'accessoryId': accId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      return itemId;
    });
  }

  Future<int> updateItem(Item item, {List<int>? accessoryIds}) async {
    final db = await database;
    if (item.id == null) return 0;

    return await db.transaction((txn) async {
      final rows = await txn.update(
        tableItems,
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (accessoryIds != null) {
        await txn.delete(
          tableItemAccessories,
          where: 'itemId = ?',
          whereArgs: [item.id],
        );
        for (final accId in accessoryIds) {
          await txn.insert(
            tableItemAccessories,
            {'itemId': item.id, 'accessoryId': accId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      return rows;
    });
  }

  Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Item?> getItemById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    final accessories = await getAccessoriesForItem(id);
    return Item.fromMap(maps.first, accessories: accessories);
  }

  /// 多维度查询单品：
  /// 规则 1：待补尾款置顶；已完成的单品按最终实际付款日期（尾款日或全款日）降序排列！
  Future<List<Item>> getAllItems({
    String? category,
    String? subCategory,
    String? season,
    String? searchQuery,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (category != null && category != 'all') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (subCategory != null && subCategory.isNotEmpty && subCategory != '全部') {
      whereClauses.add('subCategory = ?');
      whereArgs.add(subCategory);
    }
    if (season != null && season.isNotEmpty && season != '全部季节' && season != '全部') {
      whereClauses.add('season = ?');
      whereArgs.add(season);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR shopName LIKE ? OR color LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    // 核心优化 1：待付尾款置顶，其它按尾款/全款最后付款日期降序排列
    const orderClause = '''
      (CASE WHEN isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '') THEN 0 ELSE 1 END) ASC,
      COALESCE(CASE WHEN isDepositType = 1 THEN balanceDate ELSE depositDate END, depositDate, '') DESC,
      id DESC
    ''';

    final maps = await db.query(
      tableItems,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderClause,
    );

    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<int> recordBalancePayment(int itemId, double balancePrice, String balanceDate) async {
    final db = await database;
    return await db.update(
      tableItems,
      {
        'balancePrice': balancePrice,
        'balanceDate': balanceDate,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  // ==========================================
  // 小物表 (Accessories) CRUD - 尾款/全款日期降序（待补款置顶）
  // ==========================================

  Future<int> insertAccessory(Accessory accessory, {List<int>? itemIds}) async {
    final db = await database;
    return await db.transaction((txn) async {
      final accId = await txn.insert(tableAccessories, accessory.toMap());
      if (itemIds != null && itemIds.isNotEmpty) {
        for (final itemId in itemIds) {
          await txn.insert(
            tableItemAccessories,
            {'itemId': itemId, 'accessoryId': accId},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      return accId;
    });
  }

  Future<int> updateAccessory(Accessory accessory, {List<int>? itemIds}) async {
    final db = await database;
    if (accessory.id == null) return 0;
    return await db.transaction((txn) async {
      final rows = await txn.update(
        tableAccessories,
        accessory.toMap(),
        where: 'id = ?',
        whereArgs: [accessory.id],
      );
      if (itemIds != null) {
        await txn.delete(
          tableItemAccessories,
          where: 'accessoryId = ?',
          whereArgs: [accessory.id],
        );
        for (final itemId in itemIds) {
          await txn.insert(
            tableItemAccessories,
            {'itemId': itemId, 'accessoryId': accessory.id},
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
      return rows;
    });
  }

  Future<int> deleteAccessory(int id) async {
    final db = await database;
    return await db.delete(
      tableAccessories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Accessory?> getAccessoryById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableAccessories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Accessory.fromMap(maps.first);
  }

  /// 获取小物列表：待补尾款小物置顶，已完成的按最后付款日期降序
  Future<List<Accessory>> getAllAccessories({
    String? accessoryType,
    String? searchQuery,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (accessoryType != null && accessoryType.isNotEmpty && accessoryType != '全部') {
      whereClauses.add('accessoryType = ?');
      whereArgs.add(accessoryType);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR shopName LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    const orderClause = '''
      (CASE WHEN isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '') THEN 0 ELSE 1 END) ASC,
      COALESCE(CASE WHEN isDepositType = 1 THEN balanceDate ELSE depositDate END, depositDate, '') DESC,
      id DESC
    ''';

    final maps = await db.query(
      tableAccessories,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: orderClause,
    );

    return maps.map((m) => Accessory.fromMap(m)).toList();
  }

  Future<int> recordAccessoryBalancePayment(int accessoryId, double balancePrice, String balanceDate) async {
    final db = await database;
    return await db.update(
      tableAccessories,
      {
        'balancePrice': balancePrice,
        'balanceDate': balanceDate,
      },
      where: 'id = ?',
      whereArgs: [accessoryId],
    );
  }

  // ==========================================
  // 单品与小物关联 (ItemAccessories)
  // ==========================================

  Future<List<Accessory>> getAccessoriesForItem(int itemId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT a.* FROM $tableAccessories a
      INNER JOIN $tableItemAccessories ia ON a.id = ia.accessoryId
      WHERE ia.itemId = ?
      ORDER BY a.id DESC;
    ''', [itemId]);

    return maps.map((m) => Accessory.fromMap(m)).toList();
  }

  Future<List<Item>> getItemsForAccessory(int accessoryId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT i.* FROM $tableItems i
      INNER JOIN $tableItemAccessories ia ON i.id = ia.itemId
      WHERE ia.accessoryId = ?
      ORDER BY i.id DESC;
    ''', [accessoryId]);

    return maps.map((m) => Item.fromMap(m)).toList();
  }

  Future<void> bindAccessory(int itemId, int accessoryId) async {
    final db = await database;
    await db.insert(
      tableItemAccessories,
      {'itemId': itemId, 'accessoryId': accessoryId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> unbindAccessory(int itemId, int accessoryId) async {
    final db = await database;
    await db.delete(
      tableItemAccessories,
      where: 'itemId = ? AND accessoryId = ?',
      whereArgs: [itemId, accessoryId],
    );
  }

  // ==========================================
  // 心愿单 (Wishlist) CRUD
  // ==========================================

  Future<int> insertWishlistItem(WishlistItem item) async {
    final db = await database;
    return await db.insert(tableWishlist, item.toMap());
  }

  Future<List<WishlistItem>> getAllWishlistItems({
    String? desireLevel,
    String? category,
    String? searchQuery,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (desireLevel != null && desireLevel.isNotEmpty && desireLevel != '全部') {
      whereClauses.add('desireLevel = ?');
      whereArgs.add(desireLevel);
    }
    if (category != null && category.isNotEmpty && category != '全部') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR shopName LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');
    final maps = await db.query(
      tableWishlist,
      where: where,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
    );

    return maps.map((m) => WishlistItem.fromMap(m)).toList();
  }

  Future<int> updateWishlistItem(WishlistItem item) async {
    final db = await database;
    if (item.id == null) return 0;
    return await db.update(
      tableWishlist,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteWishlistItem(int id) async {
    final db = await database;
    return await db.delete(
      tableWishlist,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // 记账看板财务统计（Finance Stats）
  // ==========================================

  Future<FinanceSummary> getFinanceSummary() async {
    final db = await database;

    final earthRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN isDepositType = 0 THEN fullPrice ELSE (depositPrice + balancePrice) END) as total
      FROM $tableItems
      WHERE category = 'earth';
    ''');
    final earthTotal = (earthRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final lolitaRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN isDepositType = 0 THEN fullPrice ELSE (depositPrice + balancePrice) END) as total
      FROM $tableItems
      WHERE category = 'lolita';
    ''');
    final lolitaTotal = (lolitaRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final accRes = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN isDepositType = 0 THEN (CASE WHEN fullPrice > 0 THEN fullPrice ELSE price END) ELSE (depositPrice + balancePrice) END) as total
      FROM $tableAccessories;
    ''');
    final accessoryTotal = (accRes.first['total'] as num?)?.toDouble() ?? 0.0;

    final pendingItemsRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        SUM(CASE WHEN fullPrice > depositPrice THEN (fullPrice - depositPrice) ELSE 0 END) as estimate
      FROM $tableItems
      WHERE isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '');
    ''');
    final pendingItemsCount = (pendingItemsRes.first['count'] as int?) ?? 0;
    final pendingItemsEstimate = (pendingItemsRes.first['estimate'] as num?)?.toDouble() ?? 0.0;

    final pendingAccRes = await db.rawQuery('''
      SELECT 
        COUNT(*) as count,
        SUM(CASE WHEN fullPrice > depositPrice THEN (fullPrice - depositPrice) ELSE 0 END) as estimate
      FROM $tableAccessories
      WHERE isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '');
    ''');
    final pendingAccCount = (pendingAccRes.first['count'] as int?) ?? 0;
    final pendingAccEstimate = (pendingAccRes.first['estimate'] as num?)?.toDouble() ?? 0.0;

    return FinanceSummary(
      totalWardrobeAsset: earthTotal + lolitaTotal + accessoryTotal,
      pendingBalanceCount: pendingItemsCount + pendingAccCount,
      pendingBalanceEstimate: pendingItemsEstimate + pendingAccEstimate,
      earthTotal: earthTotal,
      lolitaTotal: lolitaTotal,
      accessoryTotal: accessoryTotal,
    );
  }

  Future<List<FinanceRecord>> getFinanceTimeline({String? yearMonth}) async {
    final db = await database;

    final filterClause = (yearMonth != null && yearMonth.isNotEmpty && yearMonth != '全部')
        ? "WHERE strftime('%Y-%m', date) = '$yearMonth'"
        : "";

    final sql = '''
      SELECT date, amount, category, title, paymentType, itemId, accessoryId FROM (
        SELECT 
          depositDate AS date,
          fullPrice AS amount,
          category,
          name AS title,
          '全款' AS paymentType,
          id AS itemId,
          NULL AS accessoryId
        FROM $tableItems
        WHERE isDepositType = 0 AND depositDate IS NOT NULL AND trim(depositDate) != '' AND fullPrice > 0

        UNION ALL

        SELECT 
          depositDate AS date,
          depositPrice AS amount,
          'lolita' AS category,
          name AS title,
          '定金' AS paymentType,
          id AS itemId,
          NULL AS accessoryId
        FROM $tableItems
        WHERE isDepositType = 1 AND depositDate IS NOT NULL AND trim(depositDate) != '' AND depositPrice > 0

        UNION ALL

        SELECT 
          balanceDate AS date,
          balancePrice AS amount,
          'lolita' AS category,
          name AS title,
          '尾款' AS paymentType,
          id AS itemId,
          NULL AS accessoryId
        FROM $tableItems
        WHERE isDepositType = 1 AND balanceDate IS NOT NULL AND trim(balanceDate) != '' AND balancePrice > 0

        UNION ALL

        SELECT 
          depositDate AS date,
          (CASE WHEN fullPrice > 0 THEN fullPrice ELSE price END) AS amount,
          'accessory' AS category,
          name AS title,
          '小物' AS paymentType,
          NULL AS itemId,
          id AS accessoryId
        FROM $tableAccessories
        WHERE isDepositType = 0 AND depositDate IS NOT NULL AND trim(depositDate) != '' AND (fullPrice > 0 OR price > 0)

        UNION ALL

        SELECT 
          depositDate AS date,
          depositPrice AS amount,
          'accessory' AS category,
          name AS title,
          '定金' AS paymentType,
          NULL AS itemId,
          id AS accessoryId
        FROM $tableAccessories
        WHERE isDepositType = 1 AND depositDate IS NOT NULL AND trim(depositDate) != '' AND depositPrice > 0

        UNION ALL

        SELECT 
          balanceDate AS date,
          balancePrice AS amount,
          'accessory' AS category,
          name AS title,
          '尾款' AS paymentType,
          NULL AS itemId,
          id AS accessoryId
        FROM $tableAccessories
        WHERE isDepositType = 1 AND balanceDate IS NOT NULL AND trim(balanceDate) != '' AND balancePrice > 0
      )
      $filterClause
      ORDER BY date DESC;
    ''';

    final maps = await db.rawQuery(sql);
    return maps.map((m) => FinanceRecord.fromMap(m)).toList();
  }

  // ==========================================
  // 数据全量备份与迁移恢复（Backup & Restore）
  // ==========================================

  /// 导出数据库全量原始数据
  Future<Map<String, dynamic>> exportRawData() async {
    final db = await database;
    final items = await db.query(tableItems);
    final accessories = await db.query(tableAccessories);
    final itemAccessories = await db.query(tableItemAccessories);
    final wishlist = await db.query(tableWishlist);

    return {
      'app': 'FuwaFuwa',
      'version': _dbVersion,
      'items': items,
      'accessories': accessories,
      'itemAccessories': itemAccessories,
      'wishlist': wishlist,
    };
  }

  /// 导入并恢复备份数据（事务保证原子性）
  Future<int> importRawData(Map<String, dynamic> data) async {
    final db = await database;

    final itemsList = (data['items'] as List<dynamic>?) ?? [];
    final accessoriesList = (data['accessories'] as List<dynamic>?) ?? [];
    final itemAccessoriesList = (data['itemAccessories'] as List<dynamic>?) ?? [];
    final wishlistList = (data['wishlist'] as List<dynamic>?) ?? [];

    return await db.transaction((txn) async {
      int importedCount = 0;

      // 1. 恢复 items
      for (final raw in itemsList) {
        if (raw is Map<String, dynamic>) {
          await txn.insert(tableItems, raw, conflictAlgorithm: ConflictAlgorithm.replace);
          importedCount++;
        }
      }

      // 2. 恢复 accessories
      for (final raw in accessoriesList) {
        if (raw is Map<String, dynamic>) {
          await txn.insert(tableAccessories, raw, conflictAlgorithm: ConflictAlgorithm.replace);
          importedCount++;
        }
      }

      // 3. 恢复 item_accessories 关联
      for (final raw in itemAccessoriesList) {
        if (raw is Map<String, dynamic>) {
          await txn.insert(tableItemAccessories, raw, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      // 4. 恢复 wishlist
      for (final raw in wishlistList) {
        if (raw is Map<String, dynamic>) {
          await txn.insert(tableWishlist, raw, conflictAlgorithm: ConflictAlgorithm.replace);
          importedCount++;
        }
      }

      return importedCount;
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
