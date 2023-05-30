#lang racket/base

(require reader/entities/article
         reader/ai/openai/client)

(provide process-article-chat)

(define (process-article-chat article messages)
  (define response
    (create-chat-completion
     #:model "gpt-3.5-turbo"
     #:user (format "user-~a" (article-user-id article))
     #:messages (cons (hash 'role "user"
                            'content (format "This conversation is about the following artucle \"\"\"~a\"\"\""
                                             (trim-prompt-text (article-content-text article))))
                      messages)))
  (first-message-content response))
