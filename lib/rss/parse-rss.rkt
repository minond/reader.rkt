#lang racket/base

(require racket/match

         gregor
         xml
         xml/path

         reader/lib/string
         reader/lib/rss/data)

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
                            (article link title date content)) items))])
    (feed link title articles)))

(define (string->datetime str)
  (let ([parse (lambda (format)
                 (with-handlers
                     ([exn:gregor:parse?
                       (lambda (e) #f)])
                   (parse-datetime str format)))])
    (or (parse "eee, d MMM y HH:mm:ss Z")
        (parse "eee,  d MMM y HH:mm:ss Z")
        (parse "d MMM y")
        (parse "eee, d MMM y HH:mm:ss 'GMT'")
        (parse "y-M-d HH:mm:ss"))))
