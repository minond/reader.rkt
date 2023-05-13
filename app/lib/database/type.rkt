#lang racket/base

(require db
         gregor)

(provide datetime->sql-timestamp)

(define (datetime->sql-timestamp dt)
  (sql-timestamp (->year dt)
                 (->month dt)
                 (->day dt)
                 (->hours dt)
                 (->minutes dt)
                 (->seconds dt)
                 (->nanoseconds dt)
                 #f))
