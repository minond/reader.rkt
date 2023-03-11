#lang racket/base

(require racket/match
         racket/string

         net/url-string
         (prefix-in x: xml)

         reader/lib/string
         reader/lib/extractor/attribute
         reader/lib/extractor/query)

(provide extract-metadata
         (struct-out metadata))

(struct metadata (original-url canonical-url type title description charset)
  #:constructor-name make-metadata
  #:mutable
  #:prefab)

(define (extract-metadata doc base-url)
  (let* ([metatags (find-elements 'meta doc)]
         [linktags (find-elements 'link doc)]
         [titletag (find-element 'title doc)]
         [attrgroups (map x:element-attributes (append metatags linktags))]
         [metadata (make-metadata (url->string base-url) #f #f
                                  (and titletag (element-string titletag))
                                  #f #f)])
    (for* ([attributes attrgroups])
      (match (list (or (attr 'name attributes) (attr 'property attributes))
                   (attr 'content attributes)
                   (attr 'rel attributes)
                   (attr 'href attributes)
                   (attr 'charset attributes))
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
      [(x:pcdata? el)
       (string-append acc (x:pcdata-string el))]
      [(x:entity? el)
       (let ([value (x:entity-text el)])
         (if (integer? value)
             (string (integer->char value))
             ""))]
      [(x:element? el)
       (let* ([content (x:element-content el)]
              [strings (map element-string-aux content)])
         (string-append* (cons acc strings)))]))
  (string-strip (element-string-aux el)))
