#lang racket/base

(provide make-lock
         with-lock)

(struct lock (sem))

(define (make-lock)
  (lock (make-semaphore 1)))

(define (with-lock lck thunk)
  (semaphore-wait (lock-sem lck))
  (thunk)
  (semaphore-post (lock-sem lck)))
