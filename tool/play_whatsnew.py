#!/usr/bin/env python3
"""Copy the newest CHANGELOG.md entry into Google Play "What's new" files.

Usage: python3 tool/play_whatsnew.py CHANGELOG.md OUT_DIR LOCALE [LOCALE...]

This app's CHANGELOG is written for users, so the newest `## <version>`
section is used as-is (markdown stripped, bullets as "•"). Writes
OUT_DIR/whatsnew-<LOCALE>, the format r0adkll/upload-google-play's
`whatsNewDirectory` reads. Play allows 500 characters: a longer entry loses
bullets from the end and prints a warning, so keep entries short.
"""
import os
import re
import sys

LIMIT = 500


def newest_entry(text):
    m = re.search(r"^## .*$", text, re.M)
    if not m:
        sys.exit("CHANGELOG has no '## <version>' section")
    rest = text[m.end():]
    n = re.search(r"^## ", rest, re.M)
    return rest[: n.start()] if n else rest


def items(entry):
    out = []
    for line in entry.splitlines():
        b = re.match(r"^[-*]\s+(.*)", line)
        if b:
            out.append([b.group(1)])
        elif out and line.startswith(" ") and line.strip():
            out[-1].append(line.strip())
    return [clean(" ".join(x)) for x in out]


def clean(text):
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"\*\*|__", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def compose(lines):
    lines = [f"• {x}" for x in lines if x]
    dropped = 0
    while len(lines) > 1 and len("\n".join(lines)) > LIMIT:
        lines.pop()
        dropped += 1
    if dropped:
        print(f"warning: CHANGELOG entry over {LIMIT} chars; "
              f"dropped {dropped} bullet(s) from the Play notes", file=sys.stderr)
    return "\n".join(lines)[:LIMIT] or "Bug fixes and improvements"


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    changelog, out_dir, locales = sys.argv[1], sys.argv[2], sys.argv[3:]
    with open(changelog, encoding="utf-8") as f:
        notes = compose(items(newest_entry(f.read())))
    os.makedirs(out_dir, exist_ok=True)
    for loc in locales:
        with open(os.path.join(out_dir, f"whatsnew-{loc}"), "w",
                  encoding="utf-8") as f:
            f.write(notes + "\n")
    print(notes)
    print(f"({len(notes)} chars)", file=sys.stderr)


if __name__ == "__main__":
    main()
