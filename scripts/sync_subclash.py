#!/usr/bin/env python3
"""Write clash-ext.yaml into S-UI settings.subClashExt (sqlite).

S-UI reads subClashExt from the database on each Clash subscription
request, so this does not restart s-ui or sing-box.
"""
from __future__ import annotations

import argparse
import hashlib
import http.client
import sqlite3
import sys
from pathlib import Path

DB_DEFAULT = "/usr/local/s-ui/db/s-ui.db"
REQUIRED_MARKERS = ("proxy-groups:", "rule-providers:", "rules:")


def load_yaml(path: Path) -> str:
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n").replace("\r", "\n")
    if not text.endswith("\n"):
        text += "\n"
    if len(text) < 200 or len(text) > 500_000:
        raise SystemExit(f"clash-ext.yaml size looks wrong: {len(text)} bytes")
    missing = [m for m in REQUIRED_MARKERS if m not in text]
    if missing:
        raise SystemExit(f"clash-ext.yaml missing sections: {', '.join(missing)}")
    return text


def update_db(db: str, body: str) -> str:
    digest = hashlib.sha256(body.encode("utf-8")).hexdigest()[:12]
    conn = sqlite3.connect(db, timeout=10)
    try:
        conn.execute("PRAGMA busy_timeout=5000")
        cur = conn.execute(
            "UPDATE settings SET value=? WHERE key='subClashExt'", (body,)
        )
        if cur.rowcount == 0:
            conn.execute(
                "INSERT INTO settings (key, value) VALUES ('subClashExt', ?)",
                (body,),
            )
        conn.commit()
        stored = conn.execute(
            "SELECT value FROM settings WHERE key='subClashExt'"
        ).fetchone()
        if not stored or stored[0] != body:
            raise SystemExit("sqlite write did not round-trip")
        return digest
    finally:
        conn.close()


def setting(db: str, key: str, default: str = "") -> str:
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    try:
        row = conn.execute(
            "SELECT value FROM settings WHERE key=?", (key,)
        ).fetchone()
        return (row[0] if row and row[0] else default) or default
    finally:
        conn.close()


def first_client(db: str) -> str:
    conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    try:
        row = conn.execute(
            "SELECT name FROM clients WHERE enable=1 ORDER BY id LIMIT 1"
        ).fetchone()
        if not row:
            raise SystemExit("no enabled client to verify subscription")
        return row[0]
    finally:
        conn.close()


def verify_sub(db: str, client: str) -> None:
    domain = setting(db, "subDomain", "127.0.0.1")
    port = int(setting(db, "subPort", "2096") or "2096")
    path = setting(db, "subPath", "/sub/")
    if not path.endswith("/"):
        path += "/"
    listen = setting(db, "subListen", "127.0.0.1") or "127.0.0.1"
    req_path = f"{path}{client}?format=clash"
    conn = http.client.HTTPConnection(listen, port, timeout=15)
    try:
        conn.request("GET", req_path, headers={"Host": domain})
        resp = conn.getresponse()
        body = resp.read().decode("utf-8", errors="replace")
        title = resp.getheader("Profile-Title") or ""
        status = resp.status
    except OSError as e:
        raise SystemExit(f"subscription fetch failed: {e}") from e
    finally:
        conn.close()
    if status != 200:
        raise SystemExit(f"subscription HTTP {status} Host={domain} {req_path}")
    for needle in ("rule-providers:", "RULE-SET,Apple", "MATCH,", "Final"):
        if needle not in body:
            raise SystemExit(f"subscription missing {needle!r}")
    print(f"verify ok  Profile-Title={title!r}  bytes={len(body)}")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--file", required=True, type=Path)
    p.add_argument("--db", default=DB_DEFAULT)
    p.add_argument("--verify", action="store_true")
    p.add_argument("--client-name", default="")
    args = p.parse_args()

    body = load_yaml(args.file)
    digest = update_db(args.db, body)
    print(f"subClashExt updated  sha256={digest}  bytes={len(body.encode('utf-8'))}")

    if args.verify:
        name = args.client_name or first_client(args.db)
        verify_sub(args.db, name)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
