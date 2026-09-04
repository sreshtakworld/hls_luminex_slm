import os

from knowledge.retrieval.pdf_processor import extract_text_from_pdf
from knowledge.retrieval.chunker import chunk_text
from knowledge.database.db import (
    create_tables,
    insert_document,
    insert_chunk,
)


def ingest_pdf(pdf_path):
    create_tables()

    text = extract_text_from_pdf(pdf_path)
    chunks = chunk_text(text)

    filename = os.path.basename(pdf_path)

    document_id = insert_document(filename, text)

    for index, chunk in enumerate(chunks):
        insert_chunk(document_id, index, chunk)

    return document_id, len(chunks)