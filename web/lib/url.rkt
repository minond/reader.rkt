#lang racket/base

(require racket/string
         net/url-string)

(provide as-url
         fillin)

(define (as-url maybe-url)
  (if (string? maybe-url)
      (string->url maybe-url)
      maybe-url))

(define (fillin url)
  (unless (url-scheme url)
    (set! url (string->url
               (string-append "https://"
                              (url->string url)))))
  (unless (string-contains? (url-host url) ".")
    (set! url (string->url (url->string url)))
    (set-url-host! url
                   (string-append (url-host url)
                                  ".com")))
  url)
