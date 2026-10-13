# AGENTS.md

## What this is

`feed` — RSS 2.0 + Atom parsing for Racket. Single-collection package
(`feed` = collection = package name). Family protocol-library line
(websocket, sse, isotp, crc, pcap, ...). Pure parsing: no network, no
fetching, no HTML-stripping policy, no dedup.

## Layout

- `xexpr.rkt` — tolerant xexpr navigation: CDATA-wrapper stripping,
  namespace-suffix tag matching (content:encoded)
- `date.rkt` — ISO 8601 + RFC 822 → UTC seconds
- `item.rkt` — the `feed-item` struct
- `rss.rkt` / `atom.rkt` — per-format parsers
- `feed.rkt` — parse-feed sniffer (root `feed` = Atom)
- `main.rkt` — re-exports everything
- `tests/` — require the `feed` collection, not relative paths
- `scribblings/` — Scribble docs

## Invariants

- The parser is permissive: it guarantees the `feed-item` field types
  and nothing else. Filtering (link-less entries, empty titles,
  tracking params) is caller policy. Do not add product policies here.
- Malformed input gives `'()` / `#f`, never an exception — feed
  fetches fail often and callers want a branch.
- Summaries are verbatim: no entity re-decoding beyond what the xml
  package does at parse time, no HTML stripping.

## Conventions

- Code comments in English.
- Test fixtures are real-shaped samples (the arXiv Atom shape with
  rel="related" links, CDATA descriptions with embedded HTML) — not
  just self-roundtrips.

## Quality gates (before any release)

1. `raco test tests` — all green
2. `raco setup --check-pkg-deps -l feed` — zero violations
3. `raco setup -l feed` — docs build clean, zero undefined tags
