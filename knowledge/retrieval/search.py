from knowledge.database.db import get_connection


def search_chunks(query, limit=5):
    connection = get_connection()
    cursor = connection.cursor()

    keywords = query.lower().split()

    if not keywords:
        connection.close()
        return []

    conditions = []
    parameters = []

    for keyword in keywords:
        conditions.append("LOWER(content) LIKE ?")
        parameters.append(f"%{keyword}%")

    sql = f"""
        SELECT id, document_id, chunk_index, content
        FROM chunks
        WHERE {" OR ".join(conditions)}
        ORDER BY id DESC
        LIMIT ?
    """

    parameters.append(limit)

    cursor.execute(sql, parameters)
    results = cursor.fetchall()

    connection.close()

    return results