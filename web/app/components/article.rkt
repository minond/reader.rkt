#lang racket/base

(require racket/string

         db
         gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/app/models/article
         reader/app/models/feed

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
                (:aside (:article/content-processing-component article)
                        (:spacer #:direction horizontal #:size small)
                        (:article/chat article)))
          (:script 'type: 'module 'src: "/public/ai.js"))))

(define (:article/content article)
  (:article
   (:literal (article-extracted-content-html article))))

(define (:article/chat article)
  (let* ([summary-html (article-generated-summary-html article)]
         [has-summary? (not (sql-null? summary-html))])
    (:div 'class: (if has-summary? "chat" "dn chat")
          (:div 'class: "messages")
          (:div 'class: "shadow")
          (:div 'class: "input-wrapper"
                (:textarea 'rows: 1 'placeholder: "Send a message...")
                (:spinning-ring 30))
          (:p 'class: "disclaimer"
              "ChatGPT may produce inaccurate information about people, places, or facts."))))

(define (:article/content-processing-component article)
  (:div 'data-component: "article-content-processing"
        'data-article-id: (article-id article)
        (:script 'type: 'module 'src: "/public/article-content-processing.js")))

(define (:article/list feed articles current-page page-count)
  (list
   (:spacer #:direction vertical #:size small)
   (:table 'class: "table-content with-indicator"
           (:thead
            (:th)
            (:th "Title")
            (:th "Date")
            (:th ""))
           (:tbody (map :article/row articles)))
   (:spacer #:direction horizontal #:size small)
   (:pagination current-page page-count)))

(define (:article/row article)
  (let-values ([(route class) (if (article-archived article)
                                  (values "/articles/~a/unarchive" "archived")
                                  (values "/articles/~a/archive" "unarchived"))])
    (:tr 'class: (string-join (list "article-row" class))
         (:td 'class: "tc"
              (:a 'href: (format route (article-id article))
                  'class: (format "article-archive-toggle ~a" class)))
         (:td (:a 'href: (format "/articles/~a" (article-id article))
                  (article-title article)))
         (:td 'class: "wsnw" (~t (article-date article) "M/d/y"))
         (:td 'class: "wsnw" (:a 'href: (article-link article)
                                 'target: '_blank
                                 "Visit page")))))
