#lang racket/base

(require racket/match
         racket/string

         net/url-string

         reader/lib/string
         reader/lib/html
         reader/lib/extractor/attribute
         reader/lib/extractor/query
         (prefix-in html- reader/lib/extractor/html))

(provide extract-metadata
         (struct-out metadata))

(struct metadata (original-url canonical-url type title description charset)
  #:constructor-name make-metadata
  #:mutable
  #:prefab)

(define (extract-metadata doc url)
  (let* ([metatags (find*/list doc #:tag 'meta)]
         [linktags (find*/list doc #:tag 'link)]
         [titletag (find* doc #:tag 'title)]
         [attrgroups (map html-element-attributes (append metatags linktags))]
         [metadata (make-metadata (url->string url) #f #f
                                  (and titletag (element-string titletag))
                                  #f #f)])
    (for* ([attributes attrgroups])
      (match (list (or (read-attribute attributes 'name) (read-attribute attributes 'property))
                   (read-attribute attributes 'content)
                   (read-attribute attributes 'rel)
                   (read-attribute attributes 'href)
                   (read-attribute attributes 'charset))
        [(list _ _ "canonical" url _)
         (set-metadata-canonical-url! metadata url)]
        [(list _ _ _ _ (? string? charset))
         (set-metadata-charset! metadata charset)]
        [(list "og:type" content _ _ _)
         (set-metadata-type! metadata content)]
        [(list "og:title" content _ _ _)
         (set-metadata-title! metadata content)]
        [(list "og:description" content _ _ _)
         (set-metadata-description! metadata content)]
        [(list "description" content _ _ _)
         (set-metadata-description! metadata content)]
        [_
         (void)]))
    metadata))

(define (element-string el)
  (define (element-string-aux el [acc ""])
    (cond
      [(html-text? el)
       (string-append acc (html-text-text el))]
      [(html-entity? el)
       (let ([value (html-entity-id el)])
         (html-entity->string value))]
      [(html-element? el)
       (let* ([content (html-element-children el)]
              [strings (map element-string-aux content)])
         (string-append* (cons acc strings)))]))
  (string-strip (element-string-aux el)))
