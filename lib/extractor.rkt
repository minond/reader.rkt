#lang racket/base

(require request/param
         net/url-string
         (prefix-in h: html)

         reader/lib/extractor/content
         reader/lib/extractor/metadata
         reader/lib/extractor/media)

(provide extract
         download)

(define (extract url-string)
  (define url (string->url url-string))
  (define doc (download url))

  (values (extract-content doc url)
          (extract-metadata doc url)
          (extract-media doc url)))

(define (download url)
  (let* ([res (get url)]
         [bod (http-response-body res)]
         [doc (h:read-html-as-xml (open-input-string bod))])
    doc))
