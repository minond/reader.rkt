#lang racket/base

(require racket/string
         threading
         reader/entities/article
         reader/ai/openai/client)

(provide generate-article-tags)

(define (p article)
  (format "Generate a maximum of 10 comma separated tags for the following article: \"\"\"~a\"\"\""
          (trim-prompt-text (article-content-text article))))

(define (generate-article-tags article)
  (define response
    (create-chat-completion
      #:model "gpt-3.5-turbo"
      #:user (format "user-~a" (article-user-id article))
      #:messages (list (hash 'role "user"
                             'content (p article)))))
  (clean-up-tag-string (first-message-content response)))

(define (clean-up-tag-string str)
  (map (lambda~> (string-trim)
                 (regexp-replace #px"\\.$" _ "")
                 (regexp-replace* #px"^[a-z]" _ string-upcase))
       (string-split str ",")))
