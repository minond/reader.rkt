#lang racket/base

(require threading
         deta)

(provide find-user-by-email)

(define (find-user-by-email email)
  (~> (from user #:as u)
      (where (= email ,email))
      (limit 1)))
