#lang racket/base

(require rackunit
         racket/date
         racket/file
         racket/list
         racket/runtime-path
         feed)

(define-runtime-path rss-sample.xml "rss-sample.xml")
(define-runtime-path atom-sample.xml "atom-sample.xml")

(define rss-bytes (file->bytes rss-sample.xml))
(define atom-bytes (file->bytes atom-sample.xml))

(test-case "rss 2.0"
  (define items (parse-rss rss-bytes))
  (check-equal? (length items) 3)   ; parser keeps everything, even link-less
  (define a (first items))
  (check-equal? (feed-item-title a) "Solid-state battery breakthrough at &scale")
  (check-equal? (feed-item-link a) "https://example.com/a?utm_source=x&id=1")
  (check-equal? (feed-item-summary a)
                "<p>Toyota says <b>solid-state</b> batteries &amp; ranges doubled.</p>")
  (check-equal? (feed-item-published a)
                (find-seconds 0 30 6 13 10 2026 #t))
  (define b (second items))
  (check-false (feed-item-link b))              ; no <link>, so #f
  (check-false (feed-item-published b))         ; no date, so #f
  (check-equal? (feed-item-title b) "No link item")
  (check-equal? (feed-item-published (third items))
                (find-seconds 0 0 6 13 10 2026 #t)))

(test-case "rss dc:date and content:encoded fallbacks"
  (define items
    (parse-rss #"<rss><channel><item><title>t</title><link>http://x/</link><content:encoded>full body</content:encoded><dc:date>2026-10-13T09:00:00Z</dc:date></item></channel></rss>"))
  (check-equal? (feed-item-summary (first items)) "full body")
  (check-equal? (feed-item-published (first items))
                (find-seconds 0 0 9 13 10 2026 #t)))

(test-case "atom"
  (define items (parse-atom atom-bytes))
  (check-equal? (length items) 2)
  (check-equal? (feed-item-link (first items)) "http://arxiv.org/abs/2026.12345v1")
  (check-equal? (feed-item-published (first items))
                (find-seconds 0 0 9 13 10 2026 #t))
  ;; rel="related" is skipped for the plain link; date falls back to <updated>
  (check-equal? (feed-item-link (second items)) "http://right.example/")
  (check-equal? (feed-item-published (second items))
                (find-seconds 0 0 10 12 10 2026 #t)))

(test-case "parse-feed sniffing"
  (check-equal? (length (parse-feed rss-bytes)) 3)
  (check-equal? (length (parse-feed atom-bytes)) 2)
  (check-equal? (parse-feed #"this is not xml") '()))

(test-case "max-entries caps the result"
  (check-equal? (length (parse-feed rss-bytes #:max-entries 2)) 2)
  (check-equal? (length (parse-feed atom-bytes #:max-entries 1)) 1))
