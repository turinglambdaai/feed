#lang racket/base

;; Atom: bytes in, feed-items out.  Pure — no network, no policy.

(require racket/contract
         racket/list
         "date.rkt"
         "item.rkt"
         "xexpr.rkt")

(provide (contract-out
          [parse-atom (->* (bytes?) (#:max-entries (or/c exact-positive-integer? #f))
                           (listof feed-item?))]))

(define (take-up-to l n)
  (if n (take l (min (length l) n)) l))

;; Prefer rel="alternate" or a bare link; fall back to any <link>.
(define (atom-link it)
  (or (for/first ([c (in-list (xexpr-children it))]
                  #:when (xexpr-tag? c 'link)
                  #:unless (let ([rel (xexpr-attr c 'rel)])
                             (and rel (not (equal? rel "alternate")))))
        (xexpr-attr c 'href))
      (for/first ([c (in-list (xexpr-children it))] #:when (xexpr-tag? c 'link))
        (xexpr-attr c 'href))))

(define (entry-item it)
  (feed-item
   (or (xexpr-child-text it 'title) "")
   (atom-link it)
   (or (xexpr-child-text it 'summary)
       (xexpr-child-text it 'content)
       "")
   (parse-date-any (or (xexpr-child-text it 'published)
                       (xexpr-child-text it 'updated)))))

(define (parse-atom b #:max-entries [max-entries #f])
  (define root (xexpr-from-bytes b))
  (if (not root)
      '()
      (for/list ([it (in-list (take-up-to
                               (filter (λ (c) (xexpr-tag? c 'entry))
                                       (xexpr-children root))
                               max-entries))])
        (entry-item it))))
