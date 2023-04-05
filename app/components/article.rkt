#lang racket/base

(require racket/string
         racket/match
         racket/list

         db
         gregor
         (prefix-in : scribble/html/xml)
         (prefix-in : scribble/html/html)
         (prefix-in : scribble/html/extra)

         reader/app/models/article
         reader/app/models/feed
         reader/app/components/feed

         reader/lib/app/components/spacer
         reader/lib/app/components/pagination)

(provide :article/full
         :article/list
         :article/previews)

(define (:article/full feed article)
  (let* ([datetime (~t (article-date article) "y-M-d HH:mm:ss")]
         [humandate (~t (article-date article) "MMMM d, yyyy")])
    (:div 'class: "reading"
          (:h2 (:a 'href: (article-link article)
                   'target: '_blank
                   (article-title article)))
          (:h4 (:a 'href: (feed-link feed)
                   'target: '_blank
                   (feed-title feed)))
          (:time 'datetime: datetime humandate)
          (:spacer #:direction horizontal #:size small)
          (:div 'class: "container"
                (:article/content article)
                (:div (:article/summary article)
                      (:article/chat article)))
          )))

(define (:article/content article)
  (:article
    (:literal (article-content-html article))))

(define (:article/chat article)
  null)

(define (:article/summary article)
  (let* ([summary-html (article-generated-summary-html article)]
         [has-summary? (not (sql-null? summary-html))])
    (:div 'id: "summary"
          (if has-summary?
              (:literal summary-html)
              (:div 'class: "loading-summary"
                    (:input 'id: 'article-id
                            'type: 'hidden
                            'value: (article-id article))
                    (:spinning-ring)))
          (:script/inline 'type: "text/javascript" article-ai-js))))

(define article-ai-js "
(function () {

const $ = document.querySelector.bind(document)
const $$ = document.querySelectorAll.bind(document)

const summaryEl = $('#summary')
const articleIdEl = $('#summary #article-id')
const loadingSummaryEl = $('#summary .loading-summary')

if (loadingSummaryEl && articleIdEl) {
  const url = `/articles/${articleIdEl.value}/summary`
  fetch(url)
    .then((res) => res.json())
    .then((body) => {
      const p = document.createElement('p')
      p.classList.add('fadein')
      p.innerHTML = body.summary
      summaryEl.removeChild(loadingSummaryEl)
      summaryEl.appendChild(p)
    })
}

})()")

(define (:article/list feed articles current-page page-count)
  (list
   (:spacer #:direction vertical #:size small)
   (:table 'class: "table-content"
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

(define (:article/previews articles current-page page-count scheduled)
  (match (cons (empty? articles) scheduled)
    [(cons #t #t)
     (list
      (:spacer #:direction horizontal
               #:size large)
      (:p 'class: "tc"
          "We're getting articles for you, hold tight!"))]
    [(cons #t #f)
     (list
      (:spacer #:direction horizontal
               #:size large)
      (:p 'class: "tc"
          "There are no articles to show at this time. Use the form below to
           subscribe to a feed.")
      (:feed/form))]
    [else
     (list
      (map :article-preview articles)
      (:pagination current-page page-count))]))

(define (:article-preview article)
  (let ([datetime (~t (article-date article) "y-M-d HH:mm:ss")]
        [humandate (~t (article-date article) "MMMM d, yyyy")])
    (:article 'class: "article-preview show-on-hover-container"
              (:a 'href: (format "/articles/~a" (article-id article))
                  (:h3 (article-title article))
                  (:p (article-description article)))
              (:time 'datetime: datetime humandate)
              (:spacer #:direction horizontal
                       #:size small)
              (:a 'class: "action show-on-hover"
                  'href: (article-link article)
                  'target: '_blank
                  "read")
              (:spacer #:direction horizontal
                       #:size small)
              (:a 'class: "action show-on-hover"
                  'href: (format "/articles/~a/archive" (article-id article))
                  "archive"))))

(define (:spinning-ring)
  (:div 'class: "spinning-ring"
        (:div)
        (:div)
        (:div)
        (:div)))
