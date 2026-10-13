#lang racket/base

;; The normalized shape every parser produces: one entry, one place,
;; one time.  The parser is permissive — it guarantees the field types
;; and nothing else; filtering and enrichment stay with the caller.

(provide (struct-out feed-item))

;; title and summary are always strings (possibly empty); link is #f
;; when the entry has none; published is UTC seconds or #f.
(struct feed-item (title link summary published) #:transparent)
