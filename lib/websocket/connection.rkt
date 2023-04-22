#lang racket/base

(require racket/list
         net/rfc6455
         reader/lib/lock)

(provide lookup-connections
         clear-connections!
         track-connection!
         untrack-connection!)

(define connections (make-hash))
(define lock (make-lock))

(define (lookup-connections key)
  (hash-ref connections key '()))

(define (clear-connections!)
  (hash-clear! connections))

(define (track-connection! session-key ws-conn)
  (with-lock lock
    (lambda ()
      (define ws-conns (lookup-connections session-key))
      (hash-set! connections session-key (cons ws-conn ws-conns)))))

(define (untrack-connection! session-key ws-conn)
  (with-lock lock
    (lambda ()
      (define ws-conns (remove ws-conn (lookup-connections session-key)))
      (if (empty? ws-conns)
          (hash-remove! connections session-key)
          (hash-set! connections session-key ws-conns)))))
