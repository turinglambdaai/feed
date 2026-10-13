#lang racket/base

(require rackunit
         feed)

(test-case "xexpr-from-bytes tolerates garbage"
  (check-false (xexpr-from-bytes #"this is not xml"))
  (check-true (pair? (xexpr-from-bytes #"<r><a>x</a></r>"))))

(test-case "tag matching with namespace suffixes"
  (define x (xexpr-from-bytes
             #"<item><content:encoded><![CDATA[raw <em>html</em>]]></content:encoded></item>"))
  (check-true (xexpr-tag? x 'item))
  (check-false (xexpr-tag? x 'encoded))
  (define enc (xexpr-find-child x 'encoded))
  (check-true (xexpr-tag-suffix? enc 'encoded))
  (check-false (xexpr-tag-suffix? x 'encoded))
  ;; CDATA wrapper is stripped, content is verbatim
  (check-equal? (xexpr-child-text x 'encoded) "raw <em>html</em>"))

(test-case "children, attributes, text"
  (define link (xexpr-from-bytes
                #"<link href=\"http://x.example/\" rel=\"alternate\"/>"))
  (check-equal? (xexpr-attr link 'href) "http://x.example/")
  (check-equal? (xexpr-attr link 'rel) "alternate")
  (check-false (xexpr-attr link 'missing))
  (define y (xexpr-from-bytes #"<a>one<b>two</b>three</a>"))
  (check-equal? (xexpr-text y) "onetwothree")
  (check-equal? (length (xexpr-children y)) 1)
  (check-true (xexpr-tag? (car (xexpr-children y)) 'b))
  (check-false (xexpr-child-text y 'zzz)))
