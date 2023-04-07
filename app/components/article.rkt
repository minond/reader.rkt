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
          (:input 'id: 'article-id
                  'type: 'hidden
                  'value: (article-id article))
          (:div 'class: "container"
                (:article/content article)
                (:div (:article/summary article)
                      (:spacer #:direction horizontal #:size small)
                      (:article/chat article)))
          )))

(define (:article/content article)
  (:article
   (:literal (article-content-html article))))

(define (:article/chat article)
  (:div 'class: "chat"
        (:div 'class: "messages")
        (:div 'class: "input-wrapper"
              (:textarea 'rows: 1
                         'placeholder: "Send a message..."))
        (:p 'class: "disclaimer"
            "ChatGPT may produce inaccurate information about people, places, or facts.")
        (:script/inline 'type: "text/javascript" article-chat-js)))

(define (:article/summary article)
  (let* ([summary-html (article-generated-summary-html article)]
         [has-summary? (not (sql-null? summary-html))])
    (:div 'id: "summary"
          'class: "summary"
          (if has-summary?
              (:literal summary-html)
              (:div 'class: "loading-summary"
                    (:spinning-ring)))
          (:script/inline 'type: "text/javascript" article-summary-js))))

(define article-chat-js "
(function () {

const storedChat = sessionStorage.getItem('reader/chat')
const chat = storedChat ? JSON.parse(storedChat) : []
const messageEl = document.querySelector('.chat textarea')
const messagesEl = document.querySelector('.chat .messages')
const articleIdEl = document.querySelector('#article-id')
const articleId = articleIdEl.value

chat.forEach((message) => showMessage(message, false))

messageEl.addEventListener('keypress', function (ev) {
  switch (ev.keyCode) {
    case 13:
      sendMessage()
      ev.preventDefault()
      return false
  }
})

function sendMessage() {
  let content = messageEl.value
  if (!content) {
    return
  }

  storeMessage('user', content)
  messageEl.value = ''

  fetch(`/articles/${articleId}/chat`, {
    method: 'POST',
    body: JSON.stringify({ chat }),
  })
    .then((res) => res.json())
    .then((body) => storeMessage('assistant', body.response))
}

function storeMessage(role, content) {
  const message = { role, content }
  chat.push(message)
  showMessage(message)
  sessionStorage.setItem('reader/chat', JSON.stringify(chat))
}

function showMessage(message, animate = true) {
  const p = document.createElement('p')
  p.classList.add(message.role)
  if (animate) p.classList.add('fadein')
  p.innerText = message.content
  messagesEl.appendChild(p)
}

})()")

(define article-summary-js "
(function () {

const summaryEl = document.querySelector('#summary')
const loadingSummaryEl = document.querySelector('#summary .loading-summary')
const articleIdEl = document.querySelector('#article-id')
const articleId = articleIdEl.value

if (loadingSummaryEl && articleIdEl) {
  fetch(`/articles/${articleId}/summary`)
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
