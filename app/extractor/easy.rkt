#lang racket/base

(require request/param

         net/url-string

         reader/extractor/content
         reader/extractor/document
         reader/extractor/metadata
         reader/extractor/media
         (prefix-in html- reader/extractor/html))

(provide extract
         download)

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
