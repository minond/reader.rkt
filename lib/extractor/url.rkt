#lang racket/base

(require racket/function
         racket/list
         racket/string

         net/url-string
         (prefix-in x: xml)

         reader/lib/string
         reader/lib/extractor/attribute
         reader/lib/extractor/query)

(provide extract-base-url
         extract-feed-url
         absolute-url)

(define (absolute-url base-url raw-relative-url #:convert [convert #t])
  (define relative-url (string-strip raw-relative-url))
  (if (or (eq? 0 (string-length relative-url))
          (equal? #\# (string-ref relative-url 0)))
      relative-url
      (if convert
          (url->string (combine-url/relative base-url relative-url))
          (combine-url/relative base-url relative-url))))

;; Extracts or deduces the "base" URL by (1) checking link and meta tags for a
;; author or article:author, then (2) returning the base URL stripped of its
;; path/query/fragment.
;;
;; TODO look for the http://schema.org/Person element.
(define (extract-base-url doc base-url)
  (let/cc return
    (define els
      (filter identity
              (list (find* doc #:tag 'link #:attr '(rel "author"))
                    (find* doc #:tag 'meta #:attr '(property "article:author")))))
    (define urls
      (map (lambda (el)
             (define attributes (x:element-attributes el))
             (or (attr 'content attributes)
                 (attr 'href attributes)))
           els))
    (when (not (empty? urls))
      (return (absolute-url base-url (car urls) #:convert #f)))

    (url-strip base-url)))

(define (url-strip page-url)
  (url (url-scheme page-url)
       (url-user page-url)
       (url-host page-url)
       (url-port page-url)
       #t
       empty
       empty
       #f))

;; Extracts an RSS or atom feed URL by (1) checking link tags that specify the
;; feed URL, or (2) anchor tags that link to the feed.
(define (extract-feed-url doc base-url)
  (let/cc return
    (define link-els (find-elements 'link doc))
    (define alternative-link
      (findf string?
             (map (lambda (el)
                    (let* ([attributes (x:element-attributes el)]
                           [rel (attr 'rel attributes)]
                           [type (attr 'type attributes)]
                           [href (attr 'href attributes)])
                      (and rel type href
                           (or (string-contains? type "rss")
                               (string-contains? type "atom"))
                           href)))
                  link-els)))
    (when alternative-link
      (return (absolute-url base-url alternative-link #:convert #f)))

    (define anchor-els (find-elements 'a doc))
    (define rss-link
      (findf string?
             (map (lambda (el)
                    (define href (attr 'href (x:element-attributes el)))
                    (and (string? href)
                         (or (string-contains? href "rss")
                             (string-contains? href "atom"))
                         href))
                  anchor-els)))
    (when rss-link
      (return (absolute-url base-url rss-link #:convert #f)))

    #f))
