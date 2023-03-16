#lang racket/base

(require request/param

         net/url-string

         reader/lib/extractor/content
         reader/lib/extractor/document
         reader/lib/extractor/metadata
         reader/lib/extractor/media
         (prefix-in html- reader/lib/extractor/html))

(provide extract)

(define (extract url-string)
  (define url (string->url url-string))
  (define doc (download url))

  (define content (extract-content doc url))
  (define metadata (extract-metadata doc url))
  (define media (extract-media doc url))
  (define document (extract-document content metadata))

  (values content metadata media document))

(define (download url)
  (define res (get url))
  (define headers (http-response-headers res))

  (if (and (equal? 301 (http-response-code res))
           (hash-has-key? headers "Location"))
      (download (string->url (hash-ref headers "Location")))
      (html-parse (http-response-body res))))
