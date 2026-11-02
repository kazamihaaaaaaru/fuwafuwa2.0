import sqlite3
import unittest
from datetime import datetime

class TestFuwaFuwaDatabaseV2(unittest.TestCase):
    def setUp(self):
        self.conn = sqlite3.connect(":memory:")
        self.conn.execute("PRAGMA foreign_keys = ON;")
        self.cursor = self.conn.cursor()

        # V2 schema creation
        self.cursor.execute("""
        CREATE TABLE items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL CHECK(category IN ('earth', 'lolita')),
            subCategory TEXT NOT NULL,
            name TEXT NOT NULL,
            imagePath TEXT,
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

    def test_accessory_deposit_balance(self):
        """测试小物支持定金尾款制与一键补款"""
        self.cursor.execute("""
        INSERT INTO accessories (name, accessoryType, isDepositType, depositPrice, depositDate, expectedDate)
        VALUES ('原版琥珀心发带', '发带', 1, 50.0, '2026-03-01', '2026-06-01')
        """)
        acc_id = self.cursor.lastrowid
        self.conn.commit()

        # 一键补款
        self.cursor.execute("""
        UPDATE accessories SET balancePrice = ?, balanceDate = ? WHERE id = ?
        """, (28.0, '2026-05-20', acc_id))
        self.conn.commit()

        self.cursor.execute("SELECT (depositPrice + balancePrice) FROM accessories WHERE id = ?", (acc_id,))
        total = self.cursor.fetchone()[0]
        self.assertEqual(total, 78.0)

    def test_wishlist_crud_and_transfer(self):
        """测试心愿单增加、读取与转入后移出"""
        self.cursor.execute("""
        INSERT INTO wishlist (name, shopName, budgetPrice, releaseDate, desireLevel)
        VALUES ('白雪姬 JSK', 'Baby', 2800.0, '2026-12', '非入不可 ♡')
        """)
        wish_id = self.cursor.lastrowid
        self.conn.commit()

        self.cursor.execute("SELECT name, desireLevel FROM wishlist WHERE id = ?", (wish_id,))
        name, level = self.cursor.fetchone()
        self.assertEqual(name, '白雪姬 JSK')
        self.assertEqual(level, '非入不可 ♡')

        # 拔草或入库后移出
        self.cursor.execute("DELETE FROM wishlist WHERE id = ?", (wish_id,))
        self.conn.commit()
        self.cursor.execute("SELECT COUNT(*) FROM wishlist WHERE id = ?", (wish_id,))
        self.assertEqual(self.cursor.fetchone()[0], 0)

    def test_cashflow_positive_and_grouped(self):
        """测试月度流水均为正数且准确统计当月总额"""
        # 录入单品与小物
        self.cursor.execute("INSERT INTO items (category, subCategory, name, isDepositType, fullPrice, depositDate) VALUES ('lolita', 'OP', '原版琥珀心op-黑色', 0, 278.0, '2026-10-28')")
        self.cursor.execute("INSERT INTO accessories (name, accessoryType, isDepositType, fullPrice, depositDate) VALUES ('琥珀心发带-黑色', '发带', 0, 78.0, '2026-10-28')")
        self.conn.commit()

        query = """
        SELECT amount FROM (
            SELECT fullPrice as amount, depositDate as date FROM items WHERE isDepositType = 0
            UNION ALL
            SELECT (CASE WHEN fullPrice > 0 THEN fullPrice ELSE price END) as amount, depositDate as date FROM accessories WHERE isDepositType = 0
        ) WHERE strftime('%Y-%m', date) = '2026-10';
        """
        self.cursor.execute(query)
        amounts = [r[0] for r in self.cursor.fetchall()]
        self.assertEqual(amounts, [278.0, 78.0])
        self.assertEqual(sum(amounts), 356.0)

if __name__ == '__main__':
    unittest.main()
