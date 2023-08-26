#lang racket/base

(require racket/list
         net/rfc6455
         "../../lib/lock.rkt")

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

(define (track-connection! key ws-conn)
  (with-lock lock
    (lambda ()
      (define ws-conns (cons ws-conn (lookup-connections key)))
      (hash-set! connections key ws-conns)
      (length ws-conns))))

(define (untrack-connection! key ws-conn)
  (with-lock lock
    (lambda ()
      (define ws-conns (remove ws-conn (lookup-connections key)))
      (if (empty? ws-conns)
          (hash-remove! connections key)
          (hash-set! connections key ws-conns))
      (length ws-conns))))
