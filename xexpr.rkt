#lang racket/base

;; xexpr navigation for feed parsing: tolerant element/text/attribute
;; access with the two workarounds every RSS/Atom parser ends up
;; needing — namespace-prefixed tag names (e.g. content:encoded) and
;; the xml package's literal CDATA wrapper.

(require racket/contract
         racket/list
         racket/string
         xml)

(provide (contract-out
          [xexpr-from-bytes (-> bytes? (or/c xexpr? #f))]
          [xexpr-tag? (-> any/c symbol? boolean?)]
          [xexpr-tag-suffix? (-> any/c symbol? boolean?)]
          [xexpr-children (-> any/c (listof xexpr?))]
          [xexpr-text (-> any/c string?)]
          [xexpr-child-text (-> any/c symbol? (or/c string? #f))]
          [xexpr-find-child (-> any/c symbol? (or/c xexpr? #f))]
          [xexpr-attr (-> any/c symbol? (or/c string? #f))]))

;; Malformed bytes give #f, not an exception — feed fetches fail often
;; and callers want a branch, not a throw.
(define (xexpr-from-bytes b)
  (with-handlers ([exn:fail? (λ (_) #f)])
    (define doc (read-xml (open-input-bytes b)))
    (xml->xexpr (document-element doc))))

(define (xexpr-tag? x n)
  (and (pair? x) (symbol? (car x)) (eq? (car x) n)))

;; Tolerate namespace prefixes: 'content:encoded matches (n 'encoded).
(define (xexpr-tag-suffix? x n)
  (and (pair? x) (symbol? (car x))
       (let ([s (symbol->string (car x))])
         (or (eq? (car x) n)
             (string-ends-with? s (string-append ":" (symbol->string n)))))))

(define (string-ends-with? s p)
  (and (>= (string-length s) (string-length p))
       (equal? (substring s (- (string-length s) (string-length p))) p)))

(define (xexpr-children x)
  (if (pair? x)
      (for/list ([c (in-list (cddr x))]
                 #:when (and (pair? c) (symbol? (car c))))
        c)
      '()))

;; Concatenated character data, recursing into children.  The xml
;; library keeps the literal <![CDATA[...]]> wrapper in cdata structs —
;; strip it.
(define (xexpr-text x)
  (string-append*
   (for/list ([c (in-list (cddr x))])
     (cond [(string? c) c]
           [(cdata? c)
            (regexp-replace* #px"^<!\\[CDATA\\[|\\]\\]>$" (cdata-string c) "")]
           [(pair? c) (xexpr-text c)]
           [else ""]))))

(define (xexpr-find-child x n)
  (findf (λ (c) (xexpr-tag-suffix? c n)) (xexpr-children x)))

(define (xexpr-child-text x n)
  (define c (xexpr-find-child x n))
  (and c (xexpr-text c)))

(define (xexpr-attr x n)
  (define attrs (cadr x))
  (for/first ([av (in-list attrs)] #:when (eq? (car av) n)) (cadr av)))
