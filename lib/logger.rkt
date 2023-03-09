#lang racket/base

(require gregor
         reader/lib/format)

(provide application-logger)

(define-logger application)
(define receiver (make-log-receiver application-logger 'debug))

(void
 (thread
  (lambda ()
    (let loop ()
      (define rec (sync receiver))
      (displayln (format "~a [~a] ~a"
                         (date->rfc7231 (now/utc))
                         (vector-ref rec 0)
                         (vector-ref rec 1)))
      (loop)))))
