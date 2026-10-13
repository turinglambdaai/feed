#lang racket/base

(require rackunit
         racket/date
         feed)

(test-case "iso 8601"
  (define z (parse-8601 "2026-10-13T09:00:00Z"))
  (check-equal? z (find-seconds 0 0 9 13 10 2026 #t))
  (check-equal? (parse-8601 "2026-10-13T11:00:00+02:00") z)          ; 09:00Z
  (check-equal? (parse-8601 "2026-10-13T08:30:00+0200")
                (find-seconds 0 30 6 13 10 2026 #t))
  (check-equal? (parse-8601 "2026-10-13") (find-seconds 0 0 0 13 10 2026 #t))
  (check-equal? (parse-8601 "2026-10-13T09:00:00.500Z")
                (find-seconds 0 0 9 13 10 2026 #t))                  ; frac ignored
  (check-false (parse-8601 "not a date"))
  (check-false (parse-8601 #f)))

(test-case "rfc 822"
  (check-equal? (parse-rfc822 "Tue, 13 Oct 2026 08:30:00 +0200")
                (find-seconds 0 30 6 13 10 2026 #t))
  (check-equal? (parse-rfc822 "13 Oct 2026 06:00:00 GMT")
                (find-seconds 0 0 6 13 10 2026 #t))
  (check-false (parse-rfc822 "13 Foo 2026 06:00:00 GMT"))            ; bad month
  (check-false (parse-rfc822 #f)))

(test-case "parse-date-any dispatches and rejects"
  (check-equal? (parse-date-any "2026-10-13T09:00:00Z")
                (find-seconds 0 0 9 13 10 2026 #t))
  (check-equal? (parse-date-any "Tue, 13 Oct 2026 08:30:00 +0200")
                (find-seconds 0 30 6 13 10 2026 #t))
  (check-false (parse-date-any ""))
  (check-false (parse-date-any "garbage"))
  (check-false (parse-date-any #f)))
