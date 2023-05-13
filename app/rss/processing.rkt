#lang racket/base

(require racket/string

         threading
         xml
         xml/path
         gregor)

(provide string->datetime
         strip-cdata)

(define (string->datetime str)
  (let ([parse (lambda (format)
                 (with-handlers
                     ([exn:gregor:parse?
                       (lambda (e) #f)])
                   (parse-datetime str format)))])
    (or (parse "eee, d MMM y HH:mm:ss Z")
        (parse "eee,  d MMM y HH:mm:ss Z")
        (parse "d MMM y")
        (parse "eee, d MMM y HH:mm:ss 'GMT'")
        (parse "y-M-d HH:mm:ss"))))

(define (strip-cdata node)
  (if (cdata? node)
      (~> (cdata-string node)
          (string-replace _ "<![CDATA[" "" #:all? #t)
          (string-replace _ "]]>" "" #:all? #t))
      node))
