#!/usr/bin/env python3
"""Regenerates the golden decision fixture (decisions.jsonl + rules.json) in this directory.

A realistic month of link clicks for someone with work in Brave and personal in Chrome:
GitHub split by org, Google Docs split by `authuser`, Gmail genuinely ambiguous, Figma split
by source app, Notion all Brave, YouTube all Chrome, an Atlassian rule the user keeps
correcting, plus low-volume noise. Run it, then `SWITCHMAN_RECORD_GOLDEN=1 swift test`.
"""
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path

HERE = Path(__file__).parent
BRAVE = {"bundleID": "com.brave.Browser"}
CHROME = {"bundleID": "com.google.Chrome"}
SLACK = "com.tinyspeck.slackmacgap"
MESSAGES = "com.apple.MobileSMS"
NOTES = "com.apple.Notes"

decisions = []
clock = datetime(2026, 10, 1, 9, 0, tzinfo=timezone.utc)


def add(count, host, domain, path, chosen, kind="picked", source=None, hints=None, weight=None):
    global clock
    for _ in range(count):
        d = {
            "chosen": chosen,
            "date": clock.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "key": {
                "hints": hints or {},
                "host": host,
                "pathSegments": [s for s in path.split("/") if s],
                "registrableDomain": domain,
                "scheme": "https",
            },
            "kind": kind,
            "weight": weight if weight is not None else (3 if kind == "corrected" else 1),
        }
        if source:
            d["sourceAppBundleID"] = source
        decisions.append(d)
        clock += timedelta(minutes=17)


# GitHub: work org in Brave, personal repos in Chrome, gists personal, a few one-off orgs.
add(20, "github.com", "github.com", "acme/api/pull/12", BRAVE, source=SLACK)
add(12, "github.com", "github.com", "acme/web", BRAVE)
add(8, "github.com", "github.com", "acme/infra/issues", BRAVE, source=NOTES)
add(15, "github.com", "github.com", "shravan/dotfiles", CHROME)
add(10, "github.com", "github.com", "shravan/blog", CHROME, source=MESSAGES)
for org in ["rando1", "rando2", "rando3", "rando4"]:
    add(1, "github.com", "github.com", f"{org}/x", CHROME)
add(2, "github.com", "github.com", "torvalds/linux", BRAVE)
add(8, "gist.github.com", "github.com", "shravan/abc123", CHROME)

# Google: Docs split by account hint; Gmail's account lives in the path (/u/1/), past depth 1.
add(20, "docs.google.com", "google.com", "document/d/work1/edit", BRAVE, hints={"authuser": "1"})
add(15, "docs.google.com", "google.com", "document/d/home1/edit", CHROME)
add(10, "mail.google.com", "google.com", "mail/u/0/", CHROME)
add(12, "mail.google.com", "google.com", "mail/u/1/", BRAVE)

# Figma: links from Slack are work, links from Messages are personal.
add(12, "figma.com", "figma.com", "file/WORK/design", BRAVE, source=SLACK)
add(8, "figma.com", "figma.com", "file/HOME/sketch", CHROME, source=MESSAGES)

# Notion: all work, one stray personal click (still ≥ 90%).
add(28, "notion.so", "notion.so", "acme/Roadmap-123", BRAVE)
add(1, "notion.so", "notion.so", "acme/Roadmap-123", CHROME)

# YouTube: all personal.
add(30, "youtube.com", "youtube.com", "watch", CHROME)
add(3, "m.youtube.com", "youtube.com", "watch", CHROME)

# Atlassian: an existing rule sends it to Chrome; the user keeps correcting to Brave.
add(5, "acme.atlassian.net", "atlassian.net", "browse/OPS-1", CHROME, kind="autoRouted")
add(4, "acme.atlassian.net", "atlassian.net", "browse/OPS-2", BRAVE, kind="corrected")

# Noise below the support threshold.
add(3, "news.ycombinator.com", "ycombinator.com", "item", CHROME)
add(2, "reddit.com", "reddit.com", "r/swift", BRAVE)
add(1, "example.org", "example.org", "", CHROME)

with open(HERE / "decisions.jsonl", "w") as f:
    for d in decisions:
        f.write(json.dumps(d, sort_keys=True, separators=(",", ":")) + "\n")

rules = {
    "version": 1,
    "rules": [
        {
            "id": "00000000-0000-4000-8000-0000000000A1",
            "pattern": {"hostWildcard": "*.atlassian.net"},
            "open": CHROME,
            "enabled": True,
            "origin": "manual",
        }
    ],
}
with open(HERE / "rules.json", "w") as f:
    f.write(json.dumps(rules, indent=2, sort_keys=True) + "\n")

print(f"{len(decisions)} decisions")
