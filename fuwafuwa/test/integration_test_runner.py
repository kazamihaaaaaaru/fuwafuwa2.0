import json
import sqlite3
import unittest
from datetime import datetime

class TestFuwaFuwaDatabaseV4(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.execute("PRAGMA foreign_keys = ON;")
        self.cursor = self.conn.cursor()

        # V4 schema with size, color in items, shopName in accessories
        self.cursor.execute("""
        CREATE TABLE items (
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
        """)

        self.cursor.execute("""
        CREATE TABLE accessories (
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
        """)

        self.cursor.execute("""
        CREATE TABLE item_accessories (
            itemId INTEGER NOT NULL,
            accessoryId INTEGER NOT NULL,
            PRIMARY KEY (itemId, accessoryId),
            FOREIGN KEY (itemId) REFERENCES items (id) ON DELETE CASCADE,
            FOREIGN KEY (accessoryId) REFERENCES accessories (id) ON DELETE CASCADE
        );
        """)

        self.cursor.execute("""
        CREATE TABLE wishlist (
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
        """)
        self.conn.commit()

    def tearDown(self):
        self.conn.close()

    def test_item_color_and_accessory_shopname(self):
        """测试衣物颜色标签与小物品牌名称的录入与读取"""
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, color, size, shopName, fullPrice)
        VALUES ('lolita', 'OP', '琥珀心', '生成色', 'M', '玻璃花信', 880.0)
        """)
        self.cursor.execute("""
        INSERT INTO accessories (name, accessoryType, shopName, fullPrice)
        VALUES ('琥珀心KC', 'KC', '玻璃花信', 128.0)
        """)
        self.conn.commit()

        self.cursor.execute("SELECT color, shopName FROM items WHERE name = '琥珀心'")
        color, shop = self.cursor.fetchone()
        self.assertEqual(color, '生成色')
        self.assertEqual(shop, '玻璃花信')

        self.cursor.execute("SELECT shopName, accessoryType FROM accessories WHERE name = '琥珀心KC'")
        acc_shop, acc_type = self.cursor.fetchone()
        self.assertEqual(acc_shop, '玻璃花信')
        self.assertEqual(acc_type, 'KC')

    def test_date_descending_and_pending_pinning(self):
        """测试尾款/全款时间降序排列，且待补尾款严格置顶"""
        # 1. 较旧全款衣物
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, isDepositType, depositDate)
        VALUES ('earth', '连衣裙', '2026年3月连衣裙', 0, '2026-03-15')
        """)
        # 2. 待补尾款裙（必须置顶，无论定金日期多早）
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, isDepositType, depositDate, balanceDate)
        VALUES ('lolita', 'JSK', '待补尾款JSK', 1, '2026-01-01', NULL)
        """)
        # 3. 较新已补尾款裙（补款日期 2026-10-20）
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, isDepositType, depositDate, balanceDate)
        VALUES ('lolita', 'OP', '10月补款OP', 1, '2026-02-01', '2026-10-20')
        """)
        # 4. 最新全款现货衣物（购买日期 2026-11-01）
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, isDepositType, depositDate)
        VALUES ('earth', '外套', '11月现货外套', 0, '2026-11-01')
        """)
        self.conn.commit()

        order_sql = """
        (CASE WHEN isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '') THEN 0 ELSE 1 END) ASC,
        COALESCE(CASE WHEN isDepositType = 1 THEN balanceDate ELSE depositDate END, depositDate, '') DESC,
        id DESC
        """
        self.cursor.execute(f"SELECT name FROM items ORDER BY {order_sql}")
        names = [r[0] for r in self.cursor.fetchall()]

        # 预期顺序：
        # 第1名：待补尾款JSK (置顶)
        # 第2名：11月现货外套 (2026-11-01)
        # 第3名：10月补款OP (2026-10-20)
        # 第4名：2026年3月连衣裙 (2026-03-15)
        self.assertEqual(names, ['待补尾款JSK', '11月现货外套', '10月补款OP', '2026年3月连衣裙'])

    def test_accessory_sorting_and_pending_pinning(self):
        """测试小物待补款置顶与尾款/全款时间降序"""
        self.cursor.execute("""
        INSERT INTO accessories (name, accessoryType, isDepositType, depositDate)
        VALUES ('3月全款KC', 'KC', 0, '2026-03-01')
        """)
        self.cursor.execute("""
        INSERT INTO accessories (name, accessoryType, isDepositType, depositDate, balanceDate)
        VALUES ('待补款帽子', '帽子', 1, '2026-01-10', NULL)
        """)
        self.cursor.execute("""
        INSERT INTO accessories (name, accessoryType, isDepositType, depositDate, balanceDate)
        VALUES ('9月补款BNT', 'BNT', 1, '2026-02-10', '2026-09-15')
        """)
        self.conn.commit()

        order_sql = """
        (CASE WHEN isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = '') THEN 0 ELSE 1 END) ASC,
        COALESCE(CASE WHEN isDepositType = 1 THEN balanceDate ELSE depositDate END, depositDate, '') DESC,
        id DESC
        """
        self.cursor.execute(f"SELECT name FROM accessories ORDER BY {order_sql}")
        acc_names = [r[0] for r in self.cursor.fetchall()]
        self.assertEqual(acc_names, ['待补款帽子', '9月补款BNT', '3月全款KC'])

    def test_backup_and_migration_payload_structure(self):
        """测试备份迁移 JSON 数据结构导出与恢复无损性"""
        payload = {
            "version": 4,
            "exportTime": datetime.now().isoformat(),
            "appName": "fuwafuwa",
            "items": [
                {
                    "category": "lolita",
                    "subCategory": "OP",
                    "name": "梦境游行",
                    "color": "樱粉",
                    "shopName": "Baby",
                    "size": "S",
                    "isDepositType": 1,
                    "fullPrice": 0.0,
                    "depositPrice": 500.0,
                    "depositDate": "2026-05-01",
                    "balancePrice": 800.0,
                    "balanceDate": "2026-10-15"
                }
            ],
            "accessories": [
                {
                    "name": "梦境遮阳草帽",
                    "accessoryType": "帽子",
                    "shopName": "Baby",
                    "isDepositType": 0,
                    "fullPrice": 220.0,
                    "depositDate": "2026-10-16"
                }
            ],
            "wishlist": [],
            "itemAccessories": [],
            "images": {}
        }

        # 序列化与反序列化测试
        json_str = json.dumps(payload, ensure_ascii=False)
        recovered = json.loads(json_str)

        self.assertEqual(recovered["version"], 4)
        self.assertEqual(recovered["items"][0]["color"], "樱粉")
        self.assertEqual(recovered["accessories"][0]["accessoryType"], "帽子")
        self.assertEqual(recovered["accessories"][0]["shopName"], "Baby")

if __name__ == '__main__':
    unittest.main()
