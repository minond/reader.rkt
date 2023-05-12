#lang racket/base

(require threading
         reader/thirdparty/openapi/client)

(provide create-chat-completion
         first-message-content
         trim-prompt-text)

(openapi openai "openai/openapi.yaml"
         #:only (create-chat-completion)
         #:bearer (getenv "OPENAI_API_KEY"))

(define (first-message-content response)
  (~> response
      (hash-ref 'choices)
      (car)
      (hash-ref 'message)
      (hash-ref 'content)))

(define (trim-prompt-text str)
  (if (< (string-length str) 4000)
      str
      (substring str 0 4000)))
