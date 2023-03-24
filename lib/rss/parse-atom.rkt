#lang racket/base

(require racket/match

         gregor
         xml
         xml/path

         reader/lib/string
         reader/lib/rss/data
         reader/lib/rss/processing)

(provide atom?
         parse-atom)

(define (atom? xexpr)
  (se-path* '(feed) xexpr))

(define (parse-atom xexpr)
  (let* ([title (se-path* '(feed title) xexpr)]
         [link (se-path* '(feed link #:href) xexpr)]
         [entry-data (se-path*/list '(feed) xexpr)]
         [entries (filter (lambda (entry)
                            (and (pair? entry)
                                 (eq? (car entry) 'entry))) entry-data)]
         [articles (let ([title null]
                         [link null]
                         [date null]
                         [content ""])
                     (map (lambda (item)
                            (for ([part item] #:when (pair? part))
                              (let ([tag (car part)]
                                    [value (cddr part)])
                                (match tag
                                  ['title (set! title (car value))]
                                  ['link (set! link (string-list-join (se-path*/list '(link #:href) part)))]
                                  ['published (set! date (iso8601->datetime (car value)))]
                                  ['updated (set! date (iso8601->datetime (car value)))]
                                  ['summary (set! content (if (and (list? (cddr part)) (cdata? (caddr part)))
                                                              (cdata-string (caddr part))
                                                              (string-list-join (cddr part) "")))]
                                  [else null])))
                            (article (strip-cdata link)
                                     (strip-cdata title)
                                     (strip-cdata date)
                                     content)) entries))])
    (feed (strip-cdata link)
          (strip-cdata title)
          articles)))
