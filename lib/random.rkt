#lang racket/base

(require racket/list
         racket/sequence
         racket/random)

(provide random-string)

(define charset
  (map integer->char
       (append (inclusive-range 48 57)
               (inclusive-range 65 90)
               (inclusive-range 97 122))))

(define (random-item xs)
  (sequence-ref xs (random (sequence-length xs))))

(define (random-string [len 32])
  (list->string
   (map (lambda (x)
          (random-item charset))
        (make-list len 0))))
