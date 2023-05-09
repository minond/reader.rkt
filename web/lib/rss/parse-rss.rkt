#lang racket/base

(require racket/match
         racket/string

         gregor
         xml
         xml/path

         reader/lib/string
         reader/lib/rss/data
         reader/lib/rss/processing)

(provide rss?
         parse-rss)

(define (rss? xexpr)
  (se-path* '(rss) xexpr))

(define (parse-rss xexpr)
  (let* ([title (se-path* '(rss channel title) xexpr)]
         [link (se-path* '(rss channel link) xexpr)]
         [item-data (se-path*/list '(rss channel) xexpr)]
         [items (filter (lambda (entry)
                          (and (pair? entry)
                               (eq? (car entry) 'item))) item-data)]
         [articles (let ([title null]
                         [link null]
                         [date null]
                         [content ""])
                     (map (lambda (item)
                            (for ([part item] #:when (pair? part))
                              (let ([tag (car part)])
                                (match tag
                                  ['title (set! title (caddr part))]
                                  ['link (set! link (caddr part))]
                                  ['pubDate (set! date (string->datetime (caddr part)))]
                                  ['description (set! content (if (and (list? (cddr part)) (cdata? (caddr part)))
                                                                  (cdata-string (caddr part))
                                                                  (string-list-join (cddr part) "")))]
                                  [else null])))
                            (article (strip-cdata link)
                                     (string-trim (strip-cdata title))
                                     (strip-cdata date)
                                     (strip-cdata content))) items))])
    (feed (strip-cdata link)
          (string-trim (strip-cdata title))
          articles)))
