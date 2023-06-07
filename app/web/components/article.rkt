#lang racket/base

(require racket/string

         gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/entities/article
         reader/entities/feed

         reader/lib/app/components/script
         reader/lib/app/components/spacer
         reader/lib/app/components/spinner
         reader/lib/app/components/pagination)

(provide :article/full
         :article/list)

(define (:article/full feed article)
  (let* ([datetime (~t (article-date article) "y-M-d HH:mm:ss")]
         [humandate (~t (article-date article) "MMMM d, yyyy")])
    (:div 'class: "reading"
          (:div 'class: "show-on-hover-container"
                (:h2 (:a 'href: (article-link article)
                         'target: '_blank
                         (article-title article)))
                (:h4 (:a 'href: (feed-link feed)
                         'target: '_blank
                         (feed-title feed)))
                (:time 'datetime: datetime humandate)
                (if (article-archived article)
                    (:a 'class: "action show-on-hover"
                        'href: (format "/articles/~a/unarchive" (article-id article))
                        "[unarchive]")
                    (:a 'class: "action show-on-hover"
                        'href: (format "/articles/~a/archive" (article-id article))
                        "[archive]")))
          (:spacer #:direction horizontal #:size small)
          (:input 'id: 'article-id
                  'type: 'hidden
                  'value: (article-id article))
          (:div 'class: "container"
                (:article/content article)
                (:aside (:script/component 'ArticleProcessing
                                           'data-article-id: (article-id article))
                        (:spacer #:direction horizontal #:size small)
                        (:script/component 'ArticleChat
                                           'data-article-id: (article-id article)))))))

(define (:article/content article)
  (:article
   (:literal (article-content-html article))))

(define (:article/list feed articles current-page page-count)
  (list
   (:spacer #:direction vertical #:size small)
   (:table 'class: "table-content with-indicator"
           (:thead
            (:th)
            (:th "Title")
            (:th "Date")
            (:th ""))
           (:tbody (for/list ([article articles])
                     (:article/row article))))
   (:spacer #:direction horizontal #:size small)
   (:pagination current-page page-count)))

(define (:article/row article)
  (let-values ([(route action class) (if (article-archived article)
                                         (values "/articles/~a/unarchive" "unarchivd" "archived")
                                         (values "/articles/~a/archive" "archive" "unarchived"))])
    (:tr 'class: (string-join (list "article-row" class))
         (:td 'class: "tc"
              (:a 'href: (format route (article-id article))
                  'data-fancy-link: "true"
                  action))
         (:td (:a 'href: (format "/articles/~a" (article-id article))
                  (article-title article)))
         (:td 'class: "wsnw" (~t (article-date article) "M/d/y"))
         (:td 'class: "wsnw" (:a 'href: (article-link article)
                                 'target: '_blank
                                 "Visit page")))))
