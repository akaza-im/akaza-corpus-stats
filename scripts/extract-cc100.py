#!/usr/bin/env python3
"""Extract documents from CC-100 Japanese plain text (ja.txt.xz).

CC-100 format: one sentence per line, blank lines separate documents.
This script converts it to the ``<doc>`` format used by wikiextractor
so the Akaza pipeline (``akaza-data tokenize --reader=jawiki``) can
consume it without changes.

Usage:
    python3 scripts/extract-cc100.py [--limit N] INPUT.txt.xz OUTPUT_DIR

Output directory structure mirrors wikiextractor:
    OUTPUT_DIR/AA/wiki_00
    OUTPUT_DIR/AA/wiki_01
    ...
    OUTPUT_DIR/AB/wiki_00
    ...
"""

import argparse
import lzma
import os
import sys

# Maximum number of documents per output file
ARTICLES_PER_FILE = 1000


def _subdir_names():
    """Subdirectory names: AA, AB, AC, ..., ZZ (676 dirs)."""
    for a in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
        for b in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
            yield a + b


def main():
    parser = argparse.ArgumentParser(
        description="Convert CC-100 ja.txt.xz to <doc> format"
    )
    parser.add_argument("input", help="Input file (ja.txt.xz)")
    parser.add_argument("output_dir", help="Output directory")
    parser.add_argument(
        "--limit",
        type=int,
        default=0,
        help="Max number of documents to extract (0 = unlimited)",
    )
    args = parser.parse_args()

    input_path = args.input
    output_dir = args.output_dir
    limit = args.limit

    subdir_iter = _subdir_names()
    current_subdir = next(subdir_iter)
    file_index = 0
    out_file = None
    articles_in_current_file = 0
    total_articles = 0

    def open_next_file():
        nonlocal current_subdir, file_index, out_file, articles_in_current_file
        if out_file is not None:
            out_file.close()
        if total_articles > 0 and total_articles % ARTICLES_PER_FILE == 0:
            file_index += 1
            if file_index >= 100:
                file_index = 0
                current_subdir = next(subdir_iter)
        dir_path = os.path.join(output_dir, current_subdir)
        os.makedirs(dir_path, exist_ok=True)
        file_path = os.path.join(dir_path, f"wiki_{file_index:02d}")
        out_file = open(file_path, "a", encoding="utf-8")
        articles_in_current_file = 0

    def flush_doc(lines, doc_id):
        nonlocal total_articles, articles_in_current_file, out_file
        if not lines:
            return
        text = "\n".join(lines)
        out_file.write(f'<doc id="{doc_id}" url="" title="cc100_{doc_id}">\n')
        out_file.write(text)
        out_file.write("\n</doc>\n")
        articles_in_current_file += 1
        total_articles += 1
        if articles_in_current_file >= ARTICLES_PER_FILE:
            open_next_file()

    open_next_file()

    doc_lines = []
    doc_id = 0

    with lzma.open(input_path, "rt", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if line == "":
                # Document boundary
                if doc_lines:
                    flush_doc(doc_lines, doc_id)
                    doc_id += 1
                    doc_lines = []
                    if limit > 0 and total_articles >= limit:
                        break
            else:
                doc_lines.append(line)

    # Flush last document if file doesn't end with blank line
    if doc_lines and (limit == 0 or total_articles < limit):
        flush_doc(doc_lines, doc_id)

    if out_file is not None:
        out_file.close()

    print(f"Extracted {total_articles} documents to {output_dir}", file=sys.stderr)


if __name__ == "__main__":
    main()
