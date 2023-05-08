#lang racket/base

(require racket/function
         racket/list
         racket/string

         threading
         net/url-string

         reader/lib/string
         reader/lib/extractor/attribute
         reader/lib/extractor/query
         (prefix-in html- reader/lib/extractor/html))

(provide absolute-url
         extract-base-url
         extract-feed-urls)

(define (absolute-url base-url raw-relative-str #:convert [as-string #t])
  (define relative-str
    (~> raw-relative-str
        (string-strip)
        (regexp-replace #px"^./" _ "")))
  (define relative-url (string->url relative-str))
  (define ret
    (if (or (eq? 0 (string-length relative-str))
            (equal? #\# (string-ref relative-str 0)))
        base-url
        (if (url-path-absolute? relative-url)
            (combine-url/relative base-url relative-str)
            (let ([copy (string->url (url->string base-url))])
              (set-url-path! copy (append (url-path base-url)
                                          (url-path relative-url)))
              copy))))
  (if as-string
      (url->string ret)
      ret))

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
             (define attributes (html-element-attributes el))
             (or (read-attribute attributes 'content)
                 (read-attribute attributes 'href)))
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
(define (extract-feed-urls doc base-url)
  (let/cc return
    (define link-els (find*/list doc #:tag 'link))
    (define alternative-links
      (filter string?
              (map (lambda (el)
                     (let* ([attributes (html-element-attributes el)]
                            [rel (read-attribute attributes 'rel)]
                            [type (read-attribute attributes 'type)]
                            [href (read-attribute attributes 'href)])
                       (and rel type href
                            (or (string-contains? type "rss")
                                (string-contains? type "atom"))
                            href)))
                   link-els)))
    (when (not (null? alternative-links))
      (return (map (lambda~> (absolute-url base-url _ #:convert #f)) alternative-links)))

    (define anchor-els (find*/list doc #:tag 'a))
    (define rss-links
      (filter string?
              (map (lambda (el)
                     (define href (read-attribute (html-element-attributes el) 'href ))
                     (and (string? href)
                          (or (string-contains? href "rss")
                              (string-contains? href "atom"))
                          href))
                   anchor-els)))
    (when (not (null? rss-links))
      (return (map (lambda~> (absolute-url base-url _ #:convert #f)) alternative-links)))

    #f))
