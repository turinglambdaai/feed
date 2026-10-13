#lang racket/base

;; Feed timestamps in, UTC seconds out.  RSS speaks RFC 822 dates,
;; Atom speaks ISO 8601; real feeds mix both, so parse-date-any tries
;; 8601 first and falls back to 822.

(require racket/contract
         racket/format
         racket/string
         racket/date)

(provide (contract-out
          [parse-8601 (-> (or/c string? #f) (or/c integer? #f))]
          [parse-rfc822 (-> (or/c string? #f) (or/c integer? #f))]
          [parse-date-any (-> (or/c string? #f) (or/c integer? #f))]))

(define (tz-offset-seconds tz)
  (cond [(not tz) 0]
        [(regexp-match? #px"^[+-]\\d{2}:?\\d{2}$" tz)
         (define digits (regexp-replace* #px":" tz ""))
         (define sign (if (equal? (substring digits 0 1) "-") -1 1))
         (* sign (+ (* (string->number (substring digits 1 3)) 3600)
                    (* (string->number (substring digits 3 5)) 60)))]
        [else 0]))

(define (parse-8601 s)
  (define m
    (and s
         (regexp-match
          #px"^(\\d{4})-(\\d{2})-(\\d{2})(?:[T ](\\d{2}):(\\d{2}):(\\d{2})(?:\\.\\d+)?)?\\s*(Z|[+-]\\d{2}:?\\d{2})?"
          (string-trim s))))
  (and m
       (let* ([y (string->number (list-ref m 1))]
              [mo (string->number (list-ref m 2))]
              [d (string->number (list-ref m 3))]
              [h (string->number (or (list-ref m 4) "0"))]
              [mi (string->number (or (list-ref m 5) "0"))]
              [se (string->number (or (list-ref m 6) "0"))]
              [tz (list-ref m 7)]
              ;; "Z" and absent zones both fall through to 0 in
              ;; tz-offset-seconds
              [tz-secs (tz-offset-seconds tz)])
         (- (find-seconds se mi h d mo y #t) tz-secs))))

(define month-num
  (for/hash ([m (in-list '("jan" "feb" "mar" "apr" "may" "jun"
                           "jul" "aug" "sep" "oct" "nov" "dec"))]
             [i (in-naturals 1)])
    (values m i)))

(define (parse-rfc822 s)
  (define m
    (and s
         (regexp-match
          #px"^(?:\\w{3},\\s*)?(\\d{1,2})\\s+(\\w{3})\\s+(\\d{2,4})\\s+(\\d{2}):(\\d{2}):(\\d{2})\\s*([+-]\\d{4}|[A-Za-z]{1,5})?"
          (string-trim s))))
  (and m
       (let* ([d (string->number (list-ref m 1))]
              [mo (hash-ref month-num (string-downcase (list-ref m 2)) #f)]
              [y (string->number (list-ref m 3))]
              [y (if (< y 100) (+ 2000 y) y)]
              [h (string->number (list-ref m 4))]
              [mi (string->number (list-ref m 5))]
              [se (string->number (list-ref m 6))]
              [tz (list-ref m 7)])
         (and mo
              (- (find-seconds se mi h d mo y #t)
                 (tz-offset-seconds tz))))))

(define (parse-date-any s)
  (and (string? s) (non-empty-string? (string-trim s))
       (or (parse-8601 s) (parse-rfc822 s))))
