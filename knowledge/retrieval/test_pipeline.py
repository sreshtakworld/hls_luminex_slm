from pdf_processor import extract_text_from_pdf
from chunker import chunk_text


pdf_path = "knowledge/documents/test.pdf"

text = extract_text_from_pdf(pdf_path)
chunks = chunk_text(text, chunk_size=50)

print("Extracted text:")
print(text)

print("\nChunks:")
for i, chunk in enumerate(chunks, start=1):
    print(f"\nChunk {i}:")
    print(chunk)