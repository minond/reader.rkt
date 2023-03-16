#lang racket/base

(require racket/list
         racket/match
         racket/string

         reader/lib/html
         reader/lib/extractor/content
         reader/lib/extractor/metadata)

(provide extract-document
         (struct-out document))

(struct document (summary) #:transparent)

(define (extract-document content metadata)
  (define summary (or (metadata-description metadata)
                      (first-paragraph-text content)))

  (document summary))

(define (first-paragraph-text content)
  (define (extract-text el)
    (match el
      [(text text)
       text]
      [(entity id)
       (html-entity->string id)]
      [(container-element _ content)
       (string-append* (map extract-text content))]
      [else ""]))
  (extract-text (findf paragraph? content)))
