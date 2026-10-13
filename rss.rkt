#lang racket/base

;; RSS 2.0: bytes in, feed-items out.  Pure — no network, no policy.

(require racket/contract
         racket/list
         "date.rkt"
         "item.rkt"
         "xexpr.rkt")

(provide (contract-out
          [parse-rss (->* (bytes?) (#:max-entries (or/c exact-positive-integer? #f))
                          (listof feed-item?))]))

(define (take-up-to l n)
  (if n (take l (min (length l) n)) l))

(define (entry-item it)
  (feed-item
   (or (xexpr-child-text it 'title) "")
   (xexpr-child-text it 'link)
   (or (xexpr-child-text it 'description)
       (xexpr-child-text it 'content:encoded)
       "")
   (parse-date-any (or (xexpr-child-text it 'pubDate)
                       (xexpr-child-text it 'dc:date)))))

(define (parse-rss b #:max-entries [max-entries #f])
  (define root (xexpr-from-bytes b))
  (define ch (and root (xexpr-find-child root 'channel)))
  (if (not ch)
      '()
      (for/list ([it (in-list (take-up-to
                               (filter (λ (c) (xexpr-tag? c 'item))
                                       (xexpr-children ch))
                               max-entries))])
        (entry-item it))))
