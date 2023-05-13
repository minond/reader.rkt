#lang racket/base

(provide reduce-by-pair)

(define (reduce-by-pair f xs [id '()])
  (if (< (length xs) 2)
      (append id xs)
      (reduce-by-pair f (cdr xs) (f id (car xs) (cadr xs)))))
