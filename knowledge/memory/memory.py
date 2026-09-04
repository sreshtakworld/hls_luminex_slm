import sqlite3

DB_PATH = "knowledge/database/nira.db"


def save_memory(key, value):
    connection = sqlite3.connect(DB_PATH)
    cursor = connection.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS memory (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute(
        "INSERT INTO memory (key, value) VALUES (?, ?)",
        (key, value)
    )

    connection.commit()
    connection.close()


def get_memory(key):
    connection = sqlite3.connect(DB_PATH)
    cursor = connection.cursor()

    cursor.execute(
        "SELECT value FROM memory WHERE key = ? ORDER BY id DESC LIMIT 1",
        (key,)
    )

    result = cursor.fetchone()
    connection.close()

    return result[0] if result else None


def delete_memory(key):
    connection = sqlite3.connect(DB_PATH)
    cursor = connection.cursor()

    cursor.execute(
        "DELETE FROM memory WHERE key = ?",
        (key,)
    )

    connection.commit()
    connection.close()