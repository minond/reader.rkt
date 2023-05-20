#lang racket/base

(require pyffi
         gregor)

(provide (all-from-out pyffi)
         pydatetime->datetime)

(initialize)
(post-initialize)

(define (pydatetime->datetime o)
  (datetime o.tm_year
            o.tm_mon
            o.tm_mday
            o.tm_hour
            o.tm_min
            o.tm_sec
            0))
