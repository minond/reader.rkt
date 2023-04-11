#lang racket/base

(require racket/match
         racket/string

         reader/lib/html
         reader/lib/string
         reader/lib/extractor/content)

(provide extract-text)

(define (extract-text elem-or-lst)
  (if (list? elem-or-lst)
      (string-join
       (filter non-empty-string?
               (for/list ([elem elem-or-lst])
                 (extract-text elem))))
      (string-trim
       (match elem-or-lst
         [(heading _ _ _) ""]
         [(separator) ""]
         [(line-break) ""]
         [(image _ _ _) ""]
         [(iframe _ _) ""]
         [(video _ _) ""]
         [(text text) text]
         [(entity id) (html-entity->string id)]
         [(paragraph _ content) (extract-text content)]
         [(division _ content) (extract-text content)]
         [(link _ content _) (extract-text content)]
         [(bold _ content) (extract-text content)]
         [(italic _ content) (extract-text content)]
         [(code _ content) (extract-text content)]
         [(ordered-list _ content) (extract-text content)]
         [(unordered-list _ content) (extract-text content)]
         [(list-item _ content) (extract-text content)]
         [(table _ content) (extract-text content)]
         [(table-row _ content) (extract-text content)]
         [(table-cell _ content) (extract-text content)]
         [(blockquote _ content) (extract-text content)]
         [(superscript _ content) (extract-text content)]
         [(pre _ content) (extract-text content)]
         [(caption _ content) (extract-text content)]
         [(object _ content type data) (extract-text content)]
         [else (error "unable to render" elem-or-lst)]))))
