"""Índice de busca das docs: a seção é a unidade, o resultado é uma faixa de linhas.

Motor padrão é FTS5/BM25 — instantâneo e sem modelo. Embedding é opcional
(`index --embed` + `search --semantic`) porque o ganho não paga o custo num corpus
técnico em pt-BR, onde quase toda busca cita um termo que está no texto: medido neste
repositório, indexar custou 8m54s contra 0,69s e cada busca 25s contra 0,12s, e o
modelo disponível é treinado em inglês — devolveu o arquivo errado.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import signal
import sqlite3
import sys
from pathlib import Path

HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*$")
LABEL = re.compile(r"\b(D\d+[a-z]?|F\d+[a-z]?|R\d+[a-z]?|VR-\d{2}-\d{2}|A\d+|I\d+)\b")
SECTION_REF = re.compile(r"§\s?([\d.]+[a-z]?)")
MIN_CHARS = 40
DEFAULT_GLOBS = ["docs/**/*.md", "*.md", ".claude/**/*.md"]
EXCLUDED_PARTS = {".docs-index", "worktrees", "node_modules", ".dart_tool", "build"}
MODEL_NAME = os.environ.get("DOCS_INDEX_MODEL", "sentence-transformers/all-MiniLM-L6-v2")

SCHEMA = """
CREATE TABLE IF NOT EXISTS files (
  path TEXT PRIMARY KEY, sha TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS sections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  path TEXT NOT NULL, heading TEXT NOT NULL, trail TEXT NOT NULL,
  level INTEGER NOT NULL, line_start INTEGER NOT NULL, line_end INTEGER NOT NULL,
  chars INTEGER NOT NULL, body TEXT NOT NULL, vec BLOB
);
CREATE INDEX IF NOT EXISTS sections_path ON sections(path);
CREATE VIRTUAL TABLE IF NOT EXISTS sections_fts USING fts5(
  trail, body, content='sections', content_rowid='id',
  tokenize='unicode61 remove_diacritics 2'
);
CREATE TABLE IF NOT EXISTS labels (
  label TEXT NOT NULL, path TEXT NOT NULL, line INTEGER NOT NULL,
  section_id INTEGER, defining INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS labels_label ON labels(label);
CREATE INDEX IF NOT EXISTS labels_path ON labels(path);
"""


def repo_root() -> Path:
    for parent in Path(__file__).resolve().parents:
        if (parent / ".git").exists():
            return parent
    return Path.cwd()


def connect(root: Path) -> sqlite3.Connection:
    path = root / ".docs-index" / "index.db"
    path.parent.mkdir(parents=True, exist_ok=True)
    gitignore = path.parent / ".gitignore"
    if not gitignore.exists():
        gitignore.write_text("*\n")
    conn = sqlite3.connect(path)
    conn.executescript(SCHEMA)
    return conn


def doc_files(root: Path, globs: list[str]) -> list[Path]:
    found: dict[Path, None] = {}
    for pattern in globs:
        for path in sorted(root.glob(pattern)):
            if path.is_file() and not EXCLUDED_PARTS.intersection(path.parts):
                found[path] = None
    return list(found)


def split_sections(path: Path, rel: str) -> list[dict]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    marks: list[tuple[int, int, str]] = []
    fenced = False
    for index, line in enumerate(lines):
        if line.lstrip().startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        match = HEADING.match(line)
        if match:
            marks.append((index, len(match.group(1)), match.group(2).strip()))

    if not marks or marks[0][0] > 0:
        marks.insert(0, (0, 1, path.stem))

    sections: list[dict] = []
    trail: list[str] = []
    for position, (start, level, title) in enumerate(marks):
        end = marks[position + 1][0] - 1 if position + 1 < len(marks) else len(lines) - 1
        trail = trail[: level - 1]
        while len(trail) < level - 1:
            trail.append("")
        trail.append(title)
        body = "\n".join(lines[start : end + 1]).strip()
        if len(body) < MIN_CHARS:
            continue
        sections.append(
            {
                "path": rel,
                "heading": title,
                "trail": " › ".join(t for t in trail if t),
                "level": level,
                "line_start": start + 1,
                "line_end": end + 1,
                "chars": len(body),
                "body": body,
            }
        )
    return sections


def index_labels(conn: sqlite3.Connection, section: dict, section_id: int) -> None:
    for offset, line in enumerate(section["body"].splitlines()):
        defining = 1 if (offset == 0 or line.lstrip().startswith("#")) else 0
        for match in LABEL.finditer(line):
            conn.execute(
                "INSERT INTO labels (label, path, line, section_id, defining) VALUES (?,?,?,?,?)",
                (match.group(1), section["path"], section["line_start"] + offset, section_id, defining),
            )
        for match in SECTION_REF.finditer(line):
            conn.execute(
                "INSERT INTO labels (label, path, line, section_id, defining) VALUES (?,?,?,?,?)",
                ("§" + match.group(1), section["path"], section["line_start"] + offset, section_id, 0),
            )


def drop_file(conn: sqlite3.Connection, rel: str) -> None:
    for (section_id,) in conn.execute("SELECT id FROM sections WHERE path = ?", (rel,)).fetchall():
        conn.execute(
            "INSERT INTO sections_fts(sections_fts, rowid, trail, body)"
            " SELECT 'delete', id, trail, body FROM sections WHERE id = ?",
            (section_id,),
        )
    conn.execute("DELETE FROM sections WHERE path = ?", (rel,))
    conn.execute("DELETE FROM labels WHERE path = ?", (rel,))
    conn.execute("DELETE FROM files WHERE path = ?", (rel,))


def reindex(root: Path, globs: list[str], force: bool, embed: bool, quiet: bool) -> dict:
    conn = connect(root)
    known = {row[0]: row[1] for row in conn.execute("SELECT path, sha FROM files")}
    files = doc_files(root, globs)
    present: set[str] = set()
    stale: list[tuple[Path, str]] = []

    for path in files:
        rel = str(path.relative_to(root))
        present.add(rel)
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if force or known.get(rel) != digest:
            stale.append((path, digest))

    removed = [rel for rel in known if rel not in present]
    for rel in removed:
        drop_file(conn, rel)

    pending: list[tuple[dict, int]] = []
    for path, digest in stale:
        rel = str(path.relative_to(root))
        drop_file(conn, rel)
        for section in split_sections(path, rel):
            cursor = conn.execute(
                "INSERT INTO sections (path, heading, trail, level, line_start, line_end,"
                " chars, body) VALUES (?,?,?,?,?,?,?,?)",
                (
                    section["path"], section["heading"], section["trail"], section["level"],
                    section["line_start"], section["line_end"], section["chars"], section["body"],
                ),
            )
            section_id = cursor.lastrowid
            conn.execute(
                "INSERT INTO sections_fts(rowid, trail, body) VALUES (?,?,?)",
                (section_id, section["trail"], section["body"]),
            )
            index_labels(conn, section, section_id)
            pending.append((section, section_id))
        conn.execute("INSERT OR REPLACE INTO files (path, sha) VALUES (?, ?)", (rel, digest))

    if embed and pending:
        import numpy as np
        from sentence_transformers import SentenceTransformer

        model = SentenceTransformer(MODEL_NAME)
        texts = [f"{s['trail']}\n{s['body'][:2000]}" for s, _ in pending]
        vectors = model.encode(texts, normalize_embeddings=True, show_progress_bar=False)
        for (_, section_id), vector in zip(pending, vectors):
            conn.execute(
                "UPDATE sections SET vec = ? WHERE id = ?",
                (np.asarray(vector, dtype="float32").tobytes(), section_id),
            )

    conn.commit()
    stats = {
        "arquivos": len(files),
        "reindexados": len(stale),
        "removidos": len(removed),
        "secoes": conn.execute("SELECT COUNT(*) FROM sections").fetchone()[0],
        "rotulos": conn.execute("SELECT COUNT(DISTINCT label) FROM labels").fetchone()[0],
    }
    conn.close()
    if not quiet:
        print(json.dumps(stats, ensure_ascii=False))
    return stats


OPERATORS = re.compile(r'"|\bAND\b|\bOR\b|\bNOT\b|\*|:')
TOKEN = re.compile(r"[0-9A-Za-zÀ-ÿ_§.-]{2,}")
STOPWORDS = {
    "a", "o", "as", "os", "de", "da", "do", "das", "dos", "em", "no", "na", "nos", "nas",
    "um", "uma", "e", "ou", "que", "para", "por", "com", "sem", "ao", "aos", "se", "the",
}


def build_match(query: str) -> str:
    """FTS5 não faz stemming: sem o prefixo, "prova" não casa "provar" e a busca em
    linguagem natural volta vazia. Daí o OR de prefixos, deixando o BM25 ordenar — e
    quem escreve operador (aspas, AND/OR/NOT, `*`, `:`) quer controle fino, então
    a query passa intacta.
    """
    if OPERATORS.search(query):
        return query
    terms = [t for t in TOKEN.findall(query) if t.lower() not in STOPWORDS]
    if not terms:
        return query
    return " OR ".join(f'"{t}"*' for t in terms)


def snippet(body: str, limit: int = 240) -> str:
    return " ".join(body.split())[:limit]


def search_fts(root: Path, query: str, limit: int, path_filter: str | None) -> list[dict]:
    conn = connect(root)
    clause = "AND s.path LIKE ?" if path_filter else ""
    args: tuple = (build_match(query), *((f"%{path_filter}%",) if path_filter else ()), limit)
    try:
        rows = conn.execute(
            "SELECT s.path, s.trail, s.line_start, s.line_end, s.chars,"
            " snippet(sections_fts, 1, '«', '»', ' … ', 18), bm25(sections_fts, 2.0, 1.0)"
            " FROM sections_fts JOIN sections s ON s.id = sections_fts.rowid"
            f" WHERE sections_fts MATCH ? {clause}"
            " ORDER BY bm25(sections_fts, 2.0, 1.0) LIMIT ?",
            args,
        ).fetchall()
    except sqlite3.OperationalError as error:
        conn.close()
        return [{"erro": f"consulta FTS inválida: {error}. Use AND/OR/NOT, aspas para frase, * para prefixo."}]
    conn.close()
    return [
        {
            "path": r[0], "secao": r[1], "linhas": f"{r[2]}-{r[3]}", "chars": r[4],
            "trecho": " ".join(r[5].split()), "rank": round(-r[6], 2),
        }
        for r in rows
    ]


def search_semantic(root: Path, query: str, limit: int, path_filter: str | None) -> list[dict]:
    import numpy as np
    from sentence_transformers import SentenceTransformer

    conn = connect(root)
    clause = "WHERE vec IS NOT NULL" + (" AND path LIKE ?" if path_filter else "")
    args = (f"%{path_filter}%",) if path_filter else ()
    rows = conn.execute(
        f"SELECT path, trail, line_start, line_end, chars, body, vec FROM sections {clause}", args
    ).fetchall()
    conn.close()
    if not rows:
        return [{"erro": "sem vetores: rode `index --embed` antes de usar --semantic"}]

    model = SentenceTransformer(MODEL_NAME)
    wanted = np.asarray(model.encode([query], normalize_embeddings=True)[0], dtype="float32")
    matrix = np.vstack([np.frombuffer(r[6], dtype="float32") for r in rows])
    scores = matrix @ wanted
    return [
        {
            "path": rows[int(i)][0], "secao": rows[int(i)][1],
            "linhas": f"{rows[int(i)][2]}-{rows[int(i)][3]}", "chars": rows[int(i)][4],
            "trecho": snippet(rows[int(i)][5]), "score": round(float(scores[int(i)]), 3),
        }
        for i in np.argsort(-scores)[:limit]
    ]


def find_label(root: Path, label: str, path_filter: str | None = None) -> list[dict]:
    conn = connect(root)
    clause = "AND l.path LIKE ?" if path_filter else ""
    args = (label, *((f"%{path_filter}%",) if path_filter else ()))
    rows = conn.execute(
        "SELECT l.label, l.path, l.line, l.defining, s.trail, s.line_start, s.line_end"
        " FROM labels l LEFT JOIN sections s ON s.id = l.section_id"
        f" WHERE l.label = ? {clause} ORDER BY l.defining DESC, l.path, l.line",
        args,
    ).fetchall()
    conn.close()
    return [
        {
            "label": r[0], "path": r[1], "line": r[2],
            "provavel_definicao": bool(r[3]), "secao": r[4],
            "secao_linhas": f"{r[5]}-{r[6]}" if r[5] else None,
        }
        for r in rows
    ]


def outline(root: Path, path_filter: str, max_level: int) -> list[dict]:
    conn = connect(root)
    rows = conn.execute(
        "SELECT path, trail, level, line_start, line_end, chars FROM sections"
        " WHERE path LIKE ? AND level <= ? ORDER BY path, line_start",
        (f"%{path_filter}%", max_level),
    ).fetchall()
    conn.close()
    return [
        {"path": r[0], "secao": r[1], "nivel": r[2], "linhas": f"{r[3]}-{r[4]}", "chars": r[5]}
        for r in rows
    ]


def main() -> int:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=None)
    parser.add_argument("--glob", action="append", default=None)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_index = sub.add_parser("index", help="reindexa só o que mudou (por hash)")
    p_index.add_argument("--force", action="store_true")
    p_index.add_argument("--embed", action="store_true", help="calcula vetores (lento)")
    p_index.add_argument("--quiet", action="store_true")

    p_search = sub.add_parser("search", help="busca por seção; devolve a faixa de linhas")
    p_search.add_argument("query", nargs="+")
    p_search.add_argument("--limit", type=int, default=8)
    p_search.add_argument("--path", default=None, help="filtra por trecho do caminho")
    p_search.add_argument("--semantic", action="store_true", help="usa vetores (exige index --embed)")
    p_search.add_argument("--no-refresh", action="store_true")

    p_label = sub.add_parser("label", help="onde um rótulo (D12, F8, VR-46-02, §10) aparece")
    p_label.add_argument("label")
    p_label.add_argument("--path", default=None, help="filtra por trecho do caminho")
    p_label.add_argument("--no-refresh", action="store_true")

    p_outline = sub.add_parser("outline", help="sumário das seções de um arquivo")
    p_outline.add_argument("path")
    p_outline.add_argument("--max-level", type=int, default=3)
    p_outline.add_argument("--no-refresh", action="store_true")

    args = parser.parse_args()
    root = Path(args.root).resolve() if args.root else repo_root()
    globs = args.glob or DEFAULT_GLOBS

    if args.cmd == "index":
        reindex(root, globs, args.force, args.embed, args.quiet)
        return 0

    if not args.no_refresh:
        reindex(root, globs, force=False, embed=False, quiet=True)

    if args.cmd == "search":
        query = " ".join(args.query)
        found = (
            search_semantic(root, query, args.limit, args.path)
            if args.semantic
            else search_fts(root, query, args.limit, args.path)
        )
    elif args.cmd == "label":
        found = find_label(root, args.label, args.path)
    else:
        found = outline(root, args.path, args.max_level)

    print(json.dumps(found, ensure_ascii=False, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
