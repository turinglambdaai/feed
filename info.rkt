#lang info

(define collection "feed")
(define version "0.1")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/feed.scrbl" ())))
(define pkg-desc "RSS 2.0 and Atom feed parsing on plain xexprs")
(define license 'MIT)
(define pkg-authors '(turinglambdaai))
(define test-omit-paths '("scribblings"))
