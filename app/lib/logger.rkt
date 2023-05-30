#lang racket/base

(require gregor
         reader/lib/format)

(provide application-logger
         start-logger)

(define (start-logger #:parent [parent (current-logger)]
                      #:level [level 'info]
                      #:out [out (current-output-port)])
  (define receiver
    (make-log-receiver parent level))
  (define (handler)
    (let loop ()
      (sync
       (handle-evt (thread-receive-evt)
                   (lambda (_)
                     (void)))
       (handle-evt receiver
                   (lambda (rec)
                     (displayln
                      (format "~a [~a] ~a"
                              (date->rfc7231 (now/utc))
                              (vector-ref rec 0)
                              (vector-ref rec 1))
                      out)
                     (flush-output out)
                     (loop))))))

  (define thd
    (thread handler))

  (lambda ()
    (thread-send thd 'stop)))

(define-logger application)
(start-logger #:parent application-logger)
