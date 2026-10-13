# feed

[![CI](https://github.com/turinglambdaai/feed/actions/workflows/ci.yml/badge.svg)](https://github.com/turinglambdaai/feed/actions/workflows/ci.yml)

RSS 2.0 and Atom feed parsing for Racket. Pure: bytes in, items out —
fetching, HTML stripping, and dedup policy stay with the caller.

## Install

```
raco pkg install feed
```

## Use

```racket
(require feed)

(define items
  (parse-feed (fetch-bytes "https://example.com/feed.xml")))

(for ([it items])
  (displayln (feed-item-title it))
  (displayln (feed-item-link it))     ; #f when the entry has none
  (displayln (feed-item-published it))) ; UTC seconds or #f
```

- `parse-feed` sniffs RSS 2.0 vs Atom and dispatches; `parse-rss` /
  `parse-atom` are there when you know the format
- summaries come out verbatim (they usually embed HTML — strip at
  your policy boundary); `content:encoded` / `dc:date` /
  `<updated>`-style fallbacks are handled
- malformed bytes give `'()`, never an exception
- `#:max-entries` caps pathological feeds
- the `xexpr-*` toolkit (CDATA-wrapper stripping, namespace-suffix tag
  matching) is exported — it's the part every feed parser rewrites
- `parse-date-any` / `parse-8601` / `parse-rfc822` turn feed
  timestamps into UTC seconds

## Development

```
raco pkg install --auto --link .
raco test tests
raco setup --check-pkg-deps -l feed
```

## License

[MIT](LICENSE)
