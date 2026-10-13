#lang racket/base

;; Entry point: sniffs Atom (root <feed>) vs RSS 2.0, then dispatches.

(require racket/contract
         "atom.rkt"
         "item.rkt"
         "rss.rkt"
         "xexpr.rkt")

(provide (contract-out
          [parse-feed (->* (bytes?) (#:max-entries (or/c exact-positive-integer? #f))
                           (listof feed-item?))]))

(define (parse-feed b #:max-entries [max-entries #f])
  (define root (xexpr-from-bytes b))
  (cond [(not root) '()]
        [(and (pair? root) (eq? (car root) 'feed))
         (parse-atom b #:max-entries max-entries)]
        [else (parse-rss b #:max-entries max-entries)]))
