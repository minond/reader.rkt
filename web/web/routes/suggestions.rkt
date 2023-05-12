#lang racket/base

(require net/url-string
         reader/entities/suggestions
         reader/lib/server)

(provide /suggestions)

(define (/suggestions req)
  (define suggestions (make-suggestions (parameter 'url req)))
  (json 'suggestions
        (map (lambda (suggestion)
               (hash 'kind (symbol->string (suggestion-kind suggestion))
                     'url (url->string (suggestion-url suggestion))
                     'title (suggestion-title suggestion)))
             suggestions)))
