#lang racket/base

(require threading
         reader/app/models/article
         reader/lib/html
         reader/lib/openai/client)

(provide generate-article-content-summary)

(define (generate-article-content-summary-prompt link)
  (format "Write a summary of ~a to be displayed besides the article" link))

(define (generate-article-content-summary article)
  (define response
    (create-chat-completion
     #:model "gpt-3.5-turbo"
     #:user (format "user-~a" (article-user-id article))
     #:messages (list (hash 'role "user"
                            'content (generate-article-content-summary-prompt (article-link article))))))

  (define text (~> response
                   (hash-ref 'choices)
                   (car)
                   (hash-ref 'message)
                   (hash-ref 'content)))

  (values text
          (text->html text)))
