#lang racket/base

(require reader/entities/article
         reader/ai/openai/client
         reader/lib/html)

(provide generate-article-summary)

(define (generate-article-summary article)
  (define response
    (create-chat-completion
      #:model "gpt-3.5-turbo"
      #:user (format "user-~a" (article-user-id article))
      #:messages (list (hash 'role "user"
                             'content (format "Write a short summary of the following article: \"\"\"~a\"\"\""
                                              (trim-prompt-text (article-extracted-content-text article)))))))

  (define text (first-message-content response))
  (values text (text->html text)))
