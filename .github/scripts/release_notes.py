#!/usr/bin/env python3
"""Writes the Google Play "What's new" text (English and Indonesian) for one release.

    release_notes.py --version 1.0.2 --code 4 [--to v1.0.2]

Input is the git history between the previous version tag and --to. Claude turns it into short,
user-facing notes. Without ANTHROPIC_API_KEY, or if the call fails or is refused, the notes are
the feat:/fix: commit subjects, in English only, and the job summary says so.

Output: android/fastlane/metadata/android/{en-US,id}/changelogs/<code>.txt (fastlane supply reads
these when it uploads the bundle). Play allows at most 500 characters per language.
"""
import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

LIMIT = 500
MODEL = "claude-opus-5-5"
META = Path("android/fastlane/metadata/android")

PROMPT = """Write the Google Play "What's new" text for AntiDoom {version}.
AntiDoom is an Android app that counts the short videos you watch on TikTok, Reels, Shorts and X,
and helps you stop doomscrolling.

Source: the git commits since the last release (subject, then body).

Rules:
- Only changes a user can notice. Ignore CI, docs, refactors, build, tests and version bumps.
- Plain text. One bullet per line, each starting with "• ". At most 5 bullets.
- At most 450 characters per language. Friendly, no jargon, no commit hashes.
- Indonesian: casual and natural ("kamu"), not a word-for-word translation.
- If nothing is user-visible, write one bullet about stability and bug fixes.

Output exactly this, nothing else:
=== EN ===
<English text>
=== ID ===
<Indonesian text>

Commits:
{commits}
"""


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def vkey(tag):
    return tuple(int(n) for n in re.findall(r"\d+", tag))


def previous_tag(version):
    tags = [t for t in git("tag").split() if re.fullmatch(r"v\d+\.\d+\.\d+", t)]
    older = [t for t in tags if vkey(t) < vkey(version)]
    return max(older, key=vkey) if older else None


def commits(version, to):
    prev = previous_tag(version)
    rng = f"{prev}..{to}" if prev else to
    out = git("log", "--no-merges", "--pretty=format:%s%n%b%n---", rng)
    return prev, out.strip()


def subjects(raw):
    """Fallback: feat:/fix: subjects without the prefix."""
    lines = []
    for block in raw.split("\n---"):
        first = block.strip().split("\n")[0] if block.strip() else ""
        m = re.match(r"(feat|fix)(\([^)]*\))?!?:\s*(.+)", first)
        if m:
            lines.append("• " + m.group(3).strip().rstrip("."))
    return "\n".join(lines[:5]) or "• Stability and bug fixes"


def fit(text):
    """Trim to Play's 500-character limit at a line boundary."""
    text = text.strip()
    while len(text) > LIMIT and "\n" in text:
        text = text.rsplit("\n", 1)[0]
    return text[:LIMIT]


def ask_claude(version, raw):
    import anthropic

    client = anthropic.Anthropic()
    resp = client.beta.messages.create(
        model=MODEL,
        max_tokens=4000,
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
        output_config={"effort": "low"},
        messages=[{"role": "user", "content": PROMPT.format(version=version, commits=raw[:6000])}],
    )
    if resp.stop_reason == "refusal":
        raise RuntimeError("refused")
    text = "".join(b.text for b in resp.content if b.type == "text")
    m = re.search(r"=== EN ===\s*(.*?)\s*=== ID ===\s*(.*)", text, re.S)
    if not m or not m.group(1).strip() or not m.group(2).strip():
        raise RuntimeError("unexpected output format")
    return fit(m.group(1)), fit(m.group(2))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--code", required=True)
    ap.add_argument("--to", default="HEAD")
    a = ap.parse_args()

    prev, raw = commits(a.version, a.to)
    source = "Claude"
    try:
        if not os.environ.get("ANTHROPIC_API_KEY"):
            raise RuntimeError("ANTHROPIC_API_KEY is not set")
        en, idn = ask_claude(a.version, raw)
    except Exception as e:  # any failure must not block a release
        print(f"::warning::Release notes: falling back to commit subjects ({e})", file=sys.stderr)
        en = fit(subjects(raw))
        idn = en
        source = "commit subjects (English only)"

    for locale, text in (("en-US", en), ("id", idn)):
        d = META / locale / "changelogs"
        d.mkdir(parents=True, exist_ok=True)
        (d / f"{a.code}.txt").write_text(text + "\n", encoding="utf-8")

    summary = (
        f"### Release notes for {a.version} (build {a.code})\n"
        f"Source: {source}, changes since {prev or 'the first commit'}. "
        f"These go to Google Play as written; approve the **production** job to ship them.\n\n"
        f"**English** ({len(en)}/{LIMIT})\n\n```\n{en}\n```\n\n"
        f"**Indonesian** ({len(idn)}/{LIMIT})\n\n```\n{idn}\n```\n"
    )
    print(summary)
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as f:
            f.write(summary)


if __name__ == "__main__":
    main()
