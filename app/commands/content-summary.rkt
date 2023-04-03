#lang racket/base

(require threading
         reader/app/models/article
         reader/lib/openai/client)

(provide generate-article-content-summary)

(define (generate-article-content-summary article)
  (define response
    (create-chat-completion
     #:model "gpt-3.5-turbo"
     #:user (format "user-~a" (article-user-id article))
     #:messages (list (hash 'role "user"
                            'content (format "Can you write a summary of ~a"
                                             (article-link article))))))

  (~> response
      (hash-ref 'choices)
      (car)
      (hash-ref 'message)
      (hash-ref 'content)))
