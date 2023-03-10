#lang racket/base

(require racket/string
         racket/format)

(provide string-chop
         string-list-join)

(define (string-chop str maxlen #:end [end ""])
  (if (<= (string-length str) maxlen)
      str
      (string-append (string-trim (substring str 0 maxlen)) end)))

(define (string-list-join xs [sep " "])
  (string-join (map ~a xs) sep))
