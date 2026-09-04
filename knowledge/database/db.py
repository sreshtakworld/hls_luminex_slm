import sqlite3


DB_PATH = "knowledge/database/nira.db"


def get_connection():
    return sqlite3.connect(DB_PATH)


def create_tables():
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filename TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER NOT NULL,
            chunk_index INTEGER NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (document_id) REFERENCES documents(id)
        )
    """)

    connection.commit()
    connection.close()


def insert_document(filename, content):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        "INSERT INTO documents (filename, content) VALUES (?, ?)",
        (filename, content)
    )

    document_id = cursor.lastrowid

    connection.commit()
    connection.close()

    return document_id


def insert_chunk(document_id, chunk_index, content):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        INSERT INTO chunks (document_id, chunk_index, content)
        VALUES (?, ?, ?)
        """,
        (document_id, chunk_index, content)
    )

    connection.commit()
    connection.close()