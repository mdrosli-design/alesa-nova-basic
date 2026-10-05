# [ALESA-CHANGE 2026-10-05 · oleh: tyronx + claude-opus-5-5] what: TEST fixture for the ALESA Semak PR reviewer — this
#   function deliberately builds SQL from user input so the reviewer should flag it · why: end-to-end check of inline
#   comments and the alesa/semak-pr status · verify: the test PR shows a FAIL status and an inline comment. DO NOT MERGE.
import sqlite3


def find_user(conn: sqlite3.Connection, uid: str):
    query = "SELECT * FROM users WHERE id = '" + uid + "'"
    return conn.execute(query).fetchone()
