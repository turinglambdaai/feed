#lang scribble/manual

@(require (for-label feed
                     racket/base)
          scribble/example)

@title{feed: RSS 2.0 and Atom Parsing}
@defmodule[feed]

This package parses RSS 2.0 and Atom feeds into plain data. It is
pure: bytes in, items out — fetching (e.g. with @tt{http-easy}),
HTML stripping, URL normalization, and dedup policy all stay with the
caller. It exists because the two workarounds every feed parser ends
up needing — the @tt{xml} package's literal @tt{CDATA} wrapper and
namespace-prefixed tag names like @tt{content:encoded} — are handled
here once, and the xexpr toolkit behind them is exported.

@section{Parsing}

@defproc[(parse-feed [b bytes?] [#:max-entries max-entries (or/c exact-positive-integer? #f) #f])
         (listof feed-item?)]

Sniffs the root element (@tt{feed} means Atom, anything else RSS 2.0)
and dispatches. Malformed bytes yield @racket['()], not an exception —
feed fetches fail often and callers want a branch. Feed authors and
consumers disagree about what makes an entry usable, so the parser
keeps every entry; filter on @racket[feed-item-link] etc. yourself.

@defproc[(parse-rss [b bytes?] [#:max-entries max-entries (or/c exact-positive-integer? #f) #f])
         (listof feed-item?)]

Parses @tt{<item>} entries. Summary comes from @tt{<description>} or
@tt{<content:encoded>}; the date from @tt{<pubDate>} or @tt{<dc:date>}.

@defproc[(parse-atom [b bytes?] [#:max-entries max-entries (or/c exact-positive-integer? #f) #f])
         (listof feed-item?)]

Parses @tt{<entry>} elements. Link prefers @tt{rel="alternate"} or a
bare @tt{<link>}, falling back to any link; summary from
@tt{<summary>} or @tt{<content>}; date from @tt{<published>} or
@tt{<updated>}.

@defstruct*[feed-item ([title string?] [link (or/c string? #f)] [summary string?] [published (or/c integer? #f)])]

One entry. @racket[summary] is verbatim — it very often embeds HTML;
strip and truncate at your own policy boundary. @racket[published] is
UTC seconds.

@examples[#:eval (make-base-eval) #:label ""
  (require feed racket/list)
  (define items
    (parse-feed #"<rss><channel><item><title>Hello</title><link>http://x.example/</link><pubDate>Tue, 13 Oct 2026 08:30:00 +0200</pubDate></item></channel></rss>"))
  (feed-item-title (first items))
  (feed-item-link (first items))
  (feed-item-published (first items))]

@section{Feed dates}

@defproc[(parse-date-any [s (or/c string? #f)]) (or/c integer? #f)]

Tries ISO 8601 (Atom-style, including bare dates and fractional
seconds) then RFC 822 (RSS-style, two-digit years included). Returns
UTC seconds or @racket[#f].

@defproc[(parse-8601 [s (or/c string? #f)]) (or/c integer? #f)]

@defproc[(parse-rfc822 [s (or/c string? #f)]) (or/c integer? #f)]

The individual formats.

@section{The xexpr toolkit}

The @tt{xml} package's @tt{CDATA} handling and namespace prefixes are
the two recurring traps of feed-shaped parsing; these are exported for
anyone parsing similar documents.

@defproc[(xexpr-from-bytes [b bytes?]) (or/c xexpr? #f)]

Parses bytes to the root element, or @racket[#f] on malformed input.

@defproc[(xexpr-tag? [x any/c] [n symbol?]) boolean?]

Exact tag-name match.

@defproc[(xexpr-tag-suffix? [x any/c] [n symbol?]) boolean?]

Matches @racket[n] or any namespace-prefixed form ending in
@tt{:n} (e.g. @tt{content:encoded} matches @racket['encoded]).

@defproc[(xexpr-children [x any/c]) (listof xexpr?)]

Element children only — text and cdata excluded.

@defproc[(xexpr-text [x any/c]) string?]

Concatenated character data, recursing into children, with the
@tt{<![CDATA[...]]>} wrapper stripped.

@defproc[(xexpr-find-child [x any/c] [n symbol?]) (or/c xexpr? #f)]

@defproc[(xexpr-child-text [x any/c] [n symbol?]) (or/c string? #f)]

First child matching @racket[xexpr-tag-suffix?], and its text.

@defproc[(xexpr-attr [x any/c] [n symbol?]) (or/c string? #f)]

Attribute value by exact name.
