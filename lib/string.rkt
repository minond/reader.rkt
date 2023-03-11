#lang racket/base

(require racket/string
         racket/format
         threading)

(provide string-chop
         string-list-join
         string-strip)

(define (string-chop str maxlen #:end [end ""])
  (if (<= (string-length str) maxlen)
      str
      (string-append (string-trim (substring str 0 maxlen)) end)))

(define (string-list-join xs [sep " "])
  (string-join (map ~a xs) sep))

(define (string-strip string)
  (~> string
      (regexp-replace* #px"^\\s+|\\s+$" _ "")
      (regexp-replace* #px"\\s+" _ " ")))
