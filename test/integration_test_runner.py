import sqlite3
import unittest
from datetime import datetime

class TestFuwaFuwaDatabaseV3(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.execute("PRAGMA foreign_keys = ON;")
        self.cursor = self.conn.cursor()

        # V3 schema with size column
        self.cursor.execute("""
        CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL CHECK(category IN ('earth', 'lolita')),
            subCategory TEXT NOT NULL,
            name TEXT NOT NULL,
            imagePath TEXT,
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

    def test_item_size_and_shopname(self):
        """测试单品尺码与店铺品牌的保存与读取"""
        self.cursor.execute("""
        INSERT INTO items (category, subCategory, name, size, shopName, fullPrice)
        VALUES ('earth', '连衣裙', '优雅碎花裙', 'M', 'Snidel', 450.0)
        """)
        self.conn.commit()

        self.cursor.execute("SELECT size, shopName FROM items WHERE name = '优雅碎花裙'")
        size, shop = self.cursor.fetchone()
        self.assertEqual(size, 'M')
        self.assertEqual(shop, 'Snidel')

    def test_pending_balance_pinning(self):
        """测试待补尾款自动置顶排序"""
        self.cursor.execute("INSERT INTO items (category, subCategory, name, isDepositType, balanceDate) VALUES ('lolita', 'OP', '已补尾款裙', 1, '2026-10-01')")
        self.cursor.execute("INSERT INTO items (category, subCategory, name, isDepositType, balanceDate) VALUES ('lolita', 'JSK', '待补尾款裙', 1, NULL)")
        self.cursor.execute("INSERT INTO items (category, subCategory, name, isDepositType, balanceDate) VALUES ('earth', '上衣', '现货上衣', 0, '2026-05-01')")
        self.conn.commit()

        order_sql = '(CASE WHEN isDepositType = 1 AND (balanceDate IS NULL OR trim(balanceDate) = "") THEN 0 ELSE 1 END) ASC, id DESC'
        self.cursor.execute(f'SELECT name FROM items ORDER BY {order_sql}')
        names = [r[0] for r in self.cursor.fetchall()]
        self.assertEqual(names[0], '待补尾款裙')

if __name__ == '__main__':
    unittest.main()
