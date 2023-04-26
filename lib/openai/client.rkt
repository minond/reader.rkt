#lang racket/base

(require reader/thirdparty/openapi/client)

(provide create-chat-completion)

(openapi openai "lib/openai/openapi.yaml"
         #:only (create-chat-completion)
         #:bearer (getenv "OPENAI_API_KEY"))
