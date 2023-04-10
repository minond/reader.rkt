#lang racket/base

(require threading
         reader/app/models/article
         reader/lib/html
         reader/lib/openai/client)

(provide generate-article-content-summary
         process-article-chat)

(define (article-content-summary-prompt article)
  (format "Write a short summary of this article: ~a"
          (trim-prompt-part (article-extracted-content-html article))))

(define (article-chat-prompt article)
  (format "This conversation is about this article: ~a"
          (trim-prompt-part (article-extracted-content-html article))))

(define (trim-prompt-part str)
  (if (< (string-length str) 4000)
      str
      (substring str 0 4000)))

(define (generate-article-content-summary article)
  (define response
    (create-chat-completion
     #:model "gpt-3.5-turbo"
     #:user (format "user-~a" (article-user-id article))
     #:messages (list (hash 'role "user"
                            'content (article-content-summary-prompt article)))))
  (define text (first-message-content response))
  (values text
          (text->html text)))

(define (process-article-chat article messages)
  (define response
    (create-chat-completion
     #:model "gpt-3.5-turbo"
     #:user (format "user-~a" (article-user-id article))
     #:messages (cons (hash 'role "user"
                            'content (article-chat-prompt article))
                      messages)))
  (first-message-content response))

(define (first-message-content response)
  (~> response
      (hash-ref 'choices)
      (car)
      (hash-ref 'message)
      (hash-ref 'content)))
